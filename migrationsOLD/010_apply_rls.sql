-- rambler up

-- tenants table is a bit different regarding RLS, we want to allow access to any tenant the user is a member of
-- plus you need to be able to create/delete teams. Probably do that via an RPC or something.
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenants FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenants_access_select ON teams;
CREATE POLICY tenants_access_select ON tenants FOR SELECT TO apiuser USING (id = ANY(app_all_tenant_ids()));


-- Normally you would put these in the table migration itself, but due to circular deps with the tenant tables we have to do it here
SELECT create_rls_policy('tenant_memberships');
