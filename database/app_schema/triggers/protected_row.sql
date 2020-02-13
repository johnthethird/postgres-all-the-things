-- If a table has a row called 'protected' and its true, dont allow changes (except to switch it to false)
CREATE OR REPLACE FUNCTION protected_row() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
-- TG_ARGV[0] = parent table name (teams)
-- TG_ARGV[1] = parent table fk name (team_id)
  v_count INT;
BEGIN
  -- Allow for updating the protected flag to false, then you could delete
  IF TG_OP = 'UPDATE' AND OLD.protected = TRUE AND NEW.protected = FALSE THEN
    RETURN NULL;
  END IF;

  -- Only prevent direct deletes, if we are deleting from a cascade, go ahead and allow it.
  IF OLD.protected THEN
    EXECUTE format('SELECT COUNT(*) FROM %I t WHERE  t.id = $1.%I', TG_ARGV[0], TG_ARGV[1])
    USING OLD
    INTO v_count;
    IF v_count > 0 THEN
      RAISE EXCEPTION 'Updates/Deletes are not allowed on this protected record';
    END IF;
  END IF;

  RETURN NULL;
END;
$$;
