do $$
begin
raise notice '==== Reset stops transfers import table ===';
end$$;

DROP TABLE IF EXISTS %(temp_schema).stops_transfers;
CREATE TABLE IF NOT EXISTS %(temp_schema).stops_transfers
(
  feed_id character varying,
  stop_id character varying,
  parent_stop_id character varying
);



