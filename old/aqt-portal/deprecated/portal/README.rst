==================
Portal EmberJS App
==================

:Authors:
   Grant Hulegaard
:Developers:
   Grant Hulegaard,
   Matthew Fay
:Release:
   0.2.0
:Release-Date:
   03/30/2015
:Last-Edited:
   02/20/2015

``portal`` is the first, primary EmberJS application for the AQT Portal web
application.  This document outlines and describes the various components of the
project.

Contents
--------

#. `Components`_


----


Footnotes:
  Footnotes denoted by ``[#]`` will be included at the bottom of the section
  they are referenced in.  For example there is a footnote section at the bottom
  of "Installation".



==========
Components
==========

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


Back to `Components`_.

Back to `Contents`_.



=======
Helpers
=======


----


Back to `Helpers`_.

Back to `Contents`_.
