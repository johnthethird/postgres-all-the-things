CREATE TABLE tenant_memberships (
  tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES users(id) NOT NULL,
  roles role_enum[] NOT NULL DEFAULT '{TenantUser}',
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now())::timestamptz,
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now())::timestamptz,
  id UUID PRIMARY KEY DEFAULT uuid_generate_v1()
);

CREATE UNIQUE INDEX idx_tenant_memberships ON tenant_memberships(user_id, tenant_id);

SELECT audit.audit_table('tenant_memberships');
SELECT app.create_row_trigger('set_updated_at', 'before update', 'tenant_memberships');
SELECT app.create_row_trigger('set_tenant_id', 'before insert or update', 'tenant_memberships');
SELECT app.create_rls_policy('tenant_memberships');
