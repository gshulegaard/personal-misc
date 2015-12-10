"""
Validators:

This validators.py module contains the validation decorators used throught the
atms_api flask application.

flask.pocoo.org/docs/0.10/patterns/viewdecorators/

Author: Grant Hulegaard
"""

from functools import wraps
from flask import abort, request

#
# Validators
#

def login_required(f):
    # Instantiate local AuthFactory for portability.
    from atms_api.services.auth import AuthFactory
    auth = AuthFactory()

    @wraps(f)
    def decorated_function(*args, **kwargs):
        # Read the Authorization token.
        if 'X-Core-Token' in request.headers:
            username, token = str(request.headers['X-Core-Token']).split('-')
        else:
            # Abort with 401 if no token sent.
            abort(401)

        # If username not in _TOKENS, or stored token doesn't match...
        if not auth.check(username, token):
            # Abort with 401
            abort(401)

        return f(*args, **kwargs)

    return decorated_function

def login_post_validator(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        # Check to see if the required fields are in the HTTP JSON doc.
        if ('username' not in request.json or 
            'password' not in request.json):
            abort(400)

        return f(*args, **kwargs)

    return decorated_function

def password_post_validator(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        # Check to see if the required fields are in the HTTP JSON doc.
        if ('username' not in request.json):
            abort(400)

        return f(*args, **kwargs)

    return decorated_function

def password_put_validator(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        # Check to see if the required fields are in the HTTP JSON doc.
        if ('oldpassword' not in request.json or
            'newpassword' not in request.json):
            abort(400)
            
        return f(*args, **kwargs)

    return decorated_function
