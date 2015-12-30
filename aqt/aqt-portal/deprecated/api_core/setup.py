import os
from setuptools import setup, find_packages

here = os.path.abspath(os.path.dirname(__file__))

with open(os.path.join(here, 'README.rst')) as f:
    README = f.read()

requires = [
    'pyramid',
    'cornice',
    'waitress',
    'suds',
    'configobj'
]

setup(name='api_core',
      version='2.0.0',
      description='Core RESTful API for AQT Portal.',
      long_description=README, # README file from above
      classifiers=[
          "Programming Language :: Python",
          "Framework :: Pylons",
          "Topic :: Internet :: WWW/HTTP",
          "Topic :: Internet :: WWW/HTTP :: WSGI :: Application"
      ],
      keywords="web services",
      author='Grant Hulegaard',
      author_email='hulegaardg@aqtsolutions.com',
      url='http://www.aqtsolutions.com/',
      packages=find_packages(),
      include_package_data=True,
      zip_safe=False,
      install_requires=requires, # 'requires' list above
      entry_points = """\
      [paste.app_factory]
      main = api_core:main
      """,
      paster_plugins=['pyramid'])
