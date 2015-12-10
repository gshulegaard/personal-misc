"""
atms-api.main.py:

This file contains the primary application definition.

Dependencies:
    - flask
    - flask-cors

Author: Grant Huleagard
"""

import os

from flask import Flask, jsonify
from flask.ext.cors import CORS

from atms_api.core.main import api_core


#
# Flask App
#

app = Flask(__name__)

# CORS handling...
# https://flask-cors.readthedocs.org/en/latest/
CORS(app)


#
# Blueprints
#

app.register_blueprint(api_core, url_prefix='/core')


#
# Routes
#

@app.route('/status', methods=['GET'])
def routeStatus():
    """
    Unsecured status API. This end point is meant for revealing diagnostic
    information to end user's.

    @return {json}
        Contents: 'status', 'message'
    """

    resp = {}

    resp['status'] = "0"
    resp['message'] = "Flask API is running and responding."

    return jsonify(**resp) 


#
# Custom Errors
#

# FD: Add custom error handling that returns JSON rather than Nginx HTML pages.


# Development
if __name__ == '__main__':
    # Turn on DEBUG
    app.debug = True

    # Start development server
    app.run()
