--  summarize_timeseries
--
--  ====  USAGE (via bash shell CLI)
--
--    psql -d amp1 -U gshulegaard -w -f summarize-amp1.sql 
--
--      *  -w implies you use a ~/.pgpass file.  For security 
--         reasons, always avoid putting DB passwords on any 
--         command line (... for psql or any other command). 
--
--  ====  LIMITATIONS
--
--  ====  DESIGN
--
-- 20151030 GSH  To ensure that the data records are inserted in something 
--               akin to the chronological order that they (in practice and 
--               ordinarily) would appear (in a production environment), the 
--               'insert select INTO timeseries_by_4_hours' SQL statemnet 
--               (below) will use an ORDER BY clause.
--
--  ====  FUTURE DIRECTIONS
--
--
--
-- Clean up any pre-existing data.  Path of least astonishment (POLA) when re-running 
-- this script.
TRUNCATE timeseries_by_4_hours;

INSERT INTO timeseries_by_4_hours 
(account_id,
 object_id,
 metric_id,
 label_id,
 mid_stamp,
 min_value,
 mean_value,
 max_value,
 stddev_samp_value,
 unique_value_count,
 mode_value,
 percentile_98_cont_value,
 percentile_91_cont_value,
 percentile_90_cont_value,
 percentile_75_cont_value,
 precentile_50_disc_value,
 precentile_50_cont_value,
 percentile_25_cont_value,
 percentile_10_cont_value,
 percentile_9_cont_value,
 percentile_2_cont_value ) 
SELECT account_id, object_id, metric_id, label_id, 
       DATE_TRUNC('day', stamp) + ((((EXTRACT(HOUR FROM stamp)::INTEGER / 4) * 4) + 2) * INTERVAL '1 hour') AS mid_stamp,
       MIN(value) AS min_value,
       AVG(value) AS mean_value,
       MAX(value) AS max_value,
       STDDEV_SAMP(value) AS stddev_samp_value,
       COUNT(DISTINCT value) AS unique_value_count,
       MODE() WITHIN GROUP (ORDER BY value) AS mode_value,
       percentile_cont(0.98) WITHIN GROUP (ORDER BY value) AS percentile_98_cont_value,
       percentile_cont(0.91) WITHIN GROUP (ORDER BY value) AS percentile_91_cont_value,
       percentile_cont(0.90) WITHIN GROUP (ORDER BY value) AS percentile_90_cont_value,
       percentile_cont(0.75) WITHIN GROUP (ORDER BY value) AS percentile_75_cont_value,
       percentile_disc(0.50) WITHIN GROUP (ORDER BY value) AS percentile_50_disc_value,
       percentile_cont(0.50) WITHIN GROUP (ORDER BY value) AS percentile_50_cont_value,
       percentile_cont(0.25) WITHIN GROUP (ORDER BY value) AS percentile_25_cont_value,
       percentile_cont(0.10) WITHIN GROUP (ORDER BY value) AS percentile_10_cont_value,
       percentile_cont(0.09) WITHIN GROUP (ORDER BY value) AS percentile_9_cont_value,
       percentile_cont(0.02) WITHIN GROUP (ORDER BY value) AS percentile_2_cont_value
FROM timeseries
GROUP BY account_id, object_id, metric_id, label_id, 
         DATE_TRUNC('day', stamp),
         EXTRACT(HOUR FROM stamp)::INTEGER / 4  
ORDER BY account_id, object_id, metric_id, label_id, 
         DATE_TRUNC('day', stamp),
         EXTRACT(HOUR FROM stamp)::INTEGER / 4;

SELECT COUNT(*) AS TS_by_4_hours_count FROM timeseries_by_4_hours;

SELECT account_id AS aid, object_id AS oid, metric_id AS mid, label_id AS lid, count(*) AS count 
FROM timeseries_by_4_hours
GROUP BY aid, oid, mid, lid
ORDER BY aid, oid, mid, lid;

SELECT *
FROM timeseries_by_4_hours
WHERE account_id = 0
AND   object_id  = 0 
AND   metric_id  = 0
AND   label_id   = 0
AND   EXTRACT(DOY FROM mid_stamp) = 1 
ORDER BY mid_stamp ASC;
