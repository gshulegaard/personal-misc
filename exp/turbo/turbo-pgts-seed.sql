CREATE OR REPLACE FUNCTION seed_timeseries_data() RETURNS INTEGER
AS $$
DECLARE
tname TEXT;
var1 INTEGER;
var2 INTEGER;
var3 INTEGER;
var4 INTEGER;
var5 TIMESTAMP;
var6 DOUBLE PRECISION;
BEGIN
  FOR i IN 1..999999 LOOP
    SELECT round(random() * 100)::INTEGER % 10 INTO STRICT var1;
    SELECT round(random() * 100)::INTEGER % 10 INTO STRICT var2;
    SELECT round(random() * 100)::INTEGER % 10 INTO STRICT var3;
    SELECT round(random() * 100)::INTEGER % 10 INTO STRICT var4;
    SELECT to_timestamp(FORMAT('2015-%s-%s-%s', lpad((i % 12)::TEXT, 2, '0'), lpad((i % 28)::TEXT, 2 ,'0'), lpad(i::TEXT, 6, '0')), 'YYYY-MM-DD-US') INTO STRICT var5;
    SELECT random() * 100 INTO STRICT var6;

    EXECUTE FORMAT('INSERT INTO timeseries (account_id, object_id, metric_id, label_id, stamp, value) VALUES (%L, %L, %L, %L, %L, %L)', var1, var2, var3, var4, var5, var6);
  END LOOP;
  RETURN 1;
END;
$$ language plpgsql;

SELECT seed_timeseries_data();

CREATE OR REPLACE FUNCTION seed_timeseries_data2() RETURNS INTEGER
AS $$
DECLARE
tname TEXT;
var1 INTEGER;
var2 INTEGER;
var3 INTEGER;
var4 INTEGER;
var5 TIMESTAMP;
var6 DOUBLE PRECISION;
BEGIN
  FOR i IN 1..999999 LOOP
    SELECT round(random() * 100)::INTEGER % 10 INTO STRICT var1;
    SELECT round(random() * 100)::INTEGER % 10 INTO STRICT var2;
    SELECT round(random() * 100)::INTEGER % 10 INTO STRICT var3;
    SELECT round(random() * 100)::INTEGER % 10 INTO STRICT var4;
    SELECT to_timestamp(FORMAT('2015-%s-%s-%s', lpad((i % 12)::TEXT, 2, '0'), lpad((i % 28)::TEXT, 2 ,'0'), lpad(i::TEXT, 6, '0')), 'YYYY-MM-DD-US') INTO STRICT var5;
    SELECT random() * 100 INTO STRICT var6;

    EXECUTE FORMAT('INSERT INTO timeseries_default_slow (account_id, object_id, metric_id, label_id, stamp, value) VALUES (%L, %L, %L, %L, %L, %L)', var1, var2, var3, var4, var5, var6);
  END LOOP;
  RETURN 1;
END;
$$ language plpgsql;

SELECT seed_timeseries_data2();