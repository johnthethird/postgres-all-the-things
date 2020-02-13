CREATE VIEW settings AS
  SELECT d.key, COALESCE(s.value, d.value) as value, d.description, d.value as default_value
  FROM public.setting_overrides s
  RIGHT JOIN public.setting_defaults d ON d.key = s.key;
