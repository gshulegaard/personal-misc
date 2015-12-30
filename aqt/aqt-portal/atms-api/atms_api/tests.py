"""
atms-api.tests.py:

Unit tests for the atms-api Flask application.

Author: Grant Hulegaard
"""

import unittest

from flask import json

import atms_api.main
from atms_api.services.auth import AuthFactory
from atms_api.services.config import Config


class TestAtmsApi(unittest.TestCase):

    def setUp(self):
        atms_api.main.app.config['TESTING'] = True
        self.app = atms_api.main.app.test_client()
        self.auth = AuthFactory()
        self.Config = Config
        
        # Define user account to use for testing.
        self.username = "admin"
        self.password = "admin"

        # Set-up/register a new username/token with AuthFactory.
        self.token = self.auth.new(self.username)

    def testSetUp(self):
        """
        Test the set up of the test client before proceeding.
        """
        assert self.app
        assert self.auth
        assert self.Config
        assert self.username
        assert self.password
        assert self.token
        assert self.auth.check(self.username, self.token)
    
    #
    # Main Tests
    #

    def testStatus(self):
        """
        Simple starter test to make sure the main app definition is responding.
        """

        resp = self.app.get("/status")

        data = json.loads(resp.get_data())

        assert "status" in data
        assert "message" in data
        assert data["status"] == "0"

    #
    # Core Tests
    #

    def testCoreStatus(self):
        """
        Simple test to make sure api_core blue print was registered.
        """

        resp = self.app.get("/core/status")

        data = json.loads(resp.get_data())
        
        assert "status" in data
        assert "message" in data

    def testCoreConfig(self):
        """
        Test the configuration route.
        """

        resp = self.app.get("/core/config",
                            headers={"X-Core-Token": "%s-%s" % 
                                     (self.username, self.token)})

        data = json.loads(resp.get_data())

        assert "atmsapi" in data
        assert "webrdp" in data

    def testCoreLoginDelete(self):
        """
        Since there was a login registered during initialization, test the log
        out functionality first.
        """

        resp = self.app.delete("/core/login",
                               headers={"X-Core-Token": "%s-%s" % 
                                        (self.username, self.token)})
        
        data = json.loads(resp.get_data())

        assert "status" in data
        assert "message" in data
        assert "username" in data
        assert data["status"] == "0"
        assert data["username"] == "admin"

    def testCoreLoginPost(self):
        """
        Re-login and verify new credentials.
        """

        jsonData = str(
            {
                "username": self.username, 
                "password": self.password
            }
        )

        resp = self.app.post("/core/login",
                             content_type="application/json",
                             data=jsonData.replace("'",'"'))

        data = json.loads(resp.get_data())

        self.token = data["token"].split("-")[1]

        assert "status" in data
        assert "message" in data
        assert "token" in data
        assert self.auth.check(self.username, self.token)

    def testCorePasswordPost(self):
        """
        Test password recovery.
        """

        jsonData = str(
            {
                "username": self.username,
            }
        )
        resp = self.app.post("/core/password",
                             content_type="application/json",
                             data=jsonData.replace("'",'"'))

        data = json.loads(resp.get_data())

        assert "status" in data
        # Can't check status code because admin user is not configured for
        # e-mailing in test DB.
        assert "message" in data

    def testCorePasswordPut(self):
#        """
#        Test password change.
#        """
        
        jsonData = str(
            {
                "username": self.username,
                "oldpassword": self.password,
                "newpassword": "newpass"
            }
        )

        resp = self.app.put("/core/password",
                            content_type="application/json",
                            headers={"X-Core-Token": "%s-%s" %
                                     (self.username, self.token)},
                            data=jsonData.replace("'",'"'))

        data = json.loads(resp.get_data())

        assert "status" in data
        assert data["status"] == "0"
        assert "message" in data

    def testCorePasswordPut2(self):
        """
        Revert the password change in the previous test.
        """

        jsonData = str(
            {
                "username": self.username,
                "oldpassword": "newpass",
                "newpassword": self.password
            }
        )

        resp = self.app.put("/core/password",
                            content_type="application/json",
                            headers={"X-Core-Token": "%s-%s" %
                                     (self.username, self.token)},
                            data=jsonData.replace("'",'"'))

        data = json.loads(resp.get_data())

        assert "status" in data
        assert data["status"] == "0"
        assert "message" in data

    def testCoreApplicationsGet(self):
        """
        Test the retrieval of a list of applications.
        """

        resp = self.app.get("/core/applications",
                               headers={"X-Core-Token": "%s-%s" % 
                                        (self.username, self.token)})
        
        data = json.loads(resp.get_data())

        assert "status" in data
        assert data["status"] == "0"
        assert "message" in data
        assert "application_list" in data
        assert "application_count" in data


if __name__ == "__main__":
    unittest.main()
