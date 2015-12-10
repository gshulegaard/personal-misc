# -*- coding: utf-8 -*-
import time
import random

from datetime import datetime

from influxdb import InfluxDBClient
import psycopg2


__author__ = "Grant Hulegaard"
__copyright__ = "Copyright (C) 2015, Nginx Inc. All rights reserved."
__credits__ = ["Mike Belov", "Andrei Belov", "Ivan Poluyanov", "Oleg Mamontov", "Andrew Alexeev", "Grant Hulegaard"]
__license__ = ""
__maintainer__ = "Grant Hulegaard"
__email__ = "grant.hulegaard@nginx.com"


# CONSTANTS
_DB_NAME = 'time_test'
_NUM_RECORDS = 100000
_MEASUREMENT_NAME = 'requests'


# Init influxdb client
# vars: address, port, username, password, database
influx_client = InfluxDBClient('localhost', 8086, 'root', 'root', _DB_NAME)


# Init postgres conn
postgres_conn = psycopg2.connect("dbname=%s user=granthulegaard" % _DB_NAME)
postgres_cur = postgres_conn.cursor()


# HELPERS

# Simple timer decorator...
# https://www.andreas-jung.com/contents/a-python-decorator-for-measuring-the-execution-time-of-methods
def timeit(method):

    def timed(*args, **kwargs):
        ts = time.time()
        result = method(*args, **kwargs)
        te = time.time()

        print '%r %2.2f sec' % \
              (method.__name__, te-ts)
        return result

    return timed


@timeit
def create_data():
    """
    Influx expects something like:
    json_body = [
        {
            "measurement": "cpu_load_short",
            "tags": {
                "host": "server01",
                "region": "us-west"
            },
            "time": "2009-11-10T23:00:00Z",
            "fields": {
                "value": 0.64
            }
        }
    ]
    :return json:
    """
    influx_json=[]
    postgres_data = []
    counter = 0
    while counter < _NUM_RECORDS:
        value = random.randrange(0, 10000000)
        influx_json.append(
            {
                'measurement': _MEASUREMENT_NAME,
                'fields': {
                    'value': value
                }
            }
        )
        postgres_data.append(value)
        counter += 1

    return influx_json, postgres_data


# InfluxDB
@timeit
def influx_write(influx_json):
    for point in influx_json:
        influx_client.write_points([point])


@timeit
def influx_read():
    result = influx_client.query('SELECT * FROM requests')
    rows = []
    for series in result:
        for row in series:
            rows.append(row)
    return rows

@timeit
def influx_sum():
    result = influx_client.query('SELECT sum(value) FROM requests')
    rows = []
    for series in result:
        for row in series:
            rows.append(row)
    return rows

@timeit
def influx_average():
    result = influx_client.query('SELECT mean(value) FROM requests')
    rows = []
    for series in result:
        for row in series:
            rows.append(row)
    return rows

@timeit
def influx_group_sum():
    result = influx_client.query("SELECT sum(value) FROM requests WHERE time > '2015-08-18T00:00:00Z' GROUP BY time(1h)")
    rows = []
    for series in result:
        for row in series:
            rows.append(row)
    return rows

@timeit
def influx_group_average():
    result = influx_client.query("SELECT mean(value) FROM requests WHERE time > '2015-08-18T00:00:00Z' GROUP BY time(1h)")
    rows = []
    for series in result:
        for row in series:
            rows.append(row)
    return rows

# Postgres
@timeit
def postgres_write(postgres_data):
    for value in postgres_data:
        postgres_cur.execute("""INSERT INTO timeseries (account_id, object_id, metric_id, label_id, value) VALUES (1, 1, 1, 1, %s)""" % value)
        postgres_conn.commit()


@timeit
def postgres_read():
    postgres_cur.execute("""SELECT * FROM timeseries""")
    postgres_conn.commit()
    return postgres_cur.fetchall()


@timeit
def postgres_sum():
    postgres_cur.execute("""SELECT sum(value) sum from timeseries""")
    postgres_conn.commit()
    return postgres_cur.fetchall()

@timeit
def postgres_average():
    postgres_cur.execute("""SELECT avg(value) average from timeseries""")
    postgres_conn.commit()
    return postgres_cur.fetchall()


if __name__ == '__main__':
    """
    This script will perform some basic timed benchmarks on both Postgres and InfluxDB.

    This script assumes that the database "time_test" is already created in both Postgres and InfluxDB
    """

    print "--- START ---"

    # Prep

    influx_json, postgres_data = create_data()

    # Write tests

    # influx_write(influx_json)
    # postgres_write(postgres_data)

    # Read tests

    # influx_rows = influx_read()
    # print "Influx returned %s rows." % len(influx_rows)

    # postgres_rows = postgres_read()
    # print "Postgres returned %s rows." % len(postgres_rows)

    # Aggregate function tests

    # influx_rows = influx_sum()
    # print "Influx sum returned: %s" % influx_rows
    #
    # influx_rows = influx_average()
    # print "Influx average returned: %s" % influx_rows
    #
    # postgres_rows = postgres_sum()
    # print "Postgres sum returned: %s" % postgres_rows
    #
    # postgres_rows = postgres_average()
    # print "Postgres average returned: %s" % postgres_rows

    # Grouped function tests
    influx_rows = influx_group_sum()
    print "Influx group sum returned %s rows." % len(influx_rows)

    influx_rows = influx_group_average()
    print "Influx group average returned %s rows." % len(influx_rows)
