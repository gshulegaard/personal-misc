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

--
-- Name: timeseries; Type: TABLE; Schema: public; Owner: naas; Tablespace:
--

CREATE TABLE IF NOT EXISTS timeseries (
  account_id integer,
  object_id integer,
  metric_id integer,
  label_id integer,
  stamp timestamp with time zone NOT NULL DEFAULT now(),
  value double precision
);
CREATE TRIGGER insert_timeseries_trigger BEFORE INSERT ON timeseries FOR EACH ROW EXECUTE PROCEDURE timeseries_insert_trigger();

--
-- Partitions default. Others - see storage/sq/maintenance/
--

--CREATE TABLE IF NOT EXISTS timeseries_default () INHERITS (timeseries);
--CREATE UNIQUE INDEX timeseries_default_main ON timeseries_default USING btree (account_id, object_id, metric_id, label_id, stamp);
--CREATE INDEX timeseries_default_stamp ON timeseries_default USING btree (stamp);

--
-- Loop to create day tables
--

CREATE OR REPLACE FUNCTION create_timeseries_day_tables() RETURNS INTEGER
AS $$
DECLARE
tname TEXT;
idx_name TEXT;
idx2_name TEXT;
start_ts TIMESTAMP;
end_ts TIMESTAMP;
BEGIN
  FOR i IN 1..366 LOOP
    SELECT 'timeseries_default_by_day_' || ltrim(to_char(i, '999')) INTO STRICT tname;
    SELECT to_timestamp(FORMAT('2015-%s', i), 'YYYY-DDD') INTO STRICT start_ts;
    SELECT to_timestamp(FORMAT('2015-%s', i + 1), 'YYYY-DDD') INTO STRICT end_ts;

    EXECUTE FORMAT('CREATE TABLE IF NOT EXISTS %I (CONSTRAINT by_day CHECK (stamp >= %L and stamp < %L)) INHERITS (timeseries)', tname, start_ts, end_ts);
    -- This is the covering index
    SELECT 'timeseries_default_main_by_day_' || ltrim(to_char(i, '999')) INTO STRICT idx_name;
    SELECT 'timeseries_default_stamp_by_day_' || ltrim(to_char(i, '999')) INTO STRICT idx2_name;
    EXECUTE FORMAT('CREATE UNIQUE INDEX %I ON %I USING BTREE (account_id, object_id, metric_id, label_id, stamp)', idx_name, tname);
    EXECUTE FORMAT('CREATE INDEX %I ON %I USING BTREE (stamp)', idx2_name, tname);
    --EXECUTE FORMAT('CLUSTER %I USING %I', tname, idx_name);
  END LOOP;
  RETURN 1;
END;
$$ language plpgsql;

SELECT create_timeseries_day_tables();

--
-- Name: timeseries; Type: TABLE; Schema: public; Owner: naas; Tablespace:
--

CREATE TABLE IF NOT EXISTS timeseries_default_slow (
  account_id integer,
  object_id integer,
  metric_id integer,
  label_id integer,
  stamp timestamp with time zone NOT NULL DEFAULT now(),
  value double precision
);

CREATE UNIQUE INDEX timeseries_default_slow_main ON timeseries_default_slow USING BTREE (account_id, object_id, metric_id, label_id, stamp);
CREATE INDEX timeseries_default_slow_stamp ON timeseries_default_slow USING BTREE (stamp);