CREATE OR REPLACE FUNCTION audit.if_modified_func()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    audit_row audit.log;
    include_values BOOLEAN;
    log_diffs BOOLEAN;
    h_old JSONB;
    h_new JSONB;
    excluded_cols TEXT[] = ARRAY[]::TEXT[];
BEGIN
  IF TG_WHEN <> 'AFTER' THEN
    RAISE EXCEPTION 'audit.if_modified_func() may only run as an AFTER trigger';
  END IF;

  audit_row = ROW(
    nextval('audit.log_id_seq'),                    -- id
    TG_TABLE_SCHEMA::TEXT,                          -- schema_name
    TG_TABLE_NAME::TEXT,                            -- table_name
    TG_RELID,                                       -- relation OID for faster searches
    current_timestamp,                              -- action_tstamp_tx
    statement_timestamp(),                          -- action_tstamp_stm
    clock_timestamp(),                              -- action_tstamp_clk
    txid_current(),                                 -- transaction ID
    current_setting('application_name', true),      -- client application
    current_setting('request.header.user-agent', true),
    current_setting('app.tenant_id', true),           -- client application
    current_setting('app.user_id', true),           -- client user ID
    inet_client_addr(),                             -- client_addr
    inet_client_port(),                             -- client_port
    substring(TG_OP, 1, 1),                         -- action
    'f',                                            -- statement_only
    NULL,                                           -- row_data
    NULL,                                           -- changed_fields
    current_query()                                 -- top-level query or queries
    );

  IF NOT TG_ARGV[0]::BOOLEAN IS DISTINCT FROM 'f'::BOOLEAN THEN
    audit_row.client_query = NULL;
  END IF;

  IF TG_ARGV[1] IS NOT NULL THEN
    excluded_cols = TG_ARGV[1]::TEXT[];
  END IF;

  IF (TG_OP = 'INSERT' AND TG_LEVEL = 'ROW') THEN
    audit_row.changed_fields = to_jsonb(NEW.*) - excluded_cols;
  ELSIF (TG_OP = 'UPDATE' AND TG_LEVEL = 'ROW') THEN
    audit_row.row_data = to_jsonb(OLD.*) - excluded_cols;
    audit_row.changed_fields =
      (to_jsonb(NEW.*) - audit_row.row_data) - excluded_cols;
    IF audit_row.changed_fields = '{}'::JSONB THEN
      -- All changed fields are ignored. Skip this update.
      RETURN NULL;
    END IF;
  ELSIF (TG_OP = 'DELETE' AND TG_LEVEL = 'ROW') THEN
    audit_row.row_data = to_jsonb(OLD.*) - excluded_cols;
  ELSIF (TG_LEVEL = 'STATEMENT' AND
         TG_OP IN ('INSERT','UPDATE','DELETE','TRUNCATE')) THEN
    audit_row.statement_only = 't';
  ELSE
    RAISE EXCEPTION '[audit.if_modified_func] - Trigger func added as trigger '
                    'for unhandled case: %, %', TG_OP, TG_LEVEL;
    RETURN NULL;
  END IF;
  INSERT INTO audit.log VALUES (audit_row.*);
  RETURN NULL;
END;
$$;


COMMENT ON FUNCTION audit.if_modified_func() IS $$
Track changes to a table at the statement and/or row level.

Optional parameters to trigger in CREATE TRIGGER call:

param 0: BOOLEAN, whether to log the query text. Default 't'.

param 1: TEXT[], columns to ignore in updates. Default [].

         Updates to ignored cols are omitted from changed_fields.

         Updates with only ignored cols changed are not inserted
         into the audit log.

         Almost all the processing work is still done for updates
         that ignored. If you need to save the load, you need to use
         WHEN clause on the trigger instead.

         No warning or error is issued if ignored_cols contains columns
         that do not exist in the target table. This lets you specify
         a standard set of ignored columns.

There is no parameter to disable logging of values. Add this trigger as
a 'FOR EACH STATEMENT' rather than 'FOR EACH ROW' trigger if you do not
want to log row values.

Note that the user name logged is the login role for the session. The audit
trigger cannot obtain the active role because it is reset by
the SECURITY DEFINER invocation of the audit trigger its self.
$$;
