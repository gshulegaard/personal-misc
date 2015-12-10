-- Create Raw Data Objets
--   DB objects for reading records, events, sensor reports, etc.
--
-- Name: timeseries_insert_trigger(); Type: FUNCTION; Schema: public; Owner: naas
--

CREATE OR REPLACE FUNCTION timeseries_insert_trigger()
RETURNS TRIGGER AS $$
DECLARE
  tname TEXT;
  day_of_year INTEGER;
  ins_statement TEXT;
BEGIN
  SELECT EXTRACT(DOY FROM NEW.stamp) INTO STRICT day_of_year;
  SELECT 'timeseries_default_by_day_' || ltrim(to_char(day_of_year, '999')) INTO STRICT tname;
  EXECUTE FORMAT('INSERT INTO %I (account_id, object_id, metric_id, label_id, stamp, value) VALUES (%L, %L, %L, %L, %L, %L)', tname, NEW.account_id, NEW.label_id, NEW.metric_id, NEW.object_id, NEW.stamp, NEW.value);
  RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS timeseries (
  account_id INTEGER NOT NULL,
  object_id INTEGER NOT NULL,
  metric_id INTEGER NOT NULL,
  label_id INTEGER NOT NULL,
--  Warning:  Do NOT use the timestampz type.  Store all timestamp type values 
--            as (implicitly) UTC.  Do NOT risk daylight savings time hassles.  
--            Do NOT risk non-sargable timestamp values.  See
--            https://en.wikipedia.org/wiki/Sargable
--  stamp TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
  stamp TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
  value DOUBLE PRECISION NOT NULL
);
CREATE TRIGGER insert_timeseries_trigger BEFORE INSERT ON timeseries FOR EACH ROW EXECUTE PROCEDURE timeseries_insert_trigger();

--
-- Loop to create partition tables for each day of the year
--

CREATE OR REPLACE FUNCTION create_timeseries_day_tables() RETURNS INTEGER
AS $$
DECLARE
tname TEXT;
idx_name TEXT;
idx2_name TEXT;
start_ts_iso_str TEXT;
start_ts TIMESTAMP WITH TIME ZONE;
start_ts_arg_str TEXT;
start_ts_str TEXT;
end_ts_iso_str TEXT;
end_ts TIMESTAMP WITH TIME ZONE;
end_ts_arg_str TEXT;
end_ts_str TEXT;
BEGIN
  FOR i IN 1..366 LOOP
    SELECT 'timeseries_default_by_day_' || ltrim(to_char(i, '999')) INTO STRICT tname;
    -- 20151030 GSH  Beware of the implicit use of a default (per system) time zone. 
    EXECUTE FORMAT('SELECT ''2015-'' || %L', i) INTO STRICT start_ts_str;
--    RAISE NOTICE 'start_ts_str = %', start_ts_str;
    EXECUTE FORMAT('SELECT quote_literal(%L) || '', '' || quote_literal(%L)', start_ts_str, 'YYYY-DDD') INTO STRICT start_ts_arg_str;
--    RAISE NOTICE 'start_ts_arg_str = %', start_ts_arg_str;
    EXECUTE FORMAT('SELECT TO_TIMESTAMP(%s)', start_ts_arg_str) INTO STRICT start_ts;
--    RAISE NOTICE 'start_ts = %', start_ts;
    SELECT  TO_CHAR(start_ts, 'YYYY-MM-DD HH24:MI:SSOF') INTO STRICT start_ts_iso_str;
--    RAISE NOTICE 'start_ts_iso_str = %', start_ts_iso_str;
    EXECUTE FORMAT('SELECT ''2015-'' || %L', i + 1) INTO STRICT end_ts_str;
--    RAISE NOTICE 'end_ts_str = %', end_ts_str;
    EXECUTE FORMAT('SELECT quote_literal(%L) || '', '' || quote_literal(%L)', end_ts_str, 'YYYY-DDD') INTO STRICT end_ts_arg_str;
--    RAISE NOTICE 'end_ts_arg_str = %', end_ts_arg_str;
    EXECUTE FORMAT('SELECT TO_TIMESTAMP(%s)', end_ts_arg_str) INTO STRICT end_ts;
--    RAISE NOTICE 'end_ts = %', end_ts;
    SELECT  TO_CHAR(end_ts, 'YYYY-MM-DD HH24:MI:SS') INTO STRICT end_ts_iso_str;
--    RAISE NOTICE 'end_ts_iso_str = %', end_ts_iso_str;

    EXECUTE FORMAT('CREATE TABLE IF NOT EXISTS %I (CONSTRAINT by_day CHECK (stamp >= %L and stamp < %L)) INHERITS (timeseries)', tname, start_ts_iso_str, end_ts_iso_str);
    SELECT 'timeseries_default_main_by_day_' || ltrim(to_char(i, '999')) || '_udx' INTO STRICT idx_name;
    SELECT 'timeseries_default_stamp_by_day_' || ltrim(to_char(i, '999')) || '_stamp_idx' INTO STRICT idx2_name;
    EXECUTE FORMAT('CREATE UNIQUE INDEX %I ON %I USING BTREE (account_id, object_id, metric_id, label_id, stamp)', idx_name, tname);
    EXECUTE FORMAT('CREATE INDEX %I ON %I USING BTREE (stamp)', idx2_name, tname);
    EXECUTE FORMAT('CLUSTER %I USING %I', tname, idx_name);
  END LOOP;
  RETURN 1;
END;
$$ language plpgsql;

SELECT create_timeseries_day_tables();

--
-- Create tables akin to those presently in use for benchmark 
-- (performance) comparisons
--

CREATE TABLE IF NOT EXISTS timeseries_default_slow (
  account_id INTEGER,
  object_id INTEGER,
  metric_id INTEGER,
  label_id INTEGER,
--  Warning:  Do NOT use the timestampz type.  Store all timestamp type values 
--            as (implicitly) UTC.  Do NOT risk daylight savings time hassles.  
--            Do NOT risk non-sargable timestamp values.  See
--            https://en.wikipedia.org/wiki/Sargable
--  stamp timestamp with time zone NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
  stamp TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),     
  value DOUBLE PRECISION NOT NULL
);

CREATE UNIQUE INDEX timeseries_default_slow_udx ON timeseries_default_slow USING BTREE (account_id, object_id, metric_id, label_id, stamp);
CREATE INDEX timeseries_default_slow_stamp_idx ON timeseries_default_slow USING BTREE (stamp);

SELECT COUNT(*) FROM timeseries; 
SELECT COUNT(*) FROM timeseries_default_slow;
