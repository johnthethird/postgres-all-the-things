CREATE TABLE setting_defaults (
  key citext PRIMARY KEY CHECK(key ~* '^[a-z0-9\._]+$' AND length(key) < 255),
  value jsonb,
  description text,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now())::timestamptz,
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now())::timestamptz
);

COMMENT ON TABLE setting_defaults IS 'Contains default settings for all tenants.';

SELECT audit.audit_table('setting_defaults');
