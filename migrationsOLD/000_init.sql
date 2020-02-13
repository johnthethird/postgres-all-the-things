-- rambler up

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

-- Dont worry about api schema here
GRANT USAGE ON SCHEMA public TO anonymous, apiuser, authenticator;
-- Grant everything and use RLS to enforce permissions
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO anonymous, apiuser, authenticator;
