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

DROP TABLE IF EXISTS timeseries;

DROP TABLE IF EXISTS timeseries_default_slow;

DROP TABLE IF EXISTS timeseries_by_4_hours;

select * from pg_tables where lower(tablename) like 'time%';

SELECT p.proname AS funcname,  d.description
 FROM pg_proc p
   INNER JOIN pg_namespace n ON n.oid = p.pronamespace
   LEFT JOIN pg_description As d ON (d.objoid = p.oid )
     WHERE n.nspname = 'topology' and d.description ILIKE '%creat%'
   ORDER BY n.nspname, p.proname ;
