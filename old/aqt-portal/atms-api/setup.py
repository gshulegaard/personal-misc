"""
Simple setup.py file for atms_api Flask application.
"""

import os
from setuptools import setup, find_packages

here = os.path.abspath(os.path.dirname(__file__))

with open(os.path.join(here, 'README.rst')) as f:
    README = f.read()

requires = [
    'Flask-cors',
    'Flask',
    'uwsgi',
    'configobj',
    'suds'
]

setup(
    name='atms-api',
    version='2.1.0', # Major.Minor.Patch
    description='RESTful webservice API used by the AQT Portal application.',
    long_description=README,
    packages=find_packages(), # Use setuptools to auto-find packages
    include_package_data=True, # Include static files from MANIFEST.in
    zip_safe=False,
    install_requires=requires
)
