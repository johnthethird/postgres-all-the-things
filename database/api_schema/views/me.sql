CREATE VIEW me AS
  SELECT
    (SELECT row_to_json(t) FROM (SELECT id, email FROM tenant_members WHERE id = app.user_id()) t) AS user,
    (SELECT row_to_json(t) FROM (SELECT id, name  FROM tenants WHERE id = app.tenant_id()) t) AS tenant,
    (SELECT to_jsonb(array_agg(row_to_json(t))) FROM (SELECT * FROM tenants) t) AS all_tenants
;

ALTER VIEW me OWNER TO apiuser;
