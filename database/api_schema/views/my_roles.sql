CREATE VIEW my_roles AS

  WITH tenant_roles AS (
     SELECT
       'Tenant'::permissions_scope_enum AS scope,
       t.name AS scoped_object_name,
       tm.tenant_id AS scoped_object_id,
       tm.roles::role_enum[]
     FROM public.tenant_memberships tm
     INNER JOIN public.tenants t ON t.id = tm.tenant_id
     WHERE tm.user_id = app.user_id()
  )

  SELECT
    scope,
    scoped_object_name,
    scoped_object_id,
    roles || (SELECT roles FROM public.users u WHERE u.id = app.user_id()) AS roles
  FROM tenant_roles

  /* UNION

  SELECT
   'Board' AS scope,
   name AS scoped_object_name,
   id AS scoped_object_id,
   roles::text[],
   roles::text[] || (SELECT roles FROM tenant_roles) AS combined_roles
  FROM my_boards */
;


COMMENT ON VIEW my_roles IS $$A users roles for every object they are a member of (Tenants, etc).
Note that this view will **only** display the roles you have for the currently selected tenant.
$$;

COMMENT ON COLUMN my_roles.roles IS 'Combined roles for the scoped object itself **and** the System.';

ALTER VIEW my_roles OWNER TO apiuser;
