-- rambler up

CREATE SCHEMA pgjwt;

COMMENT ON SCHEMA pgjwt
  IS 'Library functions related to creating, signing and verifying JWT tokens';

CREATE OR REPLACE FUNCTION pgjwt.url_encode(data bytea) RETURNS text LANGUAGE sql AS $$
  SELECT translate(encode(data, 'base64'), E'+/=\n', '-_');
$$;


CREATE OR REPLACE FUNCTION pgjwt.url_decode(data text) RETURNS bytea LANGUAGE sql AS $$
WITH t AS (SELECT translate(data, '-_', '+/')),
     rem AS (SELECT length((SELECT * FROM t)) % 4) -- compute padding size
    SELECT decode(
        (SELECT * FROM t) ||
        CASE WHEN (SELECT * FROM rem) > 0
           THEN repeat('=', (4 - (SELECT * FROM rem)))
           ELSE '' END,
    'base64');
$$;


CREATE OR REPLACE FUNCTION pgjwt.algorithm_sign(signables text, secret text, algorithm text)
RETURNS text LANGUAGE sql AS $$
  WITH
    alg AS (
      SELECT CASE
        WHEN algorithm = 'HS256' THEN 'sha256'
        WHEN algorithm = 'HS384' THEN 'sha384'
        WHEN algorithm = 'HS512' THEN 'sha512'
        ELSE '' END)  -- hmac throws error
  SELECT pgjwt.url_encode(hmac(signables, secret, (SELECT * FROM alg)));
$$;


CREATE OR REPLACE FUNCTION pgjwt.sign(payload json, secret text, algorithm text DEFAULT 'HS256')
RETURNS text LANGUAGE sql AS $$
  WITH
    header AS (
      SELECT pgjwt.url_encode(convert_to('{"alg":"' || algorithm || '","typ":"JWT"}', 'utf8'))
      ),
    payload AS (
      SELECT pgjwt.url_encode(convert_to(payload::text, 'utf8'))
      ),
    signables AS (
      SELECT (SELECT * FROM header) || '.' || (SELECT * FROM payload)
      )
  SELECT
      (SELECT * FROM signables)
      || '.' ||
      pgjwt.algorithm_sign((SELECT * FROM signables), secret, algorithm);
$$;


CREATE OR REPLACE FUNCTION pgjwt.verify(token text, secret text, algorithm text DEFAULT 'HS256')
RETURNS table(header json, payload json, valid boolean) AS $$
  SELECT
    convert_from(pgjwt.url_decode(r[1]), 'utf8')::json AS header,
    convert_from(pgjwt.url_decode(r[2]), 'utf8')::json AS payload,
    r[3] = pgjwt.algorithm_sign(r[1] || '.' || r[2], secret, algorithm) AS valid
  FROM regexp_split_to_array(token, '\.') r;
$$ STABLE LANGUAGE sql;

-- Public API

CREATE OR REPLACE FUNCTION pgjwt.create_token(p_user_id uuid) RETURNS TEXT AS $$
  DECLARE
    v_payload json;
    v_token text;
  BEGIN
    SELECT json_build_object(
      'email', email,
      'role', 'apiuser', -- apiuser is the PG role all PostgREST requests run under
      'exp', extract(epoch from now())::integer + config.get('jwt_lifetime')::int
    )
    FROM users
    WHERE id = p_user_id
    INTO v_payload;

    SELECT pgjwt.sign(v_payload, config.get('jwt_secret')) INTO v_token;

    RETURN v_token;
  END;
$$ STABLE LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pgjwt.verify_token(token text) RETURNS table(header json, payload json, valid boolean) AS $$
  SELECT * FROM pgjwt.verify(token, config.get('jwt_secret'));
$$ STABLE LANGUAGE sql;
