CREATE OR REPLACE FUNCTION create_row_trigger(p_name text, p_when text, p_tables text[]) RETURNS VOID AS $$
  DECLARE v_table text;
  BEGIN
    FOREACH v_table IN ARRAY p_tables LOOP
      EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I', p_name, v_table);
      EXECUTE format('CREATE TRIGGER %I %s ON %I FOR EACH ROW EXECUTE PROCEDURE app.%s()', p_name, p_when, v_table, p_name);
    END LOOP;
  END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION create_row_trigger(p_name text, p_when text, p_table text) RETURNS VOID AS $$
  DECLARE v_table text;
  BEGIN
    EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I', p_name, p_table);
    EXECUTE format('CREATE TRIGGER %I %s ON %I FOR EACH ROW EXECUTE PROCEDURE app.%s()', p_name, p_when, p_table, p_name);
  END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION create_view_trigger(p_view text, p_when text) RETURNS VOID AS $$
  BEGIN
    -- For triggers we can revoke exec privs, and then the func doesnt show up in swagger docs. Yay!
    EXECUTE format('REVOKE EXECUTE ON FUNCTION %s_%s() FROM PUBLIC', p_view, p_when);
    EXECUTE format('CREATE TRIGGER %s_%s INSTEAD OF %s ON %s FOR EACH ROW EXECUTE PROCEDURE %s_%s()', p_view, p_when, p_when, p_view, p_view, p_when);
  END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION create_row_trigger_for_column(p_name text, p_when text, p_column text) RETURNS VOID AS $$
  DECLARE v_tables text[];
  BEGIN
    SELECT array_agg(table_name::text) INTO v_tables
    FROM information_schema.columns WHERE table_schema='public' AND column_name = p_column;

    PERFORM create_row_trigger(p_name, p_when, v_tables);
  END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION create_row_trigger_for_column(p_name text, p_when text, p_column text) IS $$
  Create a trigger on every table in public schema with a column names p_column
$$;

CREATE OR REPLACE FUNCTION create_rls_policy(p_table REGCLASS) RETURNS VOID AS $$
  BEGIN
    EXECUTE 'ALTER TABLE ' || p_table::text || ' ENABLE ROW LEVEL SECURITY';
    EXECUTE 'ALTER TABLE ' || p_table::text || ' FORCE ROW LEVEL SECURITY';
    EXECUTE 'DROP POLICY IF EXISTS tenant_access ON ' || p_table::text;
    EXECUTE 'CREATE POLICY tenant_access ON ' || p_table::text || ' FOR ALL TO apiuser USING (tenant_id = app.tenant_id())';
  END;
$$ LANGUAGE plpgsql;
