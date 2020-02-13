CREATE OR REPLACE FUNCTION set_user_and_tenant(p_user_id uuid, p_tenant_id uuid, p_local boolean = true)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_tenant public.tenants;
  v_user public.users;
BEGIN
  SELECT * FROM public.users WHERE id = p_user_id INTO v_user;
  IF NOT FOUND THEN
    RAISE 'User ID % not found', p_user_id
    USING ERRCODE = '42501'; --http 403
  END IF;

  SELECT * FROM public.tenants WHERE id = p_tenant_id INTO v_tenant;
  IF NOT FOUND THEN
    RAISE 'Tenant ID % not found', p_tenant_id
    USING ERRCODE = '42501'; --http 403
  END IF;

  PERFORM FROM public.tenant_memberships
  WHERE user_id = v_user.id AND tenant_id = v_tenant.id;

  IF NOT FOUND THEN
    RAISE 'user % is not a member of tenant %', v_user.email, v_tenant.name
    USING ERRCODE = '42501'; --http 403
  END IF;

  RAISE warning 'User % Tenant %', v_user.id::text, v_tenant.id::text;
  PERFORM set_config('app.user_id', v_user.id::text, p_local);
  PERFORM set_config('app.tenant_id', v_tenant.id::text, p_local);
END $$;


CREATE OR REPLACE FUNCTION user_id() RETURNS UUID LANGUAGE plpgsql AS $$
  BEGIN
    RETURN (SELECT current_setting('app.user_id', false)::UUID);
  EXCEPTION
    WHEN invalid_text_representation THEN RAISE 'app.user_id setting is not a valid UUID';
    WHEN undefined_object THEN RAISE 'The apiuser role requires that the app.user_id GUC is set.';
  END;
$$;


CREATE OR REPLACE FUNCTION tenant_id() RETURNS UUID LANGUAGE plpgsql AS $$
  BEGIN
    RETURN (SELECT current_setting('app.tenant_id', false)::UUID);
  EXCEPTION
    WHEN invalid_text_representation THEN RAISE 'app.tenant_id setting is not a valid UUID';
    WHEN undefined_object THEN RAISE 'The apiuser role requires that the app.tenant_id GUC is set.';
  END;
$$;

-- All tenants a user has access to. Doing it here in a security definer func so we can see
-- all tenants and bypass RLS
CREATE OR REPLACE FUNCTION all_tenant_ids() RETURNS uuid[] LANGUAGE sql SECURITY DEFINER AS $$
  SELECT array_agg(tenant_id)
  FROM public.tenant_memberships
  WHERE user_id = app.user_id();
$$;

CREATE OR REPLACE FUNCTION request_var(v text) RETURNS text LANGUAGE sql SECURITY DEFINER AS $$
  SELECT NULLIF(current_setting('request.' || v, true), '');
$$;


-- Munge all postgREST specific stuff into our own vars to specify user and tenant
CREATE OR REPLACE FUNCTION pre_request() RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_user_id UUID;
  v_tenant_id UUID;
BEGIN

  -- used in the audit log table
  PERFORM set_config('application_name', 'postgREST', true);

  -- TODO cool, but is this really necessary?
  SET plv8.start_proc = 'v8.plv8_require';

  -- If we are an anonymous user bail out of the rest of this
  IF app.request_var('jwt.claim.role') = 'anonymous' THEN
    RETURN;
  END IF;



  SELECT id FROM public.users WHERE email = app.request_var('jwt.claim.email')::public.citext
  INTO v_user_id;
  IF NOT FOUND THEN
    RAISE 'User % not found', app.request_var('jwt.claim.email')
    USING ERRCODE = '42501'; --http 403
  END IF;


  -- Allow for specifying tenant in a header (so a user can be a member of multiple tenants).
  -- If not specified, we use the most recently updated membership's tenant.
  IF app.request_var('header.x-tenant-name') IS NOT NULL THEN
    SELECT id FROM public.tenants WHERE name = app.request_var('header.x-tenant-name')::public.citext
    INTO v_tenant_id;
  ELSE
    SELECT tenant_id FROM public.tenant_memberships WHERE user_id = v_user_id ORDER BY updated_at DESC LIMIT 1
    INTO v_tenant_id;
  END IF;

  PERFORM app.set_user_and_tenant(v_user_id, v_tenant_id);

  -- Now that current user is set, if they have permission allow for some impersonation and reset the current user
  IF app.request_var('header.x-impersonate-email') IS NOT NULL AND app.can('ImpersonateUser') THEN
    SELECT id FROM public.users WHERE email = app.request_var('header.x-impersonate-email')::public.citext
    INTO v_user_id;

    SELECT id FROM public.tenants WHERE name = app.request_var('header.x-impersonate-tenant-name')::public.citext
    INTO v_tenant_id;

    PERFORM app.set_user_and_tenant(v_user_id, v_tenant_id);
  END IF;

  -- Debug logging
  IF app.request_var('header.x-debug') IS NOT NULL THEN
    raise warning 'x-tenant-name:%', app.request_var('header.x-tenant-name');
    raise warning 'x-impersonate-email:%', app.request_var('header.x-impersonate-email');
    raise warning 'x-impersonate-tenant-name:%', app.request_var('header.x-impersonate-tenant-name');
    raise warning 'jwt.claim.email:%', app.request_var('jwt.claim.email');
    raise warning 'jwt.claim.role:%', app.request_var('jwt.claim.role');
    raise warning 'user_id:%', app.user_id();
    raise warning 'tenant_id:%', app.tenant_id();
  END IF;

END $$;
