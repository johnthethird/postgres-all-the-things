CREATE OR REPLACE FUNCTION set_updated_at() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
  -- Allow for manual changes to updated_at
  IF (NEW.updated_at = OLD.updated_at) THEN
    NEW.updated_at = timezone('utc', now())::timestamptz;
  END IF;
  RETURN NEW;
END;
$$;
