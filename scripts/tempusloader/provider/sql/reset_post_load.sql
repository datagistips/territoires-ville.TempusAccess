INSERT INTO tempus_access.formats
SELECT * FROM %(temp_schema).formats;

INSERT INTO tempus_access.agregates
SELECT * FROM %(temp_schema).agregates;

INSERT INTO tempus_access.modalities
SELECT * FROM %(temp_schema).modalities;

INSERT INTO tempus_access.obj_type
SELECT * FROM %(temp_schema).obj_type;

INSERT INTO tempus_access.indicators
SELECT * FROM %(temp_schema).indicators;

INSERT INTO tempus.holidays
SELECT * FROM %(temp_schema).holidays;

DROP SCHEMA IF EXISTS %(temp_schema) CASCADE;
