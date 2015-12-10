"""
Authentication Service:

This module maintains a TOKENS dictionary object for managing authorization
within the atms_api flask application.  This module also exposes methods for
interacting with the TOKENS dictionary.

Author: Grant Huleagard
"""

import os
import binascii


class AuthFactory:
    """
    Authentication manager class.  This class instantiates a shared dictionary
    that can be accessed/manipulated using the provided services.
    """

    _TOKENS = {} # Class variable that is shared by all instances.

    def _create_token(self):
        """
        Creates a random hex to be paired with a valid user authentication event.
        This username-token combination will be stored in TOKENS and used as an
        authorization reference.
        
        @return {string}
            Randomly generated hexadecimal string.
        """

        return binascii.b2a_hex(os.urandom(20))

    def new(self, username):
        """
        Inserts (or overwrites) a username and token into the TOKEN store.
        
        @param {string} username

        @returns {string} token
            The new token assigned to the user.
        """

        self._TOKENS[username] = self._create_token()

        return self._TOKENS[username]

    def delete(self, username):
        """
        Deletes a user entry from the TOKENS store.
        
        @param {string} username
        """
    
        del self._TOKENS[username]

    def check(self, username, token):
        """
        Validates passed username and token against the _TOKENS store.

        @param {string} username
        @param {string} token

        @returns {bool}
            True if username/token pair is found.  False if not/not matching.
        """

        if username in self._TOKENS:
            if self._TOKENS[username] == token:
                return True

        return False
