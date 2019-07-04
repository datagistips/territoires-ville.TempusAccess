do $$
begin
raise notice '==== Reset import schema ===';
end$$;

/* Drop import schema and recreate it */
DROP SCHEMA IF EXISTS _tempus_import CASCADE;
CREATE SCHEMA _tempus_import;
