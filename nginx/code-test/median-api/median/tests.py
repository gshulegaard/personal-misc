"""
tests.py:

Unit tests for median microservice (simple median microservice).
"""

import unittest, time
from collections import deque

from flask import json

import main

class TestMedian(unittest.TestCase):

    def setUp(self):
        main.app.config['TESTING'] = True
        self.app = main.app.test_client()
    
    def clearStream(self):
        """
        Simple helper for clearing the dataStream.
        """
        main.dataStream.clear()
        assert main.dataStream == deque([])        
            
    def testUnixTime(self):
        floatTime = main.unix_time()
        self.failIf(floatTime <= 0)

    def testCleanStream(self):
        main.dataStream.appendleft((1, main.unix_time() - 60000))
        main.cleanStream()
        self.failIf(main.dataStream != deque([]))

    def testPut(self):
        resp = self.app.post("/put", 
                             content_type="application/json", 
                             data='{"intVal": 1}')
        data = json.loads(resp.get_data())

        self.clearStream()

        assert "message" in data
        assert data["message"] == "Integer value accepted."
    
    def testEmpty(self):
        resp = self.app.get("/median")
        data = json.loads(resp.get_data())
        
        assert "message" in data
        assert data["message"] == "No data for the last minute."

    def testExpire(self):
        self.app.post("/put",
                      content_type="application/json",
                      data='{"intVal": 1}')

        print "\nThe next test will take 60 seconds.  Please be patient."
        time.sleep(60)

        resp = self.app.get("/median")
        data = json.loads(resp.get_data())
        
        assert "message" in data
        assert data["message"] == "No data for the last minute."

    def testMassExpire(self):
        for i in range(1,101):
            self.app.post("/put",
                          content_type="application/json",
                          data=('{"intVal": %d}' % i))

        print "\nThe next test will take 60 seconds.  Please be patient."
        time.sleep(60)

        resp = self.app.get("/median")
        data = json.loads(resp.get_data())
        
        assert "message" in data
        assert data["message"] == "No data for the last minute."            

    def testOdd(self):
        self.app.post("/put", 
                      content_type="application/json", 
                      data='{"intVal": 1}')
        
        self.app.post("/put", 
                      content_type="application/json", 
                      data='{"intVal": 2}')

        self.app.post("/put", 
                      content_type="application/json", 
                      data='{"intVal": 3}')

        self.app.post("/put", 
                      content_type="application/json", 
                      data='{"intVal": 4}')

        self.app.post("/put", 
                      content_type="application/json", 
                      data='{"intVal": 5}')

        resp = self.app.get("/median")
        data = json.loads(resp.get_data())

        self.clearStream()

        assert "median" in data
        assert data["median"] == 3

    def testOdd2(self):
        self.app.post("/put", 
                      content_type="application/json", 
                      data='{"intVal": 6}')
        
        self.app.post("/put", 
                      content_type="application/json", 
                      data='{"intVal": 7}')

        self.app.post("/put", 
                      content_type="application/json", 
                      data='{"intVal": 8}')

        self.app.post("/put", 
                      content_type="application/json", 
                      data='{"intVal": 9}')

        self.app.post("/put", 
                      content_type="application/json", 
                      data='{"intVal": 10}')

        resp = self.app.get("/median")
        data = json.loads(resp.get_data())

        self.clearStream()

        assert "median" in data
        assert data["median"] == 8

    def testEven(self):
        self.app.post("/put", 
                      content_type="application/json", 
                      data='{"intVal": 1}')
        
        self.app.post("/put", 
                      content_type="application/json", 
                      data='{"intVal": 2}')

        self.app.post("/put", 
                      content_type="application/json", 
                      data='{"intVal": 3}')

        self.app.post("/put", 
                      content_type="application/json", 
                      data='{"intVal": 4}')

        resp = self.app.get("/median")
        data = json.loads(resp.get_data())

        self.clearStream()

        assert "median" in data
        assert data["median"] == 2.5

    def testEven2(self):
        self.app.post("/put", 
                      content_type="application/json", 
                      data='{"intVal": 6}')
        
        self.app.post("/put", 
                      content_type="application/json", 
                      data='{"intVal": 7}')

        self.app.post("/put", 
                      content_type="application/json", 
                      data='{"intVal": 8}')

        self.app.post("/put", 
                      content_type="application/json", 
                      data='{"intVal": 9}')

        resp = self.app.get("/median")
        data = json.loads(resp.get_data())
        
        self.clearStream()

        assert "median" in data
        assert data["median"] == 7.5

    def test100(self):
        for i in range(1,101):
            self.app.post("/put",
                          content_type="application/json",
                          data=('{"intVal": %d}' % i))
            
        resp = self.app.get("/median")
        data = json.loads(resp.get_data())

        self.clearStream()

        assert "median" in data
        assert data["median"] == 50.5

    def test99(self):
        for i in range(1,100):
            self.app.post("/put",
                          content_type="application/json",
                          data=('{"intVal": %d}' % i))
            
        resp = self.app.get("/median")
        data = json.loads(resp.get_data())

        self.clearStream()

        assert "median" in data
        assert data["median"] == 50

if __name__ == "__main__":
    unittest.main()
