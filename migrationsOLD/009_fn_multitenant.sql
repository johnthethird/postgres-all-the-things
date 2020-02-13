-- rambler up

CREATE OR REPLACE FUNCTION app_user_id() RETURNS uuid LANGUAGE sql AS $$
  SELECT current_setting('app.user_id', true)::uuid;
$$;

CREATE OR REPLACE FUNCTION app_tenant_id() RETURNS uuid LANGUAGE sql AS $$
  SELECT current_setting('app.tenant_id', true)::uuid;
$$;

CREATE OR REPLACE FUNCTION app_set_user_and_tenant(p_email text, p_tenant_id uuid, p_local boolean = true)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_tenant_name text;
  v_user_id uuid;
BEGIN
  SELECT id FROM public.users WHERE email = p_email INTO v_user_id;
  IF NOT FOUND THEN
    RAISE 'user % not found', p_email
    USING ERRCODE = '42501'; --http 403
  END IF;

  PERFORM FROM public.tenant_memberships tm
  INNER JOIN public.tenants t ON t.id = tm.tenant_id
  WHERE user_id = v_user_id AND t.id = p_tenant_id;

  IF NOT FOUND THEN
    SELECT COALESCE(name, '(Unknown Tenant)') FROM public.tenants WHERE id = p_tenant_id INTO v_tenant_name;
    RAISE 'user % is not a member of tenant %', p_email, v_tenant_name
    USING ERRCODE = '42501'; --http 403
  END IF;

  PERFORM set_config('app.user_id', v_user_id::text, p_local);
  PERFORM set_config('app.tenant_id', p_tenant_id::text, p_local);
END $$;

-- Convenience to set by team name instead of ID
CREATE OR REPLACE FUNCTION app_set_user_and_tenant(p_email text, p_tenant_name text, p_local boolean = true)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_tenant_id uuid;
BEGIN
  SELECT id FROM public.tenants WHERE name = p_tenant_name INTO v_tenant_id;
  PERFORM app_set_user_and_tenant(p_email, v_tenant_id, p_local);
END $$;


-- All tenants a user has access to. Doing it here in a security definer func so we can see
-- all tenants and bypass RLS
CREATE OR REPLACE FUNCTION app_all_tenant_ids() RETURNS uuid[] LANGUAGE sql SECURITY DEFINER AS $$
  SELECT array_agg(tenant_id)
  FROM tenant_memberships
  WHERE user_id = app_user_id();
$$;


CREATE OR REPLACE FUNCTION app_request_var(v text) RETURNS text LANGUAGE sql SECURITY DEFINER AS $$
  SELECT NULLIF(current_setting('request.' || v, true), '');
$$;



-- Munge all postgREST specific stuff into our own vars to specify user and tenant
CREATE OR REPLACE FUNCTION app_pre_request() RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
  v_email text;
  v_tenant_name text;
  v_tenant_id UUID;
BEGIN
  -- EXECUTE 'SET LOCAL ROLE apiuser';

  v_email =  app_request_var('jwt.claim.email');

  PERFORM app_set_user_and_tenant(v_email, '69962a52-4a6d-11e8-a2c5-acde48001122'::uuid);

  /* BEGIN
    -- Allow for specifying tenant in a header (so a user can be a member of multiple tenants).
    -- If not specified, we use the most recently updated membership's tenant.
    IF NULLIF(current_setting('request.header.x-tenant-name', true), '') IS NOT NULL THEN
      v_tenant_name = current_setting('request.header.x-tenant-name', true);
      PERFORM app_set_user_and_team(v_email, v_tenant_name);
    ELSIF NULLIF(current_setting('request.header.x-tenant-name', true), '') IS NOT NULL THEN
      v_tenant_id = current_setting('request.header.x-tenant-id')::UUID;
      PERFORM app_set_user_and_team(v_email, v_tenant_id);
    END IF;
  EXCEPTION
    WHEN invalid_text_representation THEN RAISE 'Header X-TENANT-ID is not a valid UUID (%)', v_tenant_id::text;
    WHEN undefined_object THEN RAISE 'Required Header X-TENANT-ID is not present';
  END; */

  -- Allow for setting the team via name or ID. Provide nice error msg if team ID is invalid UUID
  /* BEGIN
    IF NULLIF(current_setting('request.header.x-tenant-name', true), '') IS NOT NULL THEN
      v_tenant_name = current_setting('request.header.x-tenant-name', true);
      PERFORM app_set_user_and_team(v_email, v_tenant_name);
    ELSE
      v_tenant_id = current_setting('request.header.x-tenant-id')::UUID;
      PERFORM app_set_user_and_team(v_email, v_tenant_id);
    END IF;
  EXCEPTION
    WHEN invalid_text_representation THEN RAISE 'Required Header X-TENANT-ID is not a valid UUID (%)', v_tenant_id::text;
    WHEN undefined_object THEN RAISE 'Required Header X-TENANT-ID is not present';
  END; */


  -- Now, if the user from the JWT is a bonafide superuser, allow for some impersonation
  -- TODO check superuser status somehow
  IF NULLIF(current_setting('request.header.x-impersonate-email', true), '') IS NOT NULL THEN
    v_email = current_setting('request.header.x-impersonate-email', true);
    v_tenant_name = current_setting('request.header.x-impersonate-team-name', true);
    PERFORM app_set_user_and_team(v_email, v_tenant_name);
  END IF;

  -- Debug logging
  IF NULLIF(current_setting('request.header.x-debug', true), '') IS NOT NULL THEN
    raise warning 'x-tenant-id:%',   NULLIF(current_setting('request.header.x-tenant-id', true), '');
    raise warning 'x-tenant-name:%', NULLIF(current_setting('request.header.x-tenant-name', true), '');
    raise warning 'x-impersonate-email:%', NULLIF(current_setting('request.header.x-impersonate-email', true), '');
    raise warning 'x-impersonate-team-name:%', NULLIF(current_setting('request.header.x-impersonate-team-name', true), '');
    raise warning 'jwt.claim.email:%', NULLIF(current_setting('request.jwt.claim.email', true), '');
    raise warning 'jwt.claim.role:%', NULLIF(current_setting('request.jwt.claim.role', true), '');
    -- raise warning 'app_user_id:%', app_user_id();
    -- raise warning 'app_team_id:%', app_team_id();
  END IF;

  -- used in the audit log table
  PERFORM set_config('application_name', 'postgREST', true);

  -- TODO cool, but is this really necessary?
  SET plv8.start_proc = 'v8.plv8_require';
END $$;
