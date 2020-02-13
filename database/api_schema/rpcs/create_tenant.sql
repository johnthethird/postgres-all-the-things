CREATE OR REPLACE FUNCTION create_tenant(p_tenant_name text, p_owner_email text) RETURNS SETOF public.tenants
SECURITY DEFINER
AS $$
DECLARE
  v_tenant public.tenants;
  v_user public.users;
BEGIN
  PERFORM app.can_or_raise('CreateTenant');

  INSERT INTO public.users (email) VALUES(p_owner_email)
    ON CONFLICT(email) DO UPDATE SET email = p_owner_email RETURNING * INTO v_user;

  INSERT INTO public.tenants (name, owned_by) VALUES (p_tenant_name, v_user.id) RETURNING * INTO v_tenant;

  INSERT INTO public.tenant_memberships (tenant_id, user_id, roles) VALUES (v_tenant.id, v_user.id, '{TenantAdmin}');

  -- Have to use public.tenants here so that we can get a tenant outside our current tenant
  RETURN QUERY SELECT * FROM public.tenants WHERE id = v_tenant.id;
END
$$ LANGUAGE plpgsql;
