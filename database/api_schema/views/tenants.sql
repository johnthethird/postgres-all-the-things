-- This is only api view that shows records from outside the currently set tenant
CREATE VIEW tenants AS
  SELECT
    t.name, t.created_at, t.updated_at, t.id,
    CASE WHEN t.id = app.tenant_id() THEN true ELSE false END AS current_tenant
  FROM public.tenants t
  WHERE t.id = ANY(app.all_tenant_ids())
  ORDER BY current_tenant
;

ALTER VIEW tenants OWNER TO apiuser;
-- Must use rpc/create_tenants
REVOKE INSERT, UPDATE, DELETE ON tenants FROM apiuser;
