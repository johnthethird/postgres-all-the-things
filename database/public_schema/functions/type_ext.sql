CREATE OR REPLACE FUNCTION jsonb_arr2text_arr(_js jsonb) RETURNS text[] AS $$
  SELECT ARRAY(SELECT jsonb_array_elements_text(_js))
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION array_distinct(anyarray) RETURNS anyarray AS $$
  SELECT array_agg(DISTINCT x) FROM unnest($1) t(x);
$$ LANGUAGE sql IMMUTABLE;


-- These are required by the audit functions

CREATE OR REPLACE FUNCTION "jsonb_minus" ( "left" JSONB, "keys" TEXT[] )
  RETURNS JSONB
  LANGUAGE SQL
  IMMUTABLE
  STRICT
AS $$
  SELECT
    CASE
      WHEN "left" ?| "keys"
        THEN COALESCE(
          (SELECT ('{' ||
                    string_agg(to_json("key")::TEXT || ':' || "value", ',') ||
                    '}')
             FROM jsonb_each("left")
            WHERE "key" <> ALL ("keys")),
          '{}'
        )::JSONB
      ELSE "left"
    END
$$;

CREATE OPERATOR - (
  LEFTARG = JSONB,
  RIGHTARG = TEXT[],
  PROCEDURE = jsonb_minus
);

COMMENT ON FUNCTION jsonb_minus(JSONB, TEXT[]) IS 'Delete specificed keys';

COMMENT ON OPERATOR - (JSONB, TEXT[]) IS 'Delete specified keys';

--
-- Implements "JSONB- JSONB" operation to recursively delete matching pairs.
--
-- Credit:
-- http://coussej.github.io/2016/05/24/A-Minus-Operator-For-PostgreSQLs-JSONB/
--

CREATE OR REPLACE FUNCTION "jsonb_minus" ( "left" JSONB, "right" JSONB )
  RETURNS JSONB
  LANGUAGE SQL
  IMMUTABLE
  STRICT
AS $$
  SELECT
    COALESCE(json_object_agg(
      "key",
      CASE
        -- if the value is an object and the value of the second argument is
        -- not null, we do a recursion
        WHEN jsonb_typeof("value") = 'object' AND "right" -> "key" IS NOT NULL
        THEN jsonb_minus("value", "right" -> "key")
        -- for all the other types, we just return the value
        ELSE "value"
      END
    ), '{}')::JSONB
  FROM
    jsonb_each("left")
  WHERE
    "left" -> "key" <> "right" -> "key"
    OR "right" -> "key" IS NULL
$$;

CREATE OPERATOR - (
  LEFTARG   = JSONB,
  RIGHTARG  = JSONB,
  PROCEDURE = jsonb_minus
);

COMMENT ON FUNCTION jsonb_minus(JSONB, JSONB)
  IS 'Delete matching pairs in the right argument from the left argument';

COMMENT ON OPERATOR - (JSONB, JSONB)
  IS 'Delete matching pairs in the right argument from the left argument';
