INSERT INTO tempus_access.formats
SELECT * FROM _tempus_import.formats;

INSERT INTO tempus_access.agregates
SELECT * FROM _tempus_import.agregates;

INSERT INTO tempus_access.modalities
SELECT * FROM _tempus_import.modalities;

INSERT INTO tempus_access.obj_type
SELECT * FROM _tempus_import.obj_type;

INSERT INTO tempus_access.indicators
SELECT * FROM _tempus_import.indicators;

INSERT INTO tempus.holidays
SELECT * FROM _tempus_import.holidays;

DROP SCHEMA IF EXISTS _tempus_import CASCADE;
