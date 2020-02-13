CREATE TABLE users (
  email email UNIQUE CHECK( email ~* '^.+@.+\..+$' AND length(email) < 255),
  firstname citext CHECK(length(firstname) < 255),
  lastname citext CHECK(length(lastname) < 255),
  roles role_enum[] NOT NULL DEFAULT '{SystemUser}',
  "password" text,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now())::timestamptz,
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now())::timestamptz,
  id UUID PRIMARY KEY DEFAULT uuid_generate_v1()
);

COMMENT ON TABLE users is 'A user of the application.';
COMMENT ON COLUMN users.id is 'UUID of the user.';
COMMENT ON COLUMN users.email is 'Email address of the user.';
COMMENT ON COLUMN users.password is 'Hashed password for the user.';
COMMENT ON COLUMN users.roles is 'System roles for the user.';

SELECT audit.audit_table('users');
SELECT app.create_row_trigger('set_updated_at', 'before update', 'users');

CREATE OR REPLACE FUNCTION users_biu() RETURNS TRIGGER AS $$
  BEGIN
    IF NEW.password IS NOT NULL THEN
    	NEW.password = crypt(NEW.password, gen_salt('bf'));
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_biu BEFORE INSERT OR UPDATE ON users FOR EACH ROW EXECUTE PROCEDURE users_biu()
