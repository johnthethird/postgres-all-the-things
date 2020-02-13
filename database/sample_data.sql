CREATE OR REPLACE FUNCTION app.create_sample_tenant(p_tenant_name text, p_owner_email text, size integer = 1) RETURNS VOID
LANGUAGE plv8
AS $$

  var faker = require("faker");
  var _ = require("lodash");
  var utils = require("utils");
  var Plain = require("slate-plain-serializer").default
  var MAX_MEMBERS = 10 * size;

  //-- Become superuser, and create a tenant with an owner
  utils.run("app.set_user_and_tenant('00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002')");
  var owner = utils.insertOne("INSERT INTO users (firstname, lastname, email) VALUES ('owner', 'owner', $1)", [p_owner_email]);
  owner = owner || utils.selectOne("SELECT * FROM users WHERE email = $1", [p_owner_email]);
  var tenant = utils.run("api.create_tenant($1, $2)", [p_tenant_name, owner.email]);

  //-- Now, become the tenant owner and start doing stuff
  utils.run("app.set_user_and_tenant($1,$2,$3)", [owner.id, tenant.id, false]);

  var members = [];
  for (var i = 0; i < MAX_MEMBERS; i++) {
    var vals = [faker.internet.email(), faker.name.firstName(), faker.name.lastName(), ['TenantUser']];
    members.push(utils.insertOne("INSERT INTO api.tenant_members (email, firstname, lastname, roles) VALUES ($1,$2,$3,$4)", vals));
  }
$$;

CREATE OR REPLACE FUNCTION app.delete_sample_tenant(p_tenant_name text) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
AS $$
  BEGIN
    DELETE FROM public.tenants WHERE name = p_tenant_name;
  END
$$;

-- To simulate running via postgREST, change to apiuser
SET ROLE apiuser;
SET plv8.start_proc = 'v8.plv8_require';
/* select v8.plv8_require(); */
select app.delete_sample_tenant('Acme');
select app.create_sample_tenant('Acme', 'owner@acme.com', 10);

select app.delete_sample_tenant('Blort');
select app.create_sample_tenant('Blort', 'owner@acme.com', 10);
