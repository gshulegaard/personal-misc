"""
Simple setup.py file for atms_api Flask application.
"""

import os
from setuptools import setup, find_packages

requires = [
    'Flask',
    'flask-cors',
    'uwsgi'
]

setup(
    name='median-api',
    version='0.1.0', # Major.Minor.Patch
    description='RESTful webservice API for returning the median of the datastream for the last minute.',
    packages=find_packages(), # Use setuptools to auto-find packages
    include_package_data=True, # Include static files from MANIFEST.in
    zip_safe=False,
    install_requires=requires
)
