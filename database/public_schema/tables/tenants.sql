CREATE TABLE tenants (
  name citext UNIQUE NOT NULL CHECK(name !~* '\W'),
  display_name text,
  owned_by UUID REFERENCES users(id) ON DELETE RESTRICT NOT NULL,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now())::timestamptz,
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now())::timestamptz,
  id uuid PRIMARY KEY DEFAULT uuid_generate_v1()
);

COMMENT ON TABLE tenants is 'A tenant. Main account for billing';
COMMENT ON COLUMN tenants.id is 'UUID of the tenant.';
COMMENT ON COLUMN tenants.name is 'Name of the tenant. Can only contain alphanumeric characters plus underscore.';
COMMENT ON COLUMN tenants.display_name is 'Display name of the tenant. Can be anything.';

SELECT audit.audit_table('tenants');
SELECT app.create_row_trigger('set_updated_at', 'before update', 'tenants');

-- tenants table is a bit different regarding RLS, we want to allow access to any tenant the user is a member of
-- plus you need to be able to create/delete teams. Probably do that via an RPC or something.
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenants FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenants_access_select ON tenants;
CREATE POLICY tenants_access_select ON tenants FOR ALL TO apiuser USING (id = ANY(app.all_tenant_ids()));
