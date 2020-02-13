CREATE OR REPLACE FUNCTION create_jwt(p_user_id uuid) RETURNS TEXT AS $$
  DECLARE
    v_payload jsonb;
    v_token text;
  BEGIN
    SELECT jsonb_build_object(
      'email', email,
      'exp', extract(epoch from now())::int + app.get_setting_text('jwt_lifetime')::int,
      'role', 'apiuser' -- apiuser is the PG role all PostgREST requests run under
    )
    FROM public.users
    WHERE id = p_user_id
    INTO v_payload;

    SELECT pgjwt.sign(v_payload, app.get_setting_text('jwt_secret')) INTO v_token;

    RETURN v_token;
  END;
$$ STABLE LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION verify_jwt(token text) RETURNS table(header jsonb, payload jsonb, valid boolean) AS $$
  SELECT * FROM pgjwt.verify(token, app.get_setting_text('jwt_secret'));
$$ STABLE LANGUAGE sql;
