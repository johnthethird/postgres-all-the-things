SET search_path TO public;

INSERT INTO permissions (name, scope, allowed_roles) VALUES ('CreateTenant', 'Tenant', '{SystemAdmin}');
INSERT INTO permissions (name, scope, allowed_roles) VALUES ('UpdateTenant', 'Tenant', '{SystemAdmin}');
INSERT INTO permissions (name, scope, allowed_roles) VALUES ('DeleteTenant', 'Tenant', '{SystemAdmin}');
INSERT INTO permissions (name, scope, allowed_roles) VALUES ('ImpersonateUser', 'Tenant', '{SystemAdmin}');
INSERT INTO permissions (name, scope, allowed_roles) VALUES ('ManageSettings', 'Tenant', '{TenantAdmin}');
INSERT INTO permissions (name, scope, allowed_roles) VALUES ('ManageTenantMemberships', 'Tenant', '{TenantAdmin}');

INSERT INTO setting_defaults VALUES ('jwt_secret', '"secretkeythats32charslongxxxxxxx"', 'Must be 32 characters or more');
INSERT INTO setting_defaults VALUES ('jwt_lifetime', '999999', 'Lifetime of a JWT token in seconds');

-- Operate directly on tables as postgres user to bypass RLS for this seed data

SELECT v8.plv8_require();

DO LANGUAGE plv8 $$
  var Utils = require("utils");
  var masterUser = Utils.insertOne("INSERT INTO users (id, firstname, lastname, email, password, roles) VALUES ($1, $2, $3, $4, $5, $6)",
    ['00000000-0000-0000-0000-000000000001', 'Master', 'User', 'master@mastertenant.local', 'password', ['SystemAdmin']]);
  var masterTenant = Utils.insertOne("INSERT INTO tenants (id, name, owned_by) VALUES ($1, $2, $3)", ['00000000-0000-0000-0000-000000000002', 'master_tenant', masterUser.id]);
  Utils.insertOne("INSERT INTO tenant_memberships (tenant_id, user_id, roles) VALUES ($1, $2, $3)", [masterTenant.id, masterUser.id, ['TenantAdmin']]);
  var jwt = Utils.run("app.create_jwt($1)", [masterUser.id]);
  Utils.log(jwt);
$$;


/* CREATE OR REPLACE FUNCTION public.create_sample_team(p_team_name text, p_owner_email text, size integer = 1) RETURNS VOID
LANGUAGE plv8
SET search_path=api,public
AS $$

  var faker = require("faker");
  var _ = require("lodash");
  var utils = require("utils");
  var Plain = require("slate-plain-serializer").default
  var MAX_MEMBERS = 10 * size;
  var MAX_EXPERTS = 5 * size;
  var MAX_KARDS = 10 * size;
  var MAX_QUESTIONS = 5 * size;

  //-- Become superuser, and create a team with an owner
  utils.run("app_set_user_and_team('superuser@masterteam.local','MasterTeam', false)");
  var owner = utils.insertOne("INSERT INTO users (firstname, lastname, email) VALUES ('owner', 'owner', $1)", [p_owner_email]);
  var team = utils.run("create_team($1, $2)", [p_team_name, owner.email]);

  //-- Now, become the team owner and start doing stuff
  utils.run("app_set_user_and_team($1,$2, false)", [owner.email, team.name]);

  var members = [];
  for (var i = 0; i < MAX_MEMBERS; i++) {
    var vals = [faker.internet.email(), faker.name.firstName(), faker.name.lastName(), ['TeamMember']];
    members.push(utils.insertOne("INSERT INTO team_members (email, firstname, lastname, roles) VALUES ($1,$2,$3,$4)", vals));
  }

  var experts = [];
  for (var i = 0; i < MAX_EXPERTS; i++) {
    var vals = [faker.internet.email(), faker.name.firstName(), faker.name.lastName(), ['TeamMember']];
    experts.push(utils.insertOne("INSERT INTO team_members (email, firstname, lastname, roles) VALUES ($1,$2,$3,$4)", vals));
  }


  var hr_users_group = utils.insertOne("INSERT INTO groups (name) VALUES ($1)", ['HR Users']);
  _.sampleSize(members, 50).forEach(function(user) {
    utils.insertOne("INSERT INTO group_members (group_id, user_id) VALUES ($1,$2)", [hr_users_group.id, user.id]);
  })

  var hr_experts_group = utils.insertOne("INSERT INTO groups (name) VALUES ($1)", ['HR Experts']);
  _.sampleSize(experts, 10).forEach(function(user) {
    utils.insertOne("INSERT INTO group_members (group_id, user_id) VALUES ($1,$2)", [hr_experts_group.id, user.id]);
  })

  var board_names = ["Manufacturing", "HQ", "Finance"];
  board_names.forEach(function(name) {
    utils.run("app_set_user_and_team($1,$2, false)", [owner.email, team.name]);

    var board = utils.insertOne("INSERT INTO boards (name, owned_by) VALUES ($1, $2)", [name, _.sample(experts).id]);

    var kards = [];
    for (var i = 0; i < MAX_KARDS; i++) {
      //-- Now, become a random expert
      utils.run("app_set_user_and_team($1,$2, false)", [_.sample(experts).email, team.name]);

      var tags = _.sampleSize([faker.company.bsNoun(), faker.company.bsNoun(), faker.hacker.noun(), faker.name.jobArea()], 4);
      var title = faker.random.words(6);
      //-- Simulate SlateJS content
      var content_json = Plain.deserialize(faker.lorem.paragraphs());
      var vals = [board.id, title, tags, content_json];
      var kard = utils.insertOne("INSERT INTO kards(board_id, title, tags, content_json) VALUES ($1, $2, $3, $4)", vals);
      kards.push(kard);
    }

    for (var i = 0; i < MAX_QUESTIONS; i++) {
      //-- Now, become a random member
      utils.run("app_set_user_and_team($1,$2, false)", [_.sample(members).email, team.name]);

      var title = _.sample(["How do I ", "Where is ", "Who knows "]) + faker.random.words(6);
      var vals;
      if (Math.random() > 0.7) {
        vals = [title, _.sample(experts).id, _.sample(kards).id];
      } else {
        vals = [title, _.sample(experts).id, null];
      }
      utils.insertOne("INSERT INTO questions(title, assigned_to_user_id, answered_with_kard_id) VALUES ($1, $2, $3)", vals);
    }

  })

$$;

CREATE OR REPLACE FUNCTION public.delete_sample_team(p_team_name text) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM public.teams WHERE name = p_team_name;
END
$$;

-- Some sample settings
INSERT INTO setting_defaults (name, value, description) VALUES ('auth.saml', '{"enabled": true}', 'desc');
INSERT INTO setting_defaults (name, value, description) VALUES ('logo', '"http://foo/img.png"', 'desc');
INSERT INTO setting_defaults (name, value, description) VALUES ('license_count', '45', 'desc');

-- To simulate running via postgREST, change to apiuser
SET ROLE apiuser;
select v8.plv8_require();
select public.delete_sample_team('Acme');
select public.create_sample_team('Acme', 'owner@acme.com', 1);


-- INSERT INTO settings (team_id, name, value) VALUES ((SELECT id FROM teams WHERE name = 'Acme'), 'license_count', '999');
-- INSERT INTO settings (team_id, name, value) VALUES ((SELECT id FROM teams WHERE name = 'BigCo'), 'license_count', '111'); */
