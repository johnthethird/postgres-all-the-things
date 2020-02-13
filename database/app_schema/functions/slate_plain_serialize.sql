CREATE OR REPLACE FUNCTION slate_plain_serialize (content_json jsonb)
RETURNS text
LANGUAGE plv8 AS $$
  var Slate = require('slate').default;
  var Plain = require('slate-plain-serializer').default;
  var slateValue = Slate.Value.fromJSON(content_json);
  return Plain.serialize(slateValue);
$$;
