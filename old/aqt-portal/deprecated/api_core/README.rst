================
Core RESTful API
================

:Authors:
   Grant Hulegaard
:Developers:
   Grant Hulegaard,
   Matthew Fay
:Release:
   0.2.0
:Release-Date:
   02/15/2015
:Last-Edited:
   01/29/2015

``api_core`` is the first, primary RESTful API for the AQT Portal web
application.  This document outlines and describes the various components of the
API.

Contents
--------

#. `Modules`_
#. `Helpers`_
#. `Services`_
#. `atmsdb.py`_
#. `guacdb.py`_
#. `settings.py`_
#. `cURL testing`_


----


Footnotes:
  Footnotes denoted by ``[#]`` will be included at the bottom of the section
  they are referenced in.  For example there is a footnote section at the bottom
  of "Installation".



=======
Modules
=======

``api_core/views.py``:
  This is the primary Cornice module.  This module registers the services,
  defines the helpers, and contains the service logic.  Ultimately, the JSON
  documents returned by the various services are defined here.

``api_core/atmsdb.py``:
  This is a module for utilizing ``pymssql`` to establish direct connections to
  the ATMS SQL Server database.

``api_core/guacdb.py``:
  This is a module for using ``pymysql`` to establish direct connections to the
  Guacamole MySQL database.  This module contains functions for managing
  connections and users in Guacamole.

``api_core/settings.py``:
  This is a basic settings file.  It contains some configuration details for the
  particular AQT Portal installation.  For now, until a more robust solution can
  be integrated, this is where database information, version, etc. is stored.


----


Back to `Modules`_.

Back to `Contents`_.



=======
Helpers
=======


----


Back to `Helpers`_.

Back to `Contents`_.



========
Services
========


----


Back to `Services`_.

Back to `Contents`_.



=========
atmsdb.py
=========


----


Back to `atmsdb.py`_.

Back to `Contents`_.



=========
guacdb.py
=========


----


Back to `guacdb.py`_.

Back to `Contents`_.



===========
settings.py
===========


----


Back to `settings.py`_.

Back to `Contents`_.



============
cURL testing
============

Here is a series of cURL commands used to test ``api_core`` (running Linux)::

  # Test if token authorization is working.
  $ curl http://localhost:8000/login
  {"status": 401, "message": "Unauthorized"}


  # Test if you can login with a valid login.
  $ curl -X POST http://localhost:8000/login -H "Content-Type: \
  application/json" -d '{"username":"admin","password":"admin"}'

  {"token": "admin-23d2e895490cc0d2c5cbf7963f96a6d517067c17"}


  # Test if you can return the applications you can access.
  $ curl -X GET http://localhost:8000/login -H "Content-Type: \
  application/json" -H "X-Core-Token: \
  admin-23d2e895490cc0d2c5cbf7963f96a6d517067c17" -d \
  '{"username":"admin","password":"admin"}'

  {"ATMS Web": "atms_web", "ATMS Mobile": "atms_mobile", "ATMS Connect": \
  "atms_connect", "ATMS": "atms"}


  # Test if you can insert a new Guacamole connection.
  $ curl -X POST http://localhost:8000/webrdp -H "Content-Type: \
  application/json" -H "X-Core-Token: \
  admin-23d2e895490cc0d2c5cbf7963f96a6d517067c17" -d \
  '{"password":"admin","app_name":"atms","connection_tag":"adminATMS"}'

  {"connection_id": 63}


  # Test if you can delete the Guacamole connections associated with your user.
  $ curl -X DELETE http://localhost:8000/webrdp -H "X-Core-Token: \
  admin-23d2e895490cc0d2c5cbf7963f96a6d517067c17"

  {"message": "Success", "result": "0"}


  # Test if you can revoke the authentication token for your user.
  $ curl -X DELETE http://localhost:8000/login -H "X-Core-Token: \
  admin-23d2e895490cc0d2c5cbf7963f96a6d517067c17"

  {"Goodbye": "admin"}

For Windows cURL, you will need to adjust the commands to be like this::

  # Test login authentication
  curl -X POST http://localhost:8000/login -H "Content-Type: application/json" \
  -d "{\"username\":\"admin\",\"password\":\"admin\"}"

----


Back to `cURL testing`_.

Back to `Contents`_.
