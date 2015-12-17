# -*- coding: utf-8 -*-
import time
import random

from datetime import datetime  # used in ES DocType definition, but maybe time.time() can be used instead?

import psycopg2

from elasticsearch import Elasticsearch
from elasticsearch_dsl import Index, DocType, Date


__author__ = "Grant Hulegaard"
__copyright__ = "Copyright (C) 2015, Nginx Inc. All rights reserved."
__credits__ = ["Mike Belov", "Andrei Belov", "Ivan Poluyanov", "Oleg Mamontov", "Andrew Alexeev", "Grant Hulegaard"]
__license__ = ""
__maintainer__ = "Grant Hulegaard"
__email__ = "grant.hulegaard@nginx.com"


# CONSTANTS
_DB_NAME = 'test'
_NUM_RECORDS = 100000
_MEASUREMENT_NAME = 'requests'


# Init Elasticsearch client
elastic_client = Elasticsearch('localhost')

# Configure Elasticsearch index
test = Index('test', using=elastic_client)
# test.settings(max_result_window=100000000)  # For testing only.  Using the _scroll api might be better suited in future.
# Index housekeeping
# test.delete(ignore=404)
# test.create()


# Define and Register the Elasticsearch document to the test index
# Registration could also be done after create with: test.doc_type(SimpleRecord)
@test.doc_type
class SimpleRecord(DocType):
    account_id = int()
    value = int()
    stamp = int()

    class Meta:
        index = 'test'

    def save(self, **kwargs):
        self.account_id = 1  # Default account_id to 1 for this test.

        return super(SimpleRecord, self).save(**kwargs)


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
    data = []
    counter = 0
    while counter < _NUM_RECORDS:
        value = random.randrange(0, 10000000)
        data.append((value, (counter + 0)))
        counter += 1

    return data


# Elasticsearch
@timeit
def elastic_write(data):
    for value, counter in data:
        # instantiate the document
        point = SimpleRecord(value=value, stamp=counter)
        # save the document
        point.save(using=elastic_client)

@timeit
def elastic_read():
    # s = Search(using=elastic_client)
    # s = s[None:100]  # set 'from' and 'size' params ([from]:[size]) None forces explicit specification of default
    # q = Q('match_all', query={})
    # s = s.query(q)
    # print str(s.to_dict()).replace("'", '"')
    # result = s.execute()
    # print result.to_dict()
    # return result.hits.hits
    response = elastic_client.search(
        index="test",
        body={
            "size": 100000000,
            "query": {
                "match_all": {}
            }
        }
    )
    return response['hits']['hits']

@timeit
def elastic_sum():
    response = elastic_client.search(
        index="test",
        doc_type="simple_record",
        body={
            "size": 0,
            "aggs": {
                "sum": {
                    "sum": {"field": "value"}
                }
            }
        }
    )
    return response['aggregations']['sum']['value']

@timeit
def elastic_average():
    response = elastic_client.search(
        index="test",
        doc_type="simple_record",
        body={
            "size": 0,
            "aggs": {
                "avg": {
                    "avg": {"field": "value"}
                }
            }
        }
    )
    return response['aggregations']['avg']['value']

@timeit
def elastic_group_sum():
    response = elastic_client.search(
        index="test",
        doc_type="simple_record",
        body={
            "size": 0,
            "aggs": {
                "values_per_ten_thousand": {
                    "histogram": {
                        "field": "stamp",
                        "interval": 10000
                    },
                    "aggs": {
                        "sum": {
                            "sum": {
                                "field": "value"
                            }
                        }
                    }
                }
            }
        }
    )
    return response['aggregations']['values_per_ten_thousand']['buckets']

@timeit
def elastic_group_average():
    response = elastic_client.search(
        index="test",
        doc_type="simple_record",
        body={
            "size": 0,
            "aggs": {
                "values_per_ten_thousand": {
                    "histogram": {
                        "field": "stamp",
                        "interval": 10000
                    },
                    "aggs": {
                        "avg": {
                            "avg": {
                                "field": "value"
                            }
                        }
                    }
                }
            }
        }
    )
    return response['aggregations']['values_per_ten_thousand']['buckets']

@timeit
def elastic_combined_metrics():
    response = elastic_client.search(
        index="test",
        doc_type="simple_record",
        body={
            "size": 0,
            "aggs": {
                "values_per_ten_thousand": {
                    "histogram": {
                        "field": "stamp",
                        "interval": 10000
                    },
                    "aggs": {
                        "sum": {
                            "sum": {
                                "field": "value"
                            }
                        },
                        "avg": {
                            "avg": {
                                "field": "value"
                            }
                        }
                    }
                }
            }
        }
    )
    return response['aggregations']['values_per_ten_thousand']['buckets']


# Postgres
@timeit
def postgres_write(postgres_data):
    for value, counter in postgres_data:
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

    # data = create_data()

    # Write tests

    # elastic_write(data)
    # postgres_write(data)

    # Read tests

    # time.sleep(1)
    # rows = elastic_read()
    # print "Elastic returned %s rows." % len(rows)
    #
    # rows = postgres_read()
    # print "Postgres returned %s rows." % len(rows)

    # Aggregate function tests

    data = elastic_sum()
    print "Elastic sum returned: %s" % data

    data = elastic_average()
    print "Elastic average returned: %s" % data

    rows = postgres_sum()
    print "Postgres sum returned: %s" % rows

    rows = postgres_average()
    print "Postgres average returned: %s" % rows

    # Grouped function tests
    data = elastic_group_sum()
    print "Elastic group sum returned %s rows." % len(data)
    print "Example: %s" % data[0]

    data = elastic_group_average()
    print "Elastic group average returned %s rows." % len(data)
    print "Example: %s" % data[0]

    data = elastic_combined_metrics()
    print "Elastic combined metrics returned %s rows" % len(data)
    print "Example: %s" % data[0]
