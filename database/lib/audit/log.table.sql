CREATE TABLE audit.log (
    id BIGSERIAL PRIMARY KEY,
    schema_name TEXT NOT NULL,
    table_name TEXT NOT NULL,
    relid OID NOT NULL,
    action_tstamp_tx TIMESTAMP WITH TIME ZONE NOT NULL,
    action_tstamp_stm TIMESTAMP WITH TIME ZONE NOT NULL,
    action_tstamp_clk TIMESTAMP WITH TIME ZONE NOT NULL,
    transaction_id BIGINT NOT NULL,
    application_name TEXT,
    user_agent TEXT,
    tenant_id UUID,
    user_id UUID,
    client_addr INET,
    client_port INTEGER,
    action TEXT NOT NULL CHECK (action IN ('I','D','U', 'T')),
    statement_only BOOLEAN NOT NULL,
    row_data JSONB,
    changed_fields JSONB,
    client_query TEXT
);

CREATE INDEX log_relid_idx ON audit.log(relid);
CREATE INDEX log_action_tstamp_tx_stm_idx ON audit.log(action_tstamp_stm);
CREATE INDEX log_action_idx ON audit.log(action);
CREATE INDEX log_tenant_idx ON audit.log(tenant_id);

REVOKE ALL ON audit.log FROM public;

COMMENT ON TABLE audit.log
  IS 'History of auditable actions on audited tables';
COMMENT ON COLUMN audit.log.id
  IS 'Unique identifier for each auditable event';
COMMENT ON COLUMN audit.log.schema_name
  IS 'Database schema audited table for this event is in';
COMMENT ON COLUMN audit.log.table_name
  IS 'Non-schema-qualified table name of table event occured in';
COMMENT ON COLUMN audit.log.relid
  IS 'Table OID. Changes with drop/create. Get with ''tablename''::REGCLASS';
COMMENT ON COLUMN audit.log.action_tstamp_tx
  IS 'Transaction start timestamp for tx in which audited event occurred';
COMMENT ON COLUMN audit.log.action_tstamp_stm
  IS 'Statement start timestamp for tx in which audited event occurred';
COMMENT ON COLUMN audit.log.action_tstamp_clk
  IS 'Wall clock time at which audited event''s trigger call occurred';
COMMENT ON COLUMN audit.log.transaction_id
  IS 'Identifier of transaction that made the change. Unique when paired with action_tstamp_tx.';
COMMENT ON COLUMN audit.log.client_addr
  IS 'IP address of client that issued query. Null for unix domain socket.';
COMMENT ON COLUMN audit.log.client_port
  IS 'Port address of client that issued query. Undefined for unix socket.';
COMMENT ON COLUMN audit.log.client_query
  IS 'Top-level query that caused this auditable event. May be more than one.';
COMMENT ON COLUMN audit.log.application_name
  IS 'Client-set session application name when this audit event occurred.';
COMMENT ON COLUMN audit.log.user_agent
  IS 'Client-set user_agent when this audit event occurred.';
COMMENT ON COLUMN audit.log.tenant_id
  IS 'Client-set GUC for tenant id.';
COMMENT ON COLUMN audit.log.user_id
  IS 'Client-set GUC for user_id.';
COMMENT ON COLUMN audit.log.action
  IS 'Action type; I = insert, D = delete, U = update, T = truncate';
COMMENT ON COLUMN audit.log.row_data
  IS 'Record value. Null for statement-level trigger. For INSERT this is null. For DELETE and UPDATE it is the old tuple.';
COMMENT ON COLUMN audit.log.changed_fields
  IS 'New values of fields for INSERT or changed by UPDATE. Null for DELETE';
COMMENT ON COLUMN audit.log.statement_only
  IS '''t'' if audit event is from an FOR EACH STATEMENT trigger, ''f'' for FOR EACH ROW';
