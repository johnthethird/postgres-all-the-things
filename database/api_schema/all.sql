set client_min_messages to warning;

\set QUIET on
\set ON_ERROR_STOP on

-- Ability to create multiple api schemas for version control or something? Defaults to "api"
\set api_schema `echo ${API_SCHEMA:-api}`

\echo # Creating api schema

-- Everything in this schema will be exposed by Postgrest (probably just views wrapping base tables).
-- Take care to write updateable views if thats what you want, or use INSTEAD OF triggers, defined in the same file as the view.
-- https://www.postgresql.org/docs/current/static/sql-createview.html#SQL-CREATEVIEW-UPDATABLE-VIEWS

-- Dont ref the name of this schema, as it may change in future. Im thinking api-<githash> to have multiple versions active at once.
-- So set the searchpath in this file and then keep the namespace off CREATE statements.
-- If u ref any table/func in public then lets agree you have to be explicit and say it public.<foo>
-- Dont even put public in the search path?

-- TODO make sure apiuser owns every view/proc?

DROP SCHEMA IF EXISTS :"api_schema" CASCADE;
CREATE SCHEMA :"api_schema";
COMMENT ON SCHEMA :"api_schema" IS 'API V1.0';

GRANT USAGE ON SCHEMA :"api_schema" TO anonymous, authenticator, apiuser;
-- TODO is this right?
ALTER DEFAULT PRIVILEGES IN SCHEMA :"api_schema" GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO apiuser;
ALTER DEFAULT PRIVILEGES IN SCHEMA :"api_schema" REVOKE SELECT, INSERT, UPDATE, DELETE ON TABLES FROM anonymous;

SET search_path TO :"api_schema",public;

\ir views/tenants.sql
\ir views/tenant_members.sql
\ir views/settings.sql
\ir views/me.sql
\ir views/my_roles.sql
\ir views/permissions.sql

\ir rpcs/login.sql
\ir rpcs/create_tenant.sql
