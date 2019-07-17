-- Tempus - Zoning delete Wrapper
-- Parameter %(source_name) : zoning source name to delete

-- Delete
do 
$$
begin
    raise notice '==== Delete zoning ===';
end
$$;

DROP TABLE IF EXISTS zoning.%(source_name);

DELETE FROM zoning.zoning_source
WHERE name = '%(source_name)'; 
