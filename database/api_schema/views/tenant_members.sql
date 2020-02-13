-- Convenience which relies on RLS to show only users in the current team
CREATE VIEW tenant_members AS
  SELECT
    u.email,
    u.firstname,
    u.lastname,
    tm.created_at,
    to_jsonb(array_cat(tm.roles, u.roles)) AS roles,
    u.id
  FROM public.users u
  INNER JOIN public.tenant_memberships tm ON tm.user_id = u.id
;

ALTER VIEW tenant_members OWNER TO apiuser;

COMMENT ON VIEW tenant_members IS 'All users who are members of the current tenant';
COMMENT ON COLUMN tenant_members.roles IS 'Users role in the tenant';

CREATE FUNCTION tenant_members_insert() RETURNS TRIGGER
AS $$
DECLARE
  v_row public.users;
BEGIN
  PERFORM app.can_or_raise('ManageTenantMemberships');

  -- We need the useless update so that RETURNING works
  INSERT INTO public.users (firstname, lastname, email)
    VALUES (NEW.firstname, NEW.lastname, NEW.email)
    ON CONFLICT(email) DO UPDATE SET email = NEW.email
    RETURNING * INTO v_row;

  INSERT INTO public.tenant_memberships (user_id, roles)
    VALUES (v_row.id, jsonb_arr2text_arr(NEW.roles)::role_enum[]);

  -- Now that the record exists in the base table, copy the values from the view into the NEW record so we can return it
  EXECUTE format('SELECT * FROM %I.%I WHERE id = $1', TG_TABLE_SCHEMA, TG_TABLE_NAME) INTO NEW USING v_row.id;
  RETURN NEW;
END
$$ LANGUAGE plpgsql;
SELECT app.create_view_trigger('tenant_members', 'insert');


CREATE FUNCTION tenant_members_update() RETURNS TRIGGER
AS $$
DECLARE
  v_row public.tenant_memberships;
BEGIN
  PERFORM app.can_or_raise('ManageTenantMemberships');

  UPDATE public.tenant_memberships
    SET roles = jsonb_arr2text_arr(NEW.roles)::role_enum[]
    WHERE id = OLD.id
    RETURNING * INTO v_row;

  -- Now that the record exists in the base table, copy the values from the view into the NEW record so we can return it
  EXECUTE format('SELECT * FROM %I.%I WHERE id = $1', TG_TABLE_SCHEMA, TG_TABLE_NAME) INTO NEW USING v_row.id;
  RETURN NEW;
END
$$ LANGUAGE plpgsql;
SELECT app.create_view_trigger('tenant_members', 'update');


CREATE FUNCTION tenant_members_delete() RETURNS TRIGGER
AS $$
BEGIN
  PERFORM app.can_or_raise('ManageTenantMemberships');

  DELETE FROM public.tenant_memberships WHERE user_id = OLD.id;
END
$$ LANGUAGE plpgsql;
SELECT app.create_view_trigger('tenant_members', 'delete');
