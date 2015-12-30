-- Create Summarization Objects
--   For the sake of illustration and benchmarking, create summarization 
--   tables at the 4-hour (time interval) level of summarization.  When 
--   displaying a week's worth of historical data (on the web-based dashboard), 
--   it appears as if each data point represents a 4 hour interval.
--
DROP TABLE IF EXISTS timeseries_by_4_hours;

CREATE TABLE IF NOT EXISTS timeseries_by_4_hours (
  account_id INTEGER NOT NULL,
  object_id INTEGER NOT NULL,
  metric_id INTEGER NOT NULL,
  label_id INTEGER NOT NULL,
--  By convention, the mid_stamp (timestamp) will represent 
--  the timestamp value in the 'middle' of a four hour 
--  interval.  This center-of-interval mid_stamp value 
--  should be good 'as-stored' for most display/UI/UX purposes.
--  For other purposes, subtract two hours from the stored 
--  mid-stamp to compute a start_stamp (timestamp) for the 
--  (inclusive) beginning of the given summary record's time 
--  interval.  Likewise, add two hours to compute the end_stamp 
--  to compute the end_stamp (timestamp) for the (eclusive) end of 
--  the given summary record's time interval.
--  Warning:  Do NOT use the timestampz type.  Store all timestamp type values 
--            as (implicitly) UTC.  Do NOT risk daylight savings time hassles.  
--            Do NOT risk non-sargable timestamp values.  See
--            https://en.wikipedia.org/wiki/Sargable
--  mid_stamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
  mid_stamp TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
--  Summary values describing the time interval's 
--  source (raw, timeseries) values
  min_value DOUBLE PRECISION NOT NULL,
  mean_value DOUBLE PRECISION NOT NULL,
  max_value DOUBLE PRECISION NOT NULL,
  stddev_samp_value DOUBLE PRECISION NOT NULL,
--  ordered set aggregates (available in postgres v9.4+)
  unique_value_count INTEGER NOT NULL,
--  mode is most frequently appearing value.  This is rarely used
  mode_value DOUBLE PRECISION NOT NULL,
--  box-and-whisker plot percentile (continuous) values.
--  See https://en.wikipedia.org/wiki/Box_plot
--  See https://en.wikipedia.org/wiki/Seven-number_summary
--  cover both parametric and non-parametric summaries
  percentile_98_cont_value DOUBLE PRECISION NOT NULL,
  percentile_91_cont_value DOUBLE PRECISION NOT NULL,
  percentile_90_cont_value DOUBLE PRECISION NOT NULL,
  percentile_75_cont_value DOUBLE PRECISION NOT NULL,
--  By definition, the median value is percentile_disc(0.5) 
--  and herein recorded as 50_percentile_disc_value 
  precentile_50_disc_value DOUBLE PRECISION NOT NULL,
  precentile_50_cont_value DOUBLE PRECISION NOT NULL,
  percentile_25_cont_value DOUBLE PRECISION NOT NULL,
  percentile_10_cont_value DOUBLE PRECISION NOT NULL,
  percentile_9_cont_value  DOUBLE PRECISION NOT NULL,
  percentile_2_cont_value  DOUBLE PRECISION NOT NULL,
--  The dirty flag is a future direction (FD).  
--  the dirty flag should be set (by a trigger on 
--  the timeseries table) whenever an update or insert 
--  modifies the raw timeseries (ordered) input set 
--  corresponding to a corresponding timeseries_by-4_hours 
--  summary record.  Since prior (4 hour summary) interval 
--  inserts and/or updates on the timeseries tables should 
--  become very infrequent (esp. as time goes on), very 
--  few of the  summary records here will ever be flagged
--  as 'dirty'.  Periodically, dirty summary records should 
--  be replaced/updated (to reflect changes in the source 
--  timeseries table).  At the same time, any missing (or 
--  newly available) summary records should be inserted into 
--  this timeseries_by_4_hours (pre-computed) summary table.    
  dirty BOOLEAN NOT NULL DEFAULT 'False',
--  Outliers are a future direction (FD).
--  See https://en.wikipedia.org/wiki/Outlier
--  Outliers may be detected by many methods 
--  (e.g. Bollinger bands, see 
--  https://en.wikipedia.org/wiki/Bollinger_Bands)
  outlier_values DOUBLE PRECISION[]
);

CREATE UNIQUE INDEX timeseries_by_4_hours_udx ON timeseries_by_4_hours USING BTREE (account_id, object_id, metric_id, label_id, mid_stamp);
CREATE INDEX timeseries_by_4_hours_mid_stamp_idx ON timeseries_by_4_hours USING BTREE (mid_stamp);
CLUSTER timeseries_by_4_hours USING timeseries_by_4_hours_udx;

\d+ timeseries_by_4_hours

select count(*) AS TS_by_4_count FROM timeseries_by_4_hours;
