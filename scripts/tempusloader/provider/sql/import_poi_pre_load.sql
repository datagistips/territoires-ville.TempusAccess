do $$
begin
raise notice '==== Reset import schema ===';
end$$;

/* Drop import schema and recreate it */
DROP SCHEMA IF EXISTS %(temp_schema) CASCADE;
CREATE SCHEMA %(temp_schema);
