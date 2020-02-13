DROP SCHEMA IF EXISTS app CASCADE;

CREATE SCHEMA app;

SET search_path TO app,public;

GRANT USAGE ON SCHEMA app TO public;

\ir functions/ddl_utils.sql
\ir functions/request.sql
\ir functions/settings.sql
\ir functions/jwt.sql
\ir functions/can.sql
\ir functions/slate_plain_serialize.sql

\ir triggers/notify_on_table_mutation.sql
\ir triggers/protected_row.sql
\ir triggers/set_owned_by.sql
\ir triggers/set_tenant_id.sql
\ir triggers/set_updated_at.sql
