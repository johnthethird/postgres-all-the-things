---
--- Enables tracking on a table by generating and attaching a trigger
---
CREATE OR REPLACE FUNCTION audit.audit_table(
  target_table REGCLASS,
  audit_rows BOOLEAN,
  audit_query_text BOOLEAN,
  ignored_cols TEXT[]
)
RETURNS VOID
LANGUAGE 'plpgsql'
AS $$
DECLARE
  stm_targets TEXT = 'INSERT OR UPDATE OR DELETE OR TRUNCATE';
  _q_txt TEXT;
  _ignored_cols_snip TEXT = '';
BEGIN
  EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_row ON ' || target_table::TEXT;
  EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_stm ON ' || target_table::TEXT;

  IF audit_rows THEN
    IF array_length(ignored_cols,1) > 0 THEN
        _ignored_cols_snip = ', ' || quote_literal(ignored_cols);
    END IF;
    _q_txt = 'CREATE TRIGGER audit_trigger_row '
             'AFTER INSERT OR UPDATE OR DELETE ON ' ||
             target_table::TEXT ||
             ' FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func(' ||
             quote_literal(audit_query_text) ||
             _ignored_cols_snip ||
             ');';
    RAISE NOTICE '%', _q_txt;
    EXECUTE _q_txt;
    stm_targets = 'TRUNCATE';
  END IF;

  _q_txt = 'CREATE TRIGGER audit_trigger_stm AFTER ' || stm_targets || ' ON ' ||
           target_table ||
           ' FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('||
           quote_literal(audit_query_text) || ');';
  RAISE NOTICE '%', _q_txt;
  EXECUTE _q_txt;
END;
$$;

COMMENT ON FUNCTION audit.audit_table(REGCLASS, BOOLEAN, BOOLEAN, TEXT[]) IS $$
Add auditing support to a table.

Arguments:
   target_table:     Table name, schema qualified if not on search_path
   audit_rows:       Record each row change, or only audit at a statement level
   audit_query_text: Record the text of the client query that triggered
                     the audit event?
   ignored_cols:     Columns to exclude from update diffs,
                     ignore updates that change only ignored cols.
$$;

--
-- Pg doesn't allow variadic calls with 0 params, so provide a wrapper
--
CREATE OR REPLACE FUNCTION audit.audit_table(
  target_table REGCLASS,
  audit_rows BOOLEAN,
  audit_query_text BOOLEAN
)
RETURNS VOID
LANGUAGE SQL
AS $$
  SELECT audit.audit_table($1, $2, $3, ARRAY[]::TEXT[]);
$$;

--
-- And provide a convenience call wrapper for the simplest case
-- of row-level logging with no excluded cols and query logging enabled.
--
CREATE OR REPLACE FUNCTION audit.audit_table(target_table REGCLASS)
RETURNS VOID
LANGUAGE 'sql'
AS $$
  SELECT audit.audit_table($1, BOOLEAN 't', BOOLEAN 't');
$$;

COMMENT ON FUNCTION audit.audit_table(REGCLASS) IS $$
Add auditing support to the given table. Row-level changes will be logged with
full client query text. No cols are ignored.
$$;
