"""
Configuration Loader:

This module loads and serves a settings.ini for use throughout the atms_api
Flask application.

Dependencies:
    - configobj (http://www.voidspace.org.uk/python/configobj.html#getting-started)

Author: Grant Hulegaard
"""

import os
from configobj import ConfigObj

DEBUG = False

# Import settings.ini that lives in /etc/aqt-portal in production.
Config = ConfigObj('/etc/aqt-portal/settings.ini')

# Check to see if the configuration was properly loaded.
if 'atmsapi' not in Config:
    # If not, try to load the development .ini.
    MODULE_DIR = os.path.abspath(os.path.dirname(__file__))
    Config = ConfigObj(os.path.join(MODULE_DIR, '../../settings.ini'))

    # If the fallback had to be used, flip DEBUG to true.
    DEBUG = True
