#!/bin/bash

set -e

# Create the template db
psql -U $POSTGRES_USER -tc "SELECT 1 FROM pg_database WHERE datname = 'template_db'" | grep -q 1 || psql -U $POSTGRES_USER -c "CREATE DATABASE template_db IS_TEMPLATE true"

# Load zhparser into both template_db and $POSTGRES_DB
for DB in template_db "$POSTGRES_DB"; do
echo "Loading zhparser extensions into $DB"
echo "shared_preload_libraries = 'pg_stat_statements, pg_cron'" >> $PGDATA/postgresql.conf
echo "pg_stat_statements.max = 10000" >> $PGDATA/postgresql.conf
echo "pg_stat_statements.track = all" >> $PGDATA/postgresql.conf
echo "cron.use_background_workers = on" >> $PGDATA/postgresql.conf

if [ "$USE_REPLICATION" = 1 ];then \
echo "wal_level=logical" >> $PGDATA/postgresql.conf \
&& echo "max_replication_slots=5" >> $PGDATA/postgresql.conf; \
fi;

echo "default_text_search_config= 'chinese'" >> $PGDATA/postgresql.conf

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$DB" <<-EOSQL
    CREATE EXTENSION IF NOT EXISTS pg_trgm;
    CREATE EXTENSION IF NOT EXISTS zhparser;
    CREATE EXTENSION pg_stat_statements;
    CREATE EXTENSION pg_cron;
    DO
    \$\$BEGIN
      CREATE TEXT SEARCH CONFIGURATION chn (PARSER = zhparser);
      ALTER  TEXT SEARCH CONFIGURATION chn ADD MAPPING FOR n,v,a,i,e,l,t WITH simple;
    EXCEPTION
    WHEN unique_violation THEN
    NULL;  -- ignore error
    END;\$\$;
    SELECT extname,extversion FROM pg_extension;
EOSQL
done
