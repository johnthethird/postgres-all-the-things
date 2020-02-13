CREATE OR REPLACE FUNCTION set_tenant_id() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
  tenant_id UUID;
BEGIN
  -- Allow setting manually for convience, RLS will make sure its correct for API users
  SELECT COALESCE(NEW.tenant_id, app.tenant_id()) INTO tenant_id;
  NEW.tenant_id = tenant_id;
  RETURN NEW;
END
$$;
