INSERT INTO timeseries (account_id, object_id, metric_id, label_id, stamp, value) VALUES (1, 1, 1, 1, to_timestamp('01 Jan 2015', 'DD Mon YYYY'), 1.0);
INSERT INTO timeseries (account_id, object_id, metric_id, label_id, stamp, value) VALUES (1, 1, 1, 1, to_timestamp('02 Jan 2015', 'DD Mon YYYY'), 1.0);
INSERT INTO timeseries (account_id, object_id, metric_id, label_id, stamp, value) VALUES (1, 1, 1, 1, to_timestamp('03 Jan 2015', 'DD Mon YYYY'), 1.0);

SELECT * FROM timeseries;

SELECT * FROM timeseries_default_by_day_1;