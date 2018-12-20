-- Tempus - PT delete Wrapper
-- Parameter %(source_name) : PT network name to delete

-- Predelete


-- Delete
DELETE FROM tempus_gtfs.feed_info
WHERE feed_id = '%(source_name)';

-- Postdelete



VACUUM FULL ANALYSE;


