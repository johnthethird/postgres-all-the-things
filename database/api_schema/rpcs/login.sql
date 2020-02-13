CREATE OR REPLACE FUNCTION login(email text, password text) RETURNS jsonb AS $$
DECLARE v_user_id UUID;
BEGIN
  SELECT id FROM public.users u WHERE u.email = $1 and u.password = public.crypt($2, u.password)
  INTO v_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid email/password'
    USING ERRCODE = '42501'; --http 403
  END IF;

  RETURN jsonb_build_object('token', app.create_jwt(v_user_id));
END
$$ LANGUAGE plpgsql SECURITY DEFINER;
