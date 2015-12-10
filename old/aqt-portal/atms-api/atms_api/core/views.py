"""
Core Views:

This module provides convenient function handling for different endpoint (route)
views.  This will allow for greater modularization as well as selective
application of decorators (see atms_api.core.validators).

Author: Grant Huleagard
"""

from flask import request

from atms_api.services.auth import AuthFactory
from atms_api.services.validators import login_required, login_post_validator, \
    password_post_validator, password_put_validator
import atms_api.core.soap as soap

# Instantiate local instance of AuthFactory.

auth = AuthFactory()

@login_post_validator
def login_post():
    """
    Authenticates user against SOAP ValidateLogin method and issues a token
    if successful.  If a user has an expired password, they will still be
    issued a token, but will be returned a '-2' status.
    
    @param {string} username
    @param {string} password
    
    @returns {dict} resp
        Contents: 'token', 'status', 'message'
    """
    
    resp = {}
    
    username = request.json['username']
    password = request.json['password']

    print username, password

    # Query the SOAP API for a user record.
    atmsdata = soap.ValidateLogin(username, password)
    
    # If soap returns a non-success code that is not password expired...
    if (atmsdata['status'] != '0' and
        atmsdata['status'] != '-2'):
        # Break processing and return error.
        resp = atmsdata
        return resp
        
    # Add the user and token combination to the store.
    token = auth.new(username)
    
    resp['token'] = '{!s}-{!s}'.format(username, token)
    resp['status'] = atmsdata['status']
    resp['message'] = atmsdata['message']
        
    return resp

@login_required
def login_delete():
    """
    Removes user and token from authorized data store.
    
    @param {string} username
        This is gathered from the X-Core-Token passed.
    
    @returns {dict} resp
        Contents: 'status', 'message', 'username'
    """

    resp = {}

    # X-Core-Token header takes form as [username]-[token]
    username = str(request.headers['X-Core-Token']).split('-')[0]
    # FD: Might not need string conversion.

    auth.delete(username)

    resp['status'] = '0'
    resp['message'] = 'Logout succesful.'
    resp['username'] = username

    return resp

@password_post_validator
def password_post():
    """
    Sends a user an e-mail for password recovery.
    
    @param {string} username
    
    @return {dict} resp
        Contents: 'status', 'message'
    """
    
    username = request.json['username']
    
    # Send information to SOAP API to try and send e-mail.
    atmsdata = soap.EmailPassword(username)
    
    # Regardless of status, return response from SOAP API.
    resp = atmsdata

    return resp

@login_required
@password_put_validator
def password_put():
    """
    Change a user's password using the SOAP ChangePassword method.
    Validation of whether or not the new password phrases match is
    offloaded to the front-end SPA.  Validation of the old password is
    offloaded to the SOAP API.
    
    @param {string} username
        This is gathered from the X-Core-Token passed.
    @param {string} oldpassword
    @param {string} newpassword
    
    @return {dict} resp
        Contents: 'status', 'message'
    """
    
    # Grab username from Authorization header.
    username = str(request.headers['X-Core-Token']).split('-')[0]
    oldpassword = request.json['oldpassword']
    newpassword = request.json['newpassword']
    
    # Send information to SOAP API to try and change password in DB.
    atmsdata = soap.ChangePassword(username, oldpassword, newpassword)
    
    # Regardless of status, return response from SOAP API.
    resp = atmsdata

    return resp

@login_required
def applications_get():
    """
    Queries the SOAP API for the applications a given user can access.

    @return {dict} resp
        Contents: 'status', 'message', 'application_list', 'application_count'
    """

    username = str(request.headers['X-Core-Token']).split('-')[0]

    # Send username to SOAP API to retrieve applications from ATMS database.
    atmsdata = soap.ApplicationList(username)

    resp = atmsdata

    return resp
