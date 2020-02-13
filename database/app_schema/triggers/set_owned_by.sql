CREATE OR REPLACE FUNCTION set_owned_by() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
  uid UUID;
BEGIN
    SELECT COALESCE(NEW.owned_by, app.user_id()) INTO uid;
    NEW.owned_by = uid;
    RETURN NEW;
END;
$$;
