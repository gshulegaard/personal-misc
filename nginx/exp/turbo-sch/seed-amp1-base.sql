--  seed_timeseries_data()
--
--  ====  USAGE (via bash shell CLI)
--
--    psql -d amp1 -U gshulegaard -w -f bench1-amp1.sql \
--         -v rph=2 -v rpm=1 -v rps=1 -v num_accounts=2, \
--         -v num_objects=3, -v num_metrics=4, \
--         -v num_labels=5
--
--      *  -w implies you use a ~/.pgpass file.  For security 
--         reasons, always avoid putting DB passwords on any 
--         command line (... for psql or any other command).
--
--      *  rph := Reports Per Hour (RPH) for each unique combination 
--                of (account_id, object_id, metric_id, label_id).  
--                Determines the number of distinct minutes, per mintue, 
--                for which 'reports' (i.e. timeseries records) will 
--                be generated.
--
--      *  rpm := Reports Per Minute (RPM) for each unique combination 
--                of (account_id, object_id, metric_id, label_id).  
--                Determines the number of distinct seconds, per mintue, 
--                for which 'reports' (i.e. timeseries records) will 
--                be generated.
--
--      *  rps := Reports Per Second (RPS) for each minute and 
--                for each unique combination of 
--                (account_id, object_id, metric_id, label_id).  
--                Determines the number of distinct milliseconds 
--                (per second) for which 'reports' (i.e. timeseries 
--                records) will be generated.  
-- 
--         For one report per minute and per unique identify tuple of 
--         (account_id, object_iud, metric_id, label_id), use rpm = 1 
--         and rps = 1.
--
--      *  Be wary of using any value for rps that is > 1, 
--         especially when/if (ever?) rpm > 1. 
--         If rph = 60, rpm = 60 and rps = 1, then 12 (monnts) * 28 (days/month)
--         * 24 (hours/day) * 60 (minutes/hour) * 60 (seconds/minute) = 
--         29,030,400 'report' (records) per year.  
--
--         In this case, that means ~29M (timeseries) records 
--         would end up in *BOTH* the timeseries table AND in the 
--         timeseries_default_slow table.  Cranking up the 
--         reporting frequencies from rph=1, rpm = 1 and/or rps=1
--         can have a surprisingly big effect.  Wehn raising rph, rpm 
--         and rps frequencies together, beware of the synergistic 
--         effect.  Raising these frequencies together 
--         tends to quickly become a massive data volume 
--         multiplier.  
--
--         On top of it all, and ot make matters even worse, 
--         any reporting frequency driven data volume spike will hit
--         both the 'timeseries' table and the 'timeseries_default_slow' 
--         table.
--  
--      *  num_labels = 1 is likely to be the only sensible choice.
--
--         It appears as if label_id is part of the compound primary key 
--         for the 'timeseries' table only as a performance-tuning artifact.
--         There may well be a functional dependency between the tuple 
--         (account_id, object_id, metric_id) and one particular lable_id 
--         value.  If so, then, the label_id may have been pulled into 
--         the unique primary key (index) in order to make the primary key 
--         index a covering index for some dominant, performance critical 
--         query (or queries).  If this suspicion is true, then proliferating 
--         distinct label_id's for any given combination of (account_id, object_id, 
--         metric_id) can be disabled by 'psql ... -v num_labels=1 ...'
--
--  ====  LIMITATIONS
--  *  Any command line 'number' argument (like num_accounts, num_objects, etc.)
--     that exceeds 100,000 is silently (and implicitly) capped at 100,000.       
--
--  ====  DESIGN
--
--  20151030 GSH  Emulate the sequential (i.e. chronological) buildup of
--                otherwise randomized test data.  It is important to 
--                insert the data in a largely chronological order to 
--                make benchmarking queries against this data more 
--                realistic.  If the data arrives in chronological order,
--                it will often be (by default) stored in a way that 
--                offers a significant degree of 'locality of (block-level) 
--                reference' (even for storage that is not index clustered).
--                Failing to do this might bias certain benchmarks against 
--                non-chronologically sorted data.  In production, most
--                data arrives in (usually and largely) chronologically 
--                order.                
--
--  ====  FUTURE DIRECTIONS
--
--  *  Convert this psql script (w/embedded pgplsql) to Python (or whatever)
--     It is sort of bad form to push pgplsql to the point that bash shell 
--     (command line supplied) arguments like the following:
--       psql's -v <set_var_name>=<set_var_value>) 
--     are (herein) being pushed into plpgsqsl functions (via function 
--     arguments receiving SQL interpolated values from pgsql).  
--
--     After all, pgplsql is NOT a general-purpose scripting 
--     language.  It was never meant to be a programming/scripting language 
--     on a par with Python, Ruby, etc.  This particular 'feature' of pgplsql 
--     is fragile.  It often leads to contorted quoting of the command line 
--     arguments.  Here, the command line arguments are all integer's - so 
--     perhaps this is O.K.  All the same, the embedded pgplsql (functions) 
--     herein is just expedient.  For further details, see the following:
-- http://stackoverflow.com/questions/3259703/are-there-any-escaping-syntax-for-psql-variable-inside-postgresql-functions
--
-- Clean up any pre-existing data.  Path of least astonishment (POLA) when re-running 
-- this script.
TRUNCATE timeseries;
TRUNCATE timeseries_default_slow;
DROP FUNCTION IF EXISTS seed_timeseries_data("rph" INTEGER,
                                             "rpm" INTEGER,
                                             "rps" INTEGER,
                                             "num_accounts" INTEGER,
                                             "num_objects" INTEGER,
                                             "num_metrics" INTEGER,
                                             "num_labels" INTEGER);
--  WARNING:  First, PG supports overloaded functions, you need the full
--            function signature to unambiguousy identify a function.  See
-- http://stackoverflow.com/questions/30782925/postgresql-how-to-drop-function-if-exists-without-specifying-parameters
--            Second, when changing the arguments to a PG function, there's 
--            an ambiguity when/if a new function signature is ever
--            created (or ever replaced).  PG doesn't know if the new function 
--            should complement the old one as yet another overloaded variation 
--            (distinguished by argument types) OR if the new function should 
--            replace the old function (and thus change the argument types).
--            Therefore, it tends to be a common practice to drop the previously 
--            defined function (esp. during development) and then just recreate
--            it.  Trying to rely on 'OR REPLACE' to read the developers own mind, 
--            in some impossible effort to suss out the developer's intention, 
--            will NOT work.  There's an ambiguity here.  As a result, this 
--            script always runs the 'DROP FUNCTION' command above (before running 
--            the 'CREATE OR REPLACE FUNCTION' below.
--
CREATE OR REPLACE FUNCTION seed_timeseries_data("rph" INTEGER,
                                                "rpm" INTEGER,
                                                "rps" INTEGER, 
                                                "num_accounts" INTEGER,
                                                "num_objects" INTEGER,
                                                "num_metrics" INTEGER,
                                                "num_labels" INTEGER) 
RETURNS INTEGER
AS $$
DECLARE
last_minute INTEGER;
last_second INTEGER; 
last_millisecond INTEGER;
tname TEXT;
-- end_year INTEGER;
aid INTEGER;
oid INTEGER;
mid INTEGER;
lid INTEGER;
ts TIMESTAMP;
random_val DOUBLE PRECISION;
BEGIN
--  FD:  Hardcode the year to 2015.  Ignore the following  
--    EXECUTE 'SELECT (2000 + $1)::INTEGER' INTO STRICT end_year USING num_years;
--    RAISE NOTICE 'end_year = %', end_year;
--    FOR y in 2000..end_year LOOP
  EXECUTE 'SELECT CASE WHEN $1 > 60 THEN 59 WHEN $1 < 1 THEN 0 ELSE ($1 - 1) END' INTO STRICT last_minute USING rph;
  RAISE NOTICE 'last_minute = %', last_minute;
  EXECUTE 'SELECT CASE WHEN $1 > 60 THEN 59 WHEN $1 < 1 THEN 0 ELSE ($1 - 1) END' INTO STRICT last_second USING rpm;
  RAISE NOTICE 'last_second = %', last_second;
  EXECUTE 'SELECT CASE WHEN $1 > 999 THEN 999 WHEN $1 < 1 THEN 0 ELSE ($1 - 1) END' INTO STRICT last_millisecond USING rps;
  RAISE NOTICE 'last_millisecond = %', last_millisecond;
  FOR mm in 1..12 LOOP
    FOR d in 1..28 LOOP
      FOR h in 0..23 LOOP
--      Next, crudely hack around daylight savings time adjustments, to either timestamp or
--      timestampz values, inducing errors like:
-- psql:seed-amp1.sql:207: ERROR:  23505: duplicate key value violates unique constraint "timeseries_default_main_by_day_67"
-- DETAIL:  Key (account_id, object_id, metric_id, label_id, stamp)=(0, 0, 0, 0, 2015-03-08 03:00:00) already exists.
-- CONTEXT:  SQL statement "INSERT INTO timeseries_default_by_day_67 (account_id, object_id, metric_id, label_id, stamp, value) VALUES ('0', '0', '0', '0', '2015-03-08 03:00:00', '58.72')"
-- For further details, see
-- http://postgresql.nabble.com/to-timestamp-and-timestamp-without-time-zone-td4517970.html
        IF mm = 3 AND (d BETWEEN 6 AND 10) AND (h BETWEEN 2 AND 4) THEN 
          CONTINUE;
        END IF;  
        FOR mi in 0..last_minute LOOP
          FOR ss in 0..last_second LOOP
            FOR ms IN 0..last_millisecond LOOP
              FOR aid IN 0..num_accounts LOOP
                FOR oid IN 0..num_objects LOOP
                  FOR mid IN 0..num_metrics LOOP
                    FOR lid IN 0..num_labels LOOP
                      SELECT to_timestamp(FORMAT('2015-%s-%s-%s-%s-%s-%s', 
                                          lpad(mm::TEXT, 2, '0'), 
                                          lpad(d::TEXT, 2 ,'0'), 
                                          lpad(h::TEXT, 2, '0'), 
                                          lpad(mi::TEXT, 2, '0'), 
                                          lpad(ss::TEXT, 2, '0'), 
                                          lpad(ms::TEXT, 3, '0')),
                                          'YYYY-MM-DD-HH24-MI-SS-MS') 
                                          AT TIME ZONE 'UTC' AT TIME ZONE 'UTC'
                                          INTO STRICT ts;
                      SELECT round((random() * 100)::NUMERIC, 2) INTO STRICT random_val;

                      EXECUTE FORMAT('INSERT INTO timeseries (account_id, object_id, metric_id, label_id, stamp, value) VALUES (%L, %L, %L, %L, %L, %L)', aid, oid, mid, lid, ts, random_val);
                    END LOOP;
                  END LOOP;
                END LOOP;
              END LOOP;
            END LOOP;
          END LOOP;
        END LOOP;
      END LOOP;
    END LOOP;
--    END LOOP;
  END LOOP;

  RETURN 1;
END;
$$ language plpgsql;

SELECT seed_timeseries_data(:rph, :rpm, :rps, :num_accounts, :num_objects, :num_metrics, :num_labels);

DROP FUNCTION IF EXISTS seed_timeseries_data2("rph" INTEGER,
                                              "rpm" INTEGER,
                                              "rps" INTEGER,
                                              "num_accounts" INTEGER,
                                              "num_objects" INTEGER,
                                              "num_metrics" INTEGER,
                                              "num_labels" INTEGER);

CREATE OR REPLACE FUNCTION seed_timeseries_data2("rph" INTEGER,
                                                 "rpm" INTEGER,
                                                 "rps" INTEGER, 
                                                 "num_accounts" INTEGER,
                                                 "num_objects" INTEGER,
                                                 "num_metrics" INTEGER,
                                                 "num_labels" INTEGER) 
RETURNS INTEGER
AS $$
DECLARE
last_minute INTEGER;
last_second INTEGER;
last_millisecond INTEGER; 
tname TEXT;
-- end_year INTEGER;
aid INTEGER;
oid INTEGER;
mid INTEGER;
lid INTEGER;
ts TIMESTAMP;
random_val DOUBLE PRECISION;
BEGIN
--  FD:  Hardcode the year to 2015.  Ignore the following  
--    EXECUTE 'SELECT (2000 + $1)::INTEGER' INTO STRICT end_year USING num_years;
--    RAISE NOTICE 'end_year = %', end_year;
--    FOR y in 2000..end_year LOOP
  EXECUTE 'SELECT CASE WHEN $1 > 60 THEN 59 WHEN $1 < 1 THEN 0 ELSE ($1 - 1) END' INTO STRICT last_minute USING rph;
  RAISE NOTICE 'last_minute = %', last_minute;
  EXECUTE 'SELECT CASE WHEN $1 > 60 THEN 59 WHEN $1 < 1 THEN 0 ELSE ($1 - 1) END' INTO STRICT last_second USING rpm;
  RAISE NOTICE 'last_second = %', last_second;
  EXECUTE 'SELECT CASE WHEN $1 > 999 THEN 999 WHEN $1 < 1 THEN 0 ELSE ($1 - 1) END' INTO STRICT last_millisecond USING rps;
  RAISE NOTICE 'last_millisecond = %', last_millisecond;
  FOR mm in 1..12 LOOP
    FOR d in 1..28 LOOP
      FOR h in 0..23 LOOP
--      Next, crudely hack around daylight savings time adjustments, to either timestamp or
--      timestampz values, inducing errors like:
-- psql:seed-amp1.sql:207: ERROR:  23505: duplicate key value violates unique constraint "timeseries_default_main_by_day_67"
-- DETAIL:  Key (account_id, object_id, metric_id, label_id, stamp)=(0, 0, 0, 0, 2015-03-08 03:00:00) already exists.
-- CONTEXT:  SQL statement "INSERT INTO timeseries_default_by_day_67 (account_id, object_id, metric_id, label_id, stamp, value) VALUES ('0', '0', '0', '0', '2015-03-08 03:00:00', '58.72')"
-- For further details, see
-- http://postgresql.nabble.com/to-timestamp-and-timestamp-without-time-zone-td4517970.html
        IF mm = 3 AND (d BETWEEN 6 AND 10) AND (h BETWEEN 2 AND 4) THEN 
          CONTINUE; 
        END IF;  
        FOR mi in 0..last_minute LOOP
          FOR ss in 0..last_second LOOP
            FOR ms IN 0..last_millisecond LOOP
              FOR aid IN 0..num_accounts LOOP
                FOR oid IN 0..num_objects LOOP
                  FOR mid IN 0..num_metrics LOOP
                    FOR lid IN 0..num_labels LOOP
                      SELECT to_timestamp(FORMAT('2015-%s-%s-%s-%s-%s-%s', 
                                          lpad(mm::TEXT, 2, '0'), 
                                          lpad(d::TEXT, 2 ,'0'), 
                                          lpad(h::TEXT, 2, '0'),
                                          lpad(mi::TEXT, 2, '0'), 
                                          lpad(ss::TEXT, 2, '0'), 
                                          lpad(ms::TEXT, 3, '0')), 
                                          'YYYY-MM-DD-HH24-MI-SS-MS')
                                          AT TIME ZONE 'UTC' AT TIME ZONE 'UTC' 
                                          INTO STRICT ts;
                      SELECT round((random() * 100)::NUMERIC, 2) INTO STRICT random_val;

                      EXECUTE FORMAT('INSERT INTO timeseries_default_slow (account_id, object_id, metric_id, label_id, stamp, value) VALUES (%L, %L, %L, %L, %L, %L)', aid, oid, mid, lid, ts, random_val);
                    END LOOP;
                  END LOOP;
                END LOOP;
              END LOOP;
            END LOOP;
          END LOOP;
        END LOOP;
      END LOOP;
    END LOOP;
--    END LOOP;
  END LOOP;

  RETURN 1;
END;
$$ language plpgsql;

SELECT seed_timeseries_data2(:rph, :rpm, :rps, :num_accounts, :num_objects, :num_metrics, :num_labels);

SELECT COUNT(*) AS TS_Count   FROM timeseries; 
SELECT COUNT(*) AS TSDS_Count FROM timeseries_default_slow;
