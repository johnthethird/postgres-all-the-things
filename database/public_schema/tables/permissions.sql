CREATE TABLE permissions (
  name CITEXT CHECK(name !~* '\W' AND length(name) < 255) NOT NULL,
  scope permissions_scope_enum NOT NULL,
  allowed_roles role_enum[] DEFAULT '{}',
  denied_roles role_enum[] DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now())::timestamptz,
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now())::timestamptz,
  id UUID PRIMARY KEY DEFAULT uuid_generate_v1(),
  UNIQUE(name, scope)
);

SELECT app.create_row_trigger('set_updated_at', 'before update', 'permissions');
