"""
main.py:

This is the microservice definition for a simple service that accepts a data
stream of integers and returns the median value for the data stream for the last
minute of data.
"""

import os
import datetime
import logging
from logging.handlers import RotatingFileHandler
from functools import wraps
from collections import deque

from flask import Flask, request, jsonify, abort
from flask.ext.cors import CORS


app = Flask(__name__)

# CORS handling...
# https://flask-cors.readthedocs.org/en/latest/
CORS(app)


#
# Variables
#

dataStream = deque([])


#
# Helpers
#

def unix_time():
    """
    Return an integer representation of a timestamp.  This is done by
    calculation the timedelta between now and the epoch and returning the
    representation in milliseconds.

    The epoch is the Unix time epoch (January 1st, 1970 00:00:00)

    FD: This function could be generalized to return the representation of any
    passed datetime (instead of hard coding for "now" via utcnow()).
    """
    epoch = datetime.datetime.utcfromtimestamp(0)
    delta = datetime.datetime.utcnow() - epoch
    return delta.total_seconds() * 1000 # *1000 to convert to milliseconds

def cleanStream():
    """
    Functiton that traverses the dataStream object and removes records older
    than 1 minute.
    """
    currentDatetime = unix_time()
    count = 0

    # Iterate backwards over the dataStream and count records older than a
    # minute. Only iterate until you reach the first non-expired record.
    for element in reversed(dataStream):
        if (currentDatetime - element[1]) > (60 * 1000):
            count += 1
        else:
            break

    # Pop the number of counted records out of the dataStream.
    for _i in range(count):
        dataStream.pop()

    app.logger.debug("Trimmed %d element(s) from dataStream.", count)

def routePut_validator(f):
    """
    Simple validation decorator that checks to see if the expected inputs are in
    the JSON package.
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        # Check to see if the required fields are in the HTTP JSON doc.
        if 'intVal' not in request.json:
            app.logger.error(
                "Received an improperly formatted POST request to '/put'."
            )
            abort(400)

        if not isinstance(request.json['intVal'], int):
            app.logger.error(
                "Ignoring '%s'. Non-integer argument.",
                request.json['intVal']
            )
            abort(400)

        return f(*args, **kwargs)

    return decorated_function


#
# Routes
#

@app.route('/put', methods=['POST'])
@routePut_validator
def routePut():
    """
    Simple API endpoint that takes an integer and adds it to the data stream and
    performs incremental data cleaning.

    @return {json}
        Contents: 'status', 'message'
    """
    resp = {}

    # Incremental removal of expired data.
    cleanStream()

    dataStream.appendleft((request.json['intVal'], unix_time()))

    resp['message'] = "Integer value accepted."

    app.logger.debug("Added new tuple to dataStream (%d, %d).",
                     dataStream[0][0], dataStream[0][1])

    return jsonify(**resp)

@app.route('/median', methods=['GET'])
def routeMedian():
    """
    Simple API endpoint that returns the median of the dataStream.  Also
    performs incremental data cleaning to ensure that the median is for data
    over the last minute.

    @return {json}
        Contents: 'median' or 'message'
            - 'median' always returns a float to be consistent.
    """
    resp = {}

    # Incremental removal of expired data.
    cleanStream()

    dataStreamLength = len(dataStream)

    if dataStreamLength > 0:
        # Calculate median.
        if (dataStreamLength % 2) == 0:
            # If length is even, get two center values and take the average.
            dataStreamIntsSorted = sorted(i[0] for i in dataStream)
            value1 = dataStreamIntsSorted[(dataStreamLength / 2) - 1]
            value2 = dataStreamIntsSorted[dataStreamLength / 2]

            # Return a float here to accomodate values of .5.
            # eg. 101/2 -> 50.5 (instead of 50 as truncated integer)
            median = float(value1 + value2) / 2
        else:
            # If length is odd, get the center value.
            median = float(sorted(i[0] for i in dataStream)[((dataStreamLength + 1) / 2) - 1])
            # To be consistent, median must always return a float.

        resp['median'] = median
        app.logger.debug("Returned median: %d.", median)
        app.logger.debug("Current sorted values are: %s.", 
                         str(list(sorted([i[0] for i in dataStream]))).strip('[]'))
    else:
        resp['message'] = "No data for the last minute."
        app.logger.debug("Handled empty dataStream for request to '/median'.")

    return jsonify(**resp)


# Development
if __name__ == '__main__':
    app.debug = True

    # Configure logging.
    handler = RotatingFileHandler('DEBUG.log', maxBytes=100000, backupCount=1)
    handler.setLevel(logging.DEBUG)
    app.logger.addHandler(handler)

    # Start development server
    app.run()
