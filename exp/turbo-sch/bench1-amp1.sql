\echo '====  Execution Context  ===='
\echo `date`
-- Tell the backend to what constraint exclusion GUC setting 
-- it should be using (for this psql session)
-- set constraint_exclusion = partition;
-- set constraint_exclusion = on;
\echo
\conninfo
\echo
\l+
\echo '====  psql Configuration  ===='
\set ECHO queries
\echo
\echo '====  Benchmark Cases for Data Set Details  ===='
\d+ timeseries
\echo
\echo 'Record Count for timeseries
select count(*) from timeseries;
\d+ timeseries_default_slow
\echo
\echo 'Record Count for timeseries_default_slow'
select count(*) from timeseries_default_slow;
\echo
\echo '>>>>  Detail Benchmark Case 1:  Range scan for 5 days  <<<<'
\echo
EXPLAIN 
SELECT   min(value), avg(value), max(value) 
FROM     timeseries 
WHERE    stamp >= '2015-01-05 00:00:00-08'
AND      stamp <  '2015-01-11 00:00:00-08';

SELECT   min(value), avg(value), max(value) 
FROM     timeseries 
WHERE    stamp >= '2015-01-05 00:00:00-08'
AND      stamp <  '2015-01-11 00:00:00-08';
\echo
\echo 'Done for case 1 on timeseries'
\echo
EXPLAIN 
SELECT   min(value), avg(value), max(value) 
FROM     timeseries_default_slow 
WHERE    stamp >= '2015-01-05 00:00:00-08'
AND      stamp <  '2015-01-11 00:00:00-08';

SELECT   min(value), avg(value), max(value) 
FROM     timeseries_default_slow 
WHERE    stamp >= '2015-01-05 00:00:00-08'
AND      stamp <  '2015-01-11 00:00:00-08';
\echo 'Done for detail benchmark case 1 on timeseries_default_slow'
\echo
\echo '>>>>  Detail benchmark case 2:  Range scan for 5 days by key  <<<<'
\echo
EXPLAIN 
SELECT   stamp, value 
FROM     timeseries 
WHERE    account_id = 0
AND      object_id  = 0
AND      metric_id  = 0
AND      label_id   = 0
AND      stamp >= '2015-01-05 00:00:00-08'
AND      stamp <  '2015-01-11 00:00:00-08';

SELECT   stamp, value 
FROM     timeseries 
WHERE    account_id = 0
AND      object_id  = 0
AND      metric_id  = 0
AND      label_id   = 0
AND      stamp >= '2015-01-05 00:00:00-08'
AND      stamp <  '2015-01-11 00:00:00-08';
\echo 'Done for case 2 on timeseries'
\echo
EXPLAIN 
SELECT   stamp, value 
FROM     timeseries_default_slow 
WHERE    account_id = 0
AND      object_id  = 0
AND      metric_id  = 0
AND      label_id   = 0
AND      stamp >= '2015-01-05 00:00:00-08'
AND      stamp <  '2015-01-11 00:00:00-08';

SELECT   stamp, value 
FROM     timeseries_default_slow 
WHERE    account_id = 0
AND      object_id  = 0
AND      metric_id  = 0
AND      label_id   = 0
AND      stamp >= '2015-01-05 00:00:00-08'
AND      stamp <  '2015-01-11 00:00:00-08';
\echo 'Done for case 2 on timeseries_default_slow'
\echo
-- The following queries managed to disable constraint exclusion 
-- in some early testing.  They are left here as a reminder to NOT 
-- assume that appropriate constraint exlucsion will occur 
-- (via the PG Query Planner) in all of the cases one might 
-- expect it to occur in.  
--
-- EXPLAIN SELECT * FROM timeseries 
-- WHERE stamp >= TO_TIMESTAMP('2015-5', 'YYYY-DDD')::timestamp 
-- AND   stamp <  TO_TIMESTAMP('2015-11', 'YYYY-DDD')::timestamp; 

-- SELECT * FROM timeseries 
-- WHERE stamp >= to_timestamp(FORMAT('2015-%s', 5), 'YYYY-DDD') 
-- AND   stamp <  to_timestamp(FORMAT('2015-%s', 11), 'YYYY-DDD');
\echo
\echo '====  End of Benchmark Cases for Data Set Details  ===='
\echo
\echo '====  Start Benchmark Cases for (Pre-)Summarized Data ===='
\echo
\d+ timeseries_by_4_hours
\echo
\echo 'Record Count for timeseries_by_4_hours'
select count(*) from timeseries_by_4_hours;
\echo
\echo '>>>>  Summary benchmark case 1:  Range scan for 5 days  <<<<'
\echo
\echo 'Here, we are just suppressing output by approximating an '
\echo 'average as an average of pre-summarized sub-range (summary) '
\echo 'averages.  The actual result is just a means to a timing end.'
\echo
EXPLAIN 
SELECT   min(min_value), avg(mean_value), max(max_value) 
FROM     timeseries_by_4_hours 
WHERE    mid_stamp >= '2015-01-05 00:00:00-08'
AND      mid_stamp <  '2015-01-11 00:00:00-08';
\echo
SELECT   min(min_value), avg(mean_value), max(max_value) 
FROM     timeseries_by_4_hours 
WHERE    mid_stamp >= '2015-01-05 00:00:00-08'
AND      mid_stamp <  '2015-01-11 00:00:00-08';
\echo
\echo 'Done for summary benchmark case 1 on timeseries_by_4_hours'
\echo
\echo '>>>>  Summary Benchmark Case 2:  Range scan for 5 days by key  <<<<'
\echo
EXPLAIN 
SELECT   mid_stamp, min_value, mean_value, max_value 
FROM     timeseries_by_4_hours
WHERE    account_id = 0
AND      object_id  = 0
AND      metric_id  = 0
AND      label_id   = 0
AND      mid_stamp >= '2015-01-05 00:00:00-08'
AND      mid_stamp <  '2015-01-11 00:00:00-08';
\echo
SELECT mid_stamp, min_value, mean_value, max_value 
FROM   timeseries_by_4_hours
WHERE  account_id = 0
AND    object_id  = 0
AND    metric_id  = 0
AND    label_id   = 0
AND    mid_stamp >= '2015-01-05 00:00:00-08'
AND    mid_stamp <  '2015-01-11 00:00:00-08';
\echo
\echo 'Done for summary benchmark case 2 on timeseries_by_4_hours'
\echo
\echo
\echo '====  End of Summary Benchmark Cases on timeseries-by-4-hour  ===='
\echo '====  End of All Benchmark Cases  ===='

