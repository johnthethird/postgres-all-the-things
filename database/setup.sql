\set QUIET off
\set ON_ERROR_STOP on
/* set client_min_messages to warning; */
set client_min_messages to notice;
SET check_function_bodies = false;

-- load some variables from the env
/* \set anonymous `echo $DB_ANON_ROLE`
\set authenticator `echo $DB_USER`
\set authenticator_pass `echo $DB_PASS`
\set jwt_secret `echo $JWT_SECRET`
\set quoted_jwt_secret '\'' :jwt_secret '\'' */

\echo # Initializing Database

-- begin;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE EXTENSION IF NOT EXISTS citext;

-- Idempotent role creation for postgREST users
DO $$ BEGIN
  IF NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname='anonymous') THEN
    CREATE ROLE anonymous NOINHERIT;
  END IF;

  IF NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname='authenticator') THEN
    CREATE USER authenticator NOINHERIT;
  END IF;

  IF NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname='apiuser') THEN
    CREATE ROLE apiuser NOINHERIT;
  END IF;
END $$;


\echo # Loading database definition


\ir lib/audit/all.sql
\ir lib/v8/all.sql
\ir lib/pgjwt/all.sql


SET search_path TO public;
GRANT USAGE ON SCHEMA public TO anonymous, apiuser, authenticator;
-- Grant everything and use RLS to enforce permissions
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO anonymous, apiuser, authenticator;

\ir public_schema/functions/type_ext.sql

\ir public_schema/types/permissions_scope_enum.sql
\ir public_schema/types/role_enum.sql
\ir public_schema/types/email_domain.sql

\ir app_schema/all.sql

SET search_path TO public;
\ir public_schema/tables/users.sql
\ir public_schema/tables/tenants.sql
\ir public_schema/tables/tenant_memberships.sql
\ir public_schema/tables/setting_defaults.sql
\ir public_schema/tables/setting_overrides.sql
\ir public_schema/tables/permissions.sql


\ir api_schema/all.sql
\ir seed_data.sql
\ir sample_data.sql

-- commit;
\echo # ==========================================
