-- Maybe try this instead? https://github.com/pgMemento
CREATE SCHEMA audit;

COMMENT ON SCHEMA audit
  IS 'Out-of-table audit/history logging tables and trigger functions';

REVOKE ALL ON SCHEMA audit FROM public;

SET search_path TO audit,public;

\ir log.table.sql
\ir if_modified_func.fn.sql
\ir audit_table.fn.sql
