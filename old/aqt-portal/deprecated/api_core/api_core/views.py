"""
Cornice RESTful API:

This views.py defines several web services that compromise the CORE AQT
Solutions web API.  This API layer will be a unifying layer of all various
interfaces into a single, callable REST web service.

This web service will provide access to:

  - Guacamole MySQL Auth (via the 'guac' module)
  - ATMS SOAP API (via the 'atms' module)

Author: Grant Hulegaard
"""

import os
import binascii
import json

import time
import datetime

from webob import Response, exc
from cornice import Service

# AQT interface modules. (old)
#import atmsdb

# AQT interface modules.
import atms


##
## Variables
##


# Tokens (user-token) data store for login.
_TOKENS = {}


##
## Routes/Definitions
##


# Some more thought is requried for how best to handle versioning API's.  It
# doesn't seem like traditional route prefixing will work with our current nginx
# reverse proxy setup.  (This is due to the multiple 'pserve' instances)
#
route_prefix = ''
#route_prefix = '/api_core/5.2.0'

# CORS policy settings.
# https://cornice.readthedocs.org/en/latest/api.html?highlight=cross%20domain
cors_policy = {
    'origins': ('*',),
    'max_age': 42,
}

# Service definitions

tokens = Service(
    name='tokens', 
    path=str(route_prefix + '/tokens'), 
    description="Stored tokens dump.",
    cors_policy=cors_policy
)

login = Service(
    name='login', 
    path=str(route_prefix + '/login'), 
    description="Login/token management.",
    cors_policy=cors_policy
)

password = Service(
    name='password', 
    path=str(route_prefix + '/password'), 
    description="Password reset and recovery.",
    cors_policy=cors_policy
)

applications = Service(
    name='applications',
    path=str(route_prefix + '/applications'),
    description="Get ATMS applications.",
    cors_policy=cors_policy
)

webrdp = Service(
    name='webrdp', 
    path=str(route_prefix + '/webrdp'), 
    description="Guacamole MySQL interface.",
    cors_policy=cors_policy
)


##
## Helpers
##


#
# General
#

def _create_token():
    """
    Creates random hex for token.
    """
    return binascii.b2a_hex(os.urandom(20))


class _401(exc.HTTPError):
    """
    Not Authorized (Forbidden) error.
    """

    def __init__(self, msg="Unauthorized"):
        body = {'status': 401, 'message': msg}
        Response.__init__(self, json.dumps(body))
        self.status = 401
        self.content_type = 'application/json'


def valid_token(request):
    """
    Checks HTTP request for token and validates.
    """

    header = 'X-Core-Token' # Name of the token header expected.
    token = request.headers.get(header) # Store the token from the request header.

    # If there is no token...
    if token is None:
        # Raise unauthorized class.
        raise _401()

    # Tokens are passed as <user>-<token>.
    # Split token string into a list with two values.
    token = token.split('-')

    # If there are not two values from the split...
    if len(token) != 2:
        # Raise unauthorized class.
        raise _401()

    # Store both values into individual vars for use in _TOKENS dict.
    username, token = token
    
    # Create boolean based on if the user is in the data store and the token
    # assigned to the user is equal to the value given.
    valid = username in _TOKENS and _TOKENS[username] == token

    # If boolean is false (user is NOT in the data store or token does not
    # match)...
    if not valid:
        # Raise unauthorized class.
        raise _401()

    # Set request.validated['user'] object as username.
    request.validated['username'] = username

#
# Login (login)
#

def valid_login(request):
    """
    Checks HTTP request for a username and password field in the body.
    """

    # Try to load request.body
    try:
        payload = json.loads(request.body)
    except ValueError:
        # If problem, return a JSON exception.
        request.errors.add(
            'body', 
            'payload', 
            'Not valid JSON'
        )
        return

    # Check for username field.
    if 'username' not in payload:
        request.errors.add(
            'body', 
            'username', 
            'Missing username.'
        )
        return

    # Check for password field.
    if 'password' not in payload:
        request.errors.add(
            'body', 
            'password', 
            'Missing password.'
        )
        return

    # Set request.validated['payload'] to login dict with {'username': username,
    # 'password': password}
    #
    # request.validated['payload'] -> {'username': username, 'password': password}
    # request.validated['payload']['username'] -> username
    # request.validated['payload']['password'] -> password
    request.validated['payload'] = payload

#
# Password (password)
#

def valid_password_change(request):
    """
    Checks HTTP request for username, old password, and new password in the body.
    """

    # Try to load request.body
    try:
        payload = json.loads(request.body)
    except ValueError:
        # If problem, return a JSON exception.
        request.errors.add(
            'body',
            'JSON Load',
            'Not valid JSON'
        )
        return

    # Check for oldpassword field.
    if 'oldpassword' not in payload:
        request.errors.add(
            'body', 
            'oldpassword', 
            'Missing oldpassword.'
        )
        return    

    # Check for newpassword field.
    if 'newpassword' not in payload:
        request.errors.add(
            'body', 
            'newpassword', 
            'Missing newpassword.'
        )
        return

    request.validated['payload'] = payload

def valid_password_email(request):
    """
    Checks HTTP request for username in the body.
    """

    # Try to load request.body
    try:
        payload = json.loads(request.body)
    except ValueError:
        # If problem, return a JSON exception.
        request.errors.add(
            'body',
            'JSON Load',
            'Not valid JSON'
        )
        return

    # Check for username field.
    if 'username' not in payload:
        request.errors.add(
            'body', 
            'username', 
            'Missing username.'
        )
        return

    request.validated['payload'] = payload


##
## Services
##


#
# Tokens (DEBUG ONLY)
#

@tokens.get()
def get_tokens(request):
    """
    Returns currently stored tokens.
    """
    return _TOKENS

#
# Login (login)(token management)
#

@login.post(validators=valid_login)
def check_login(request):
    """
    Authenticates user against SOAP ValidateLogin method and issues a token if
    successful.
    """

    response = {}

    # Store values that were set by valid_login.
    username = request.validated['payload']['username']
    password = request.validated['payload']['password']


    ## Check ATMS database for user record.

    atmsdata = atms.ValidateLogin(username, password)

    # If ValidateLogin returns fail...
    if atmsdata['status'] != '0':
        # Break processing and return error.
        response = atmsdata
        return response


    ## Create a new user token...
    
    # First remove any previously issued tokens.
    if username in _TOKENS:
        del _TOKENS[username]

    # Create new token.
    token = _create_token()

    # Save user and token combination to _TOKENS dict.
    _TOKENS[username] = token


    ## Return properly formatted X-Core-Token with the response.
    response['token'] = '%s-%s' %(username, token)

    response['status'] = atmsdata['status']
    response['message'] = atmsdata['message']

    return response

@login.delete(validators=valid_token)
def logout(request):
    """
    Removes user and token from authorized data store.
    """

    response = {}

    # Store username to be sent after delete.
    username = request.validated['username']


    ## Remove token from memory.

    del _TOKENS[username]


    ## Return JSON message confirming delete of user.
    response['status'] = '0'
    response['message'] = 'Logout successful.'
    response['username'] = username

    return response

#
# Password Management (password)
#

@password.post(validators=valid_password_email)
def password_email(request):
    """
    Sends a user an e-mail for password recovery.
    """
    
    response = {}

    # Store validated request values.
    username = request.validated['payload']['username']


    ## Send information to SOAP API to try and send e-mail.
    
    atmsdata = atms.EmailPassword(username)

    # If EmailPassword returns fail...
    if atmsdata['status'] != '0':
        # Break processing and return error.
        response = atmsdata
        return response

    # If success...
    response = atmsdata

    return response

@password.put(validators=(valid_token, valid_password_change))
def password_change(request):
    """
    Changes a user's password using the SOAP ChangePassword method.
    """

    response = {}

    # Store validated request values.
    username = request.validated['username']
    oldpassword = request.validated['payload']['oldpassword']
    newpassword = request.validated['payload']['newpassword']


    ## Send information to SOAP API to try and change password in ATMS DB.

    atmsdata = atms.ChangePassword(username, oldpassword, newpassword)

    # If ChangePassword returns fail...
    if atmsdata['status'] != '0':
        # Break processing and return error.
        response = atmsdata
        return response

    # If success...
    response = atmsdata

    return response

#
# Dashboard Apps
#

@applications.post(validators=(valid_token))
def get_applications(request):
    """
    Returns the applications the authorized user can access.
    """

    response = {}

    # Store values that were set by valid_login.
    username = request.validated['username']


    ## Get authorized applications from ATMS database.

    atmsdata = atms.ApplicationList(username)

    # The atms.ApplicationList() handles all the processing, so simply return
    # its response.
    response = atmsdata

    return response
