-- rambler up

-- TODO fix this whole issue
SELECT v8.plv8_require();

-- select pgjwt.create_token('8bbd1d34-4a6d-11e8-a2c5-acde48001122'::uuid);

DO LANGUAGE plv8 $$
  var Utils = plv8.require("utils");
  var masterTenant = Utils.insertOne("INSERT INTO tenants (id, name) VALUES ($1, $2)", ['82250144-4a61-11e8-a7f7-acde48001122', 'master_tenant']);
  var masterUser = Utils.insertOne("INSERT INTO users (id, firstname, lastname, email, password, roles) VALUES ($1, $2, $3, $4, $5, $6)",
    ['822158e6-4a61-11e8-a7f7-acde48001122', 'Master', 'User', 'master@mastertenant.local', 'password', ['SystemAdmin']]);
  Utils.insertOne("INSERT INTO tenant_memberships (tenant_id, user_id, roles) VALUES ($1, $2, $3)", [masterTenant.id, masterUser.id, ['Admin']]);


  var demoTenant = Utils.insertOne("INSERT INTO tenants (id, name) VALUES ($1, $2)", ['69962a52-4a6d-11e8-a2c5-acde48001122', 'demo_tenant']);
  var demoAdmin = Utils.insertOne("INSERT INTO users (id, firstname, lastname, email, password, roles) VALUES ($1, $2, $3, $4, $5, $6)", ['41f04f78-4a6d-11e8-a2c5-acde48001122', 'Demo', 'Admin', 'admin@demotenant.local', 'password', ['SystemUser']]);
  Utils.insertOne("INSERT INTO tenant_memberships (tenant_id, user_id, roles) VALUES ($1, $2, $3)", [demoTenant.id, demoAdmin.id, ['Admin']]);
  var demoUser = Utils.insertOne("INSERT INTO users (id, firstname, lastname, email, password, roles) VALUES ($1, $2, $3, $4, $5, $6)", ['8bbd1d34-4a6d-11e8-a2c5-acde48001122', 'Demo', 'User', 'user@demotenant.local', 'password', ['SystemUser']]);
  Utils.insertOne("INSERT INTO tenant_memberships (tenant_id, user_id, roles) VALUES ($1, $2, $3)", [demoTenant.id, demoUser.id, ['User']]);
  // Also a member of the master tenant
  Utils.insertOne("INSERT INTO tenant_memberships (tenant_id, user_id, roles) VALUES ($1, $2, $3)", [masterTenant.id, demoUser.id, ['User']]);


$$;

INSERT INTO config.settings_defaults VALUES ('jwt_secret', 'secretkeythats32charslongxxxxxxx', 'Must be 32 characters or more');
INSERT INTO config.settings_defaults VALUES ('jwt_lifetime', '999999', 'Lifetime of a JWT token in seconds');
