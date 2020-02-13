CREATE EXTENSION IF NOT EXISTS plv8;

CREATE SCHEMA v8;

COMMENT ON SCHEMA v8
  IS 'JavaScript modules for use in plv8 functions';

GRANT USAGE ON SCHEMA v8 TO public;

ALTER DEFAULT PRIVILEGES IN SCHEMA v8 GRANT SELECT ON TABLES TO public;

SET search_path TO v8,public;

\ir modules_table.sql
\ir plv8_require.sql
\ir load_module_files.sql
