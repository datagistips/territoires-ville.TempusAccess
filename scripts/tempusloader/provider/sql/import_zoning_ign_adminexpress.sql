
DELETE FROM zoning.zoning_source
WHERE name IN ('%(source_name)_commune', '%(source_name)_departement', '%(source_name)_region');

INSERT INTO zoning.zoning_source(name, comment)
VALUES('%(source_name)_commune', 'Communes (%(source_name))');
INSERT INTO zoning.zoning_source(name, comment)
VALUES('%(source_name)_departement', 'Départements (%(source_name))');
INSERT INTO zoning.zoning_source(name, comment)
VALUES('%(source_name)_region', 'Régions (%(source_name))'); 

DROP TABLE IF EXISTS zoning.%(source_name)_commune;
CREATE TABLE zoning.%(source_name)_commune 
AS
SELECT gid as id, insee_com as vendor_id, nom_com as lib, st_transform(st_multi(st_force2d(geom)), 4326)::Geometry(MultiPolygon, 4326) as geom, population
FROM %(temp_schema).commune
ORDER BY insee_com; 

CREATE INDEX %(source_name)_commune_lib_idx ON zoning.%(source_name)_commune USING gist (lib gist_trgm_ops);
CREATE INDEX %(source_name)_commune_vendor_id_idx ON zoning.%(source_name)_commune USING btree (vendor_id);
CREATE INDEX %(source_name)_commune_geom_idx ON zoning.%(source_name)_commune USING gist(geom);

DROP TABLE IF EXISTS zoning.%(source_name)_departement;
CREATE TABLE zoning.%(source_name)_departement 
AS
SELECT gid as id, insee_dep as vendor_id, nom_dep as lib, st_transform(st_multi(st_force2d(geom)), 4326)::Geometry(MultiPolygon, 4326) as geom
FROM %(temp_schema).departement
ORDER BY insee_dep; 

CREATE INDEX %(source_name)_departement_lib_idx ON zoning.%(source_name)_departement USING gist (lib gist_trgm_ops);
CREATE INDEX %(source_name)_departement_vendor_id_idx ON zoning.%(source_name)_departement USING btree (vendor_id);
CREATE INDEX %(source_name)_departement_geom_idx ON zoning.%(source_name)_departement USING gist(geom);

DROP TABLE IF EXISTS zoning.%(source_name)_region;
CREATE TABLE zoning.%(source_name)_region 
AS
SELECT gid as id, insee_reg as vendor_id, nom_reg as lib, st_transform(st_multi(st_force2d(geom)), 4326)::Geometry(MultiPolygon, 4326) as geom
FROM %(temp_schema).region
ORDER BY insee_reg; 

CREATE INDEX %(source_name)_region_lib_idx ON zoning.%(source_name)_region USING gist (lib gist_trgm_ops);
CREATE INDEX %(source_name)_region_vendor_id_idx ON zoning.%(source_name)_region USING btree (vendor_id);
CREATE INDEX %(source_name)_region_geom_idx ON zoning.%(source_name)_region USING gist(geom);

DROP SCHEMA %(temp_schema) CASCADE;
