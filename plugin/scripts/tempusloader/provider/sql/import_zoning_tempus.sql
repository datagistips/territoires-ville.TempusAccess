
DELETE FROM zoning.zoning_source
WHERE name = '%(source_name)';

INSERT INTO zoning.zoning_source(name, comment)
VALUES('%(source_name)', '%(source_comment)'); 

DROP TABLE IF EXISTS zoning.%(source_name);
CREATE TABLE zoning.%(source_name)
AS
SELECT *
FROM _tempus_import.zoning
ORDER BY gid; 

ALTER TABLE zoning.%(source_name)
RENAME COLUMN %(id_field) TO vendor_id;

ALTER TABLE zoning.%(source_name)
RENAME COLUMN gid TO id;

ALTER TABLE zoning.%(source_name)
RENAME COLUMN %(name_field) TO lib;

ALTER TABLE zoning.%(source_name)
ALTER COLUMN geom TYPE Geometry(MultiPolygon, 4326) USING st_transform(st_multi(geom), 4326) ;

ALTER TABLE zoning.%(source_name)
ALTER COLUMN vendor_id TYPE character varying USING vendor_id::character varying;

CREATE INDEX %(source_name)_lib_idx ON zoning.%(source_name) USING gist (lib gist_trgm_ops);
CREATE INDEX %(source_name)_vendor_id_idx ON zoning.%(source_name) USING btree (vendor_id);
CREATE INDEX %(source_name)_geom_idx ON zoning.%(source_name) USING gist(geom);

DROP SCHEMA _tempus_import CASCADE;

