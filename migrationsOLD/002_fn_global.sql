-- rambler up

CREATE OR REPLACE FUNCTION set_updated_at() RETURNS TRIGGER AS $$
  BEGIN
    -- Allow for manual changes to updated_at
    IF (NEW.updated_at = OLD.updated_at) THEN
      NEW.updated_at = timezone('utc', now())::timestamptz;
    END IF;
    RETURN NEW;
  END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION set_created_by() RETURNS TRIGGER AS $$
  DECLARE uid UUID;
  BEGIN
    SELECT app_user_id() INTO uid;
    NEW.created_by = uid;
    RETURN NEW;
  END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION create_row_trigger(p_name text, p_when text, p_table text) RETURNS VOID AS $$
  DECLARE v_table text;
  BEGIN
    EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I', p_name, p_table);
    EXECUTE format('CREATE TRIGGER %I %s ON %I FOR EACH ROW EXECUTE PROCEDURE %s()', p_name, p_when, p_table, p_name);
  END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION create_rls_policy(p_table text) RETURNS VOID AS $$
  BEGIN
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', p_table);
    EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', p_table);
    EXECUTE format('DROP POLICY IF EXISTS tenant_access ON %I', p_table);
    EXECUTE format('CREATE POLICY tenant_access ON %I FOR ALL TO apiuser USING (tenant_id = app_tenant_id())', p_table);
  END;
$$ LANGUAGE plpgsql;
