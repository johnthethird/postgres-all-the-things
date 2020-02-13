-- TODO use view instead
CREATE OR REPLACE FUNCTION can (p_permission citext,
                                p_scope permissions_scope_enum,
                                p_scoped_object_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql AS $$
DECLARE
  v_is_allowed boolean = false;
  v_scoped_roles role_enum[];
BEGIN

  SELECT roles
  FROM api.my_roles
  WHERE scope = p_scope AND scoped_object_id = p_scoped_object_id
  INTO v_scoped_roles;
  raise notice 'CHECK CAN % % %', p_scope, p_scoped_object_id, v_scoped_roles;
  -- Denys take precedence over allows
  SELECT NOT (v_scoped_roles && denied_roles) AND (v_scoped_roles && allowed_roles)
  FROM public.permissions
  WHERE scope = p_scope AND name = p_permission
  INTO v_is_allowed;

  IF v_is_allowed IS NULL THEN
    RAISE 'Permission % is not valid for scope %. Ensure the permission you are checking for exists in permissions table.', p_permission, p_scope;
  END IF;

  RETURN v_is_allowed;
END
$$;

-- Convenience to just check current-tenant scoped permission
CREATE OR REPLACE FUNCTION can (p_permission citext)
RETURNS BOOLEAN
LANGUAGE plpgsql AS $$
BEGIN
  RETURN app.can(p_permission, 'Tenant', app.tenant_id());
END
$$;


-- Raise error if user does not have specified permission
CREATE OR REPLACE FUNCTION can_or_raise (p_permission citext,
                                         p_scope permissions_scope_enum,
                                         p_scoped_object_id UUID)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  IF app.can(p_permission, p_scope, p_scoped_object_id) THEN
    RETURN;
  ELSE
    RAISE insufficient_privilege USING DETAIL = 'You do not have the required permissions to perform this action';
  END IF;
END
$$;

-- Convenience to just check system and current-tenant scoped permissions, and raise
CREATE OR REPLACE FUNCTION can_or_raise (p_permission citext)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM app.can_or_raise(p_permission, 'Tenant', app.tenant_id());
END
$$;
