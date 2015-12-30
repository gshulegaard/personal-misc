--
-- Name: timeseries; Type: TABLE; Schema: public; Owner: postgres; Tablespace:
--

CREATE TABLE IF NOT EXISTS timeseries(
  id SERIAL PRIMARY KEY,
  account_id INTEGER,
  object_id INTEGER,
  metric_id INTEGER,
  label_id INTEGER,
  stamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  value DOUBLE PRECISION
);

CREATE INDEX timeseries_main ON timeseries USING BTREE (account_id, object_id, metric_id, label_id, stamp);
CREATE INDEX timeseries_stamp ON timeseries USING BTREE (stamp);