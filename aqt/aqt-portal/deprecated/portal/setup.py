import os

from setuptools import setup, find_packages

here = os.path.abspath(os.path.dirname(__file__))
with open(os.path.join(here, 'README.rst')) as f:
    README = f.read()
with open(os.path.join(here, 'CHANGES.txt')) as f:
    CHANGES = f.read()

requires = [
    'pyramid',
    'pyramid_chameleon',
    'pyramid_debugtoolbar',
    'pyramid_jinja2',
    'waitress',
    ]

setup(name='portal',
      version='0.2.0',
      description='Primary EmberJS application (Portal).',
      long_description=README + '\n\n' + CHANGES,
      classifiers=[
        "Programming Language :: Python",
        "Framework :: Pyramid",
        "Topic :: Internet :: WWW/HTTP",
        "Topic :: Internet :: WWW/HTTP :: WSGI :: Application",
        ],
      author='Grant Hulegaard',
      author_email='hulegaardg@aqtsolutions.com',
      url='http://www.aqtsolutions.com/',
      keywords='web pyramid pylons',
      packages=find_packages(),
      include_package_data=True,
      zip_safe=False,
      install_requires=requires, # 'requires' list above
      tests_require=requires,
      test_suite="portal",
      entry_points="""\
      [paste.app_factory]
      main = portal:main
      """,
      )
