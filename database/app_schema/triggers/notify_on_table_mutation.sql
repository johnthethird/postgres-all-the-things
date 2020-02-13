CREATE OR REPLACE FUNCTION notify_on_table_mutation() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE v_id UUID;
BEGIN
  IF TG_OP = 'DELETE' THEN v_id = OLD.id; ELSE v_id = NEW.id; END IF;

  -- NOTIFY table change
  PERFORM pg_notify(TG_TABLE_NAME, jsonb_build_object('id', v_id, 'op', TG_OP, 'table', TG_TABLE_NAME)::text);

  RETURN NULL;
END;
$$;
