"""
Core RESTful API:

This main.py file defines the flask Blueprint/Application that composes our
"Core" API endpoint calls.

Author: Grant Hulegaard
"""

from flask import Blueprint, request, jsonify

from atms_api.services.config import Config, DEBUG
from atms_api.services.validators import login_required

import atms_api.core.views as views
import atms_api.core.soap



# Flask blueuprint
api_core = Blueprint('api_core',
                     __name__)


#
# Routes
#

# FD: Factor this processing out as a view function to avoid unneccessary
# imports in this file.
@api_core.route('/status', methods=['GET'])
def routeStatus():
    """
    Unsecured status API. This end point is meant for revealing diagnostic
    information to end user's

    @return {json}
        Contents: 'status', 'message'
    """

    resp = {}

    # Check SOAP API.
    if atms_api.core.soap.client == None:
        resp['status'] = "-1000"
        resp['message'] = "There was a problem downloading the SOAP API."
        return jsonify(**resp)

    # Check configuration file.
    if 'atmsapi' not in Config:
        resp['status'] = "-1001"
        resp['message'] = "Unable to load configuration file."
        return jsonify(**resp)

    # Check if configuration was production or fellback to development.
    if DEBUG == True:
        resp['status'] = "-1002"
        resp['message'] = ("Production settings file was not found. " + 
                           "Fell back on Development .ini.")
        return jsonify(**resp)

    resp['status'] = "0"
    resp['message'] = "Flask blueprint for 'api_core' was loaded."

    return jsonify(**resp)

# FD: Factor this processing out as a view to remove login_required import in
# this file.
@api_core.route('/config', methods=['GET'])
@login_required
def routeConfig():
    """
    Secured configuration API.  This end point is mean to be accessed by the web
    client to retrieve configuration settings from the Python runtime.

    @return {json}
        Contents: settings.ini
    """

    return jsonify(**Config)

@api_core.route('/login', methods=['POST', 'DELETE'])
def routeLogin():
    """
    Login API end-point.  Handles POST (logging in) and DELETE (logging out).

    @return {json} resp
        Contents:
            POST: 'status', 'message', 'token'
            DELETE: 'status', 'message', 'username'
    """

    if request.method == 'POST':
        resp = views.login_post()
    elif request.method == 'DELETE':
        resp = views.login_delete()

    return jsonify(**resp)

@api_core.route('/password', methods=['POST', 'PUT'])
def routePassword():
    """
    Password management end-point.  Supports password recovery by e-mail (POST)
    and password changing (PUT).

    @return {json} resp
        Contents: 'status', 'message'
    """

    if request.method == 'POST':
        resp = views.password_post()
    elif request.method == 'PUT':
        resp = views.password_put()

    return jsonify(**resp)

@api_core.route('/applications', methods=['GET'])
def routeApplications():
    """
    Returns the applications the authenticated user can access.

    @return {json} resp
        Contents: 'status', 'message', 'application_list', 'application_count'
    """

    resp = views.applications_get()

    return jsonify(**resp)
