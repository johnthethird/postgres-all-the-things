-- rambler up

CREATE SCHEMA config;

COMMENT ON SCHEMA config
  IS 'Tables/Functions for setting/getting configuration settings.';


CREATE TABLE config.settings_defaults (
  key citext PRIMARY KEY CHECK(key ~* '^[a-z0-9\._]+$' AND length(key) < 255),
  value jsonb,
  description text,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now())::timestamptz,
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now())::timestamptz
);

COMMENT ON TABLE config.settings_defaults IS 'Contains default settings for all tenants.';

SELECT audit.audit_table('config.settings_defaults');


CREATE TABLE config.settings (
  key citext NOT NULL REFERENCES config.settings_defaults(key) ON DELETE RESTRICT,
  value jsonb,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now())::timestamptz,
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now())::timestamptz,
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  PRIMARY KEY (tenant_id, key),
  CONSTRAINT unique_tenant_and_key UNIQUE (tenant_id, key)
);

COMMENT ON TABLE config.settings IS 'Contains overrides for default settings for specific tenants';

SELECT audit.audit_table('config.settings');
SELECT create_rls_policy('config.settings');


CREATE VIEW config.settings_combined AS
  SELECT d.key, COALESCE(s.value, d.value) as value, d.description, d.value as default_value
  FROM config.settings s
  RIGHT JOIN config.settings_defaults d ON d.key = s.key;


CREATE OR REPLACE FUNCTION config.get(text) RETURNS jsonb AS $$
    SELECT VALUE FROM config.settings_combined WHERE key = $1
$$ SECURITY DEFINER STABLE LANGUAGE sql;


CREATE OR REPLACE FUNCTION config.set(text, jsonb) RETURNS VOID AS $$
	INSERT INTO config.settings (key, value) VALUES ($1, $2)
	ON CONFLICT (key) DO UPDATE SET value = $2;
$$ SECURITY DEFINER LANGUAGE sql;
