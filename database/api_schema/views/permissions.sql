CREATE VIEW permissions AS

  WITH
  tenant_roles AS (
    SELECT
      'Tenant'::permissions_scope_enum AS scope,
      t.name AS scoped_object_name,
      tm.tenant_id AS scoped_object_id,
      tm.roles::role_enum[]
    FROM public.tenant_memberships tm
    INNER JOIN public.tenants t ON t.id = tm.tenant_id
    WHERE tm.user_id = app.user_id()
  ),
  combined_roles AS (
    SELECT
      scope,
      scoped_object_name,
      scoped_object_id,
      roles || (SELECT roles FROM public.users u WHERE u.id = app.user_id()) AS roles
    FROM tenant_roles tr
  )
  SELECT
     p.name,
     p.scope,
     cr.scoped_object_name,
     cr.scoped_object_id,
     NOT (roles && denied_roles) AND (roles && allowed_roles) as can,
     p.allowed_roles,
     p.denied_roles,
     cr.roles
  FROM public.permissions p
  INNER JOIN combined_roles cr ON cr.scope = p.scope
;

ALTER VIEW permissions OWNER TO apiuser;
