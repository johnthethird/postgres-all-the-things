\echo # Creating app data tables in public schema

SET search_path TO public;

-- Dont worry about api schema here
GRANT USAGE ON SCHEMA public TO anonymous, apiuser, authenticator;
-- Grant everything and use RLS to enforce permissions
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO anonymous, apiuser, authenticator;

\ir functions/type_ext.sql

\ir types/permissions_scope_enum.sql
\ir types/role_enum.sql

\ir tables/users.sql
\ir tables/tenants.sql
\ir tables/tenant_memberships.sql
\ir tables/setting_defaults.sql
\ir tables/setting_overrides.sql
\ir tables/permissions.sql
