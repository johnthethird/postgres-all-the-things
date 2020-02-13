CREATE OR REPLACE FUNCTION get_setting_text(text) RETURNS text AS $$
  -- https://stackoverflow.com/questions/27215216/postgres-how-to-convert-json-string-to-text
  SELECT VALUE#>>'{}' FROM api.settings WHERE key = $1
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_setting_jsonb(text) RETURNS jsonb AS $$
  SELECT VALUE FROM api.settings WHERE key = $1
$$ LANGUAGE sql;
