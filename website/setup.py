"""
Simple setup.py file for website Flask application.
"""

import os
from setuptools import setup, find_packages

here = os.path.abspath(os.path.dirname(__file__))

with open(os.path.join(here, 'README.rst')) as f:
    README = f.read()

requires = [
    'Flask',
    'uwsgi'
]

setup(
    name='website',
    version='0.1.4', # Major.Minor.Patch
    description='Personal website for gshulegaard.',
    long_description=README,
    packages=find_packages(), # Use setuptools to auto-find packages
    include_package_data=True, # Include static files from MANIFEST.in
    zip_safe=False,
    install_requires=requires
)
