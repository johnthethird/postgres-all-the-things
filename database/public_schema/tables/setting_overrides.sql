CREATE TABLE setting_overrides (
  key citext NOT NULL REFERENCES setting_defaults(key) ON DELETE RESTRICT,
  value jsonb,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now())::timestamptz,
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now())::timestamptz,
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  PRIMARY KEY (tenant_id, key),
  CONSTRAINT unique_tenant_and_key UNIQUE (tenant_id, key)
);

COMMENT ON TABLE setting_overrides IS 'Contains overrides for default settings for specific tenants';

SELECT audit.audit_table('setting_overrides');
SELECT app.create_rls_policy('setting_overrides');
