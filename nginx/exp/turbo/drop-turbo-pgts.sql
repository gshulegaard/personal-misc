DROP TRIGGER insert_timeseries_trigger ON timeseries;

DROP FUNCTION timeseries_insert_trigger();

--
-- Loop to drop day tables
--

CREATE OR REPLACE FUNCTION drop_timeseries_day_tables() RETURNS INTEGER
AS $$
DECLARE
tname TEXT;
BEGIN
  FOR i IN 1..366 LOOP
    SELECT 'timeseries_default_by_day_' || ltrim(to_char(i, '999')) INTO STRICT tname;
    EXECUTE format('DROP TABLE IF EXISTS %I', tname);
  END LOOP;
  RETURN 1;
END;
$$ language plpgsql;

SELECT drop_timeseries_day_tables();

-- DROP TABLE timeseries_default;

DROP TABLE timeseries;

DROP TABLE timeseries_default_slow;