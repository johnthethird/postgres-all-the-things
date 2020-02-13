CREATE SCHEMA pgjwt;

COMMENT ON SCHEMA pgjwt
  IS 'Library functions related to creating, signing and verifying JWT tokens';

GRANT USAGE ON SCHEMA pgjwt TO public;

SET search_path TO pgjwt,public;

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
  SELECT pgjwt.url_encode(public.hmac(signables, secret, (SELECT * FROM alg)));
$$;


CREATE OR REPLACE FUNCTION pgjwt.sign(payload jsonb, secret text, algorithm text DEFAULT 'HS256')
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
RETURNS table(header jsonb, payload jsonb, valid boolean) AS $$
  SELECT
    convert_from(pgjwt.url_decode(r[1]), 'utf8')::jsonb AS header,
    convert_from(pgjwt.url_decode(r[2]), 'utf8')::jsonb AS payload,
    r[3] = pgjwt.algorithm_sign(r[1] || '.' || r[2], secret, algorithm) AS valid
  FROM regexp_split_to_array(token, '\.') r;
$$ STABLE LANGUAGE sql;
