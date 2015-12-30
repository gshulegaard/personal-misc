"""
Django settings for website project.

For more information on this file, see
https://docs.djangoproject.com/en/1.7/topics/settings/

For the full list of settings and their values, see
https://docs.djangoproject.com/en/1.7/ref/settings/
"""

# Build paths inside the project like this: os.path.join(BASE_DIR, ...)
import os
gettext = lambda s: s
BASE_DIR = os.path.dirname(os.path.dirname(__file__))


# Quick-start development settings - unsuitable for production
# See https://docs.djangoproject.com/en/1.7/howto/deployment/checklist/

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = ')^pm*3%u&_bt-^212!^gy@yg-558xb+8ep*ujccv!#&u7v2gab'

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = True

TEMPLATE_DEBUG = True

ALLOWED_HOSTS = ['members.aqtsolutions.com']


# Application definition

INSTALLED_APPS = (
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'tickets', # Main tickets application.
    'contact', # Contact application.
    'support', # Support application.
    'atms_support', # ATMS Support application (for members).
    'demo', # Demo video application.
    'register', # Register application.
    'download', # Download application.
    'mobile', # Mobile application.
    'aqt_auth', # Web log in/out application.
    'member', # Prospect area application.
    'customer', # Members area application.
    'flipbook', # Flipbook application.
)

MIDDLEWARE_CLASSES = (
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.auth.middleware.SessionAuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
)

AUTHENTICATION_BACKENDS = (
    'django.contrib.auth.backends.ModelBackend',
)

TEMPLATE_LOADERS = (
    'django.template.loaders.filesystem.Loader',
    'django.template.loaders.app_directories.Loader',
    'django.template.loaders.eggs.Loader'
)

TEMPLATE_CONTEXT_PROCESSORS = (
    'django.contrib.auth.context_processors.auth',
    'django.contrib.messages.context_processors.messages',
    'django.core.context_processors.i18n',
    'django.core.context_processors.debug',
    'django.core.context_processors.request',
    'django.core.context_processors.media',
    'django.core.context_processors.csrf',
    'django.core.context_processors.tz',
    'django.core.context_processors.static'
)

TEMPLATE_DIRS = (
    os.path.join(BASE_DIR, 'website', 'templates'),
)

ROOT_URLCONF = 'website.urls'

WSGI_APPLICATION = 'website.wsgi.application'


# Database
# https://docs.djangoproject.com/en/1.7/ref/settings/#databases

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql_psycopg2',
        'NAME': u'aqt-tickets',
        'HOST': u'localhost',
        'USER': u'postgres',
        'PASSWORD': u'postgres',
        'PORT': 5432
    }
}

# Internationalization
# https://docs.djangoproject.com/en/1.7/topics/i18n/

LANGUAGE_CODE = 'en-us'

TIME_ZONE = 'UTC'

USE_I18N = True

USE_L10N = True

USE_TZ = True


# Static files (CSS, JavaScript, Images)
# https://docs.djangoproject.com/en/1.7/howto/static-files/

STATIC_URL = '/static/'
#STATIC_ROOT = os.path.join(BASE_DIR, 'static')
STATIC_ROOT = '/var/opt/aqt-tickets/static/'

STATICFILES_DIRS = (
    os.path.join(BASE_DIR, 'website', 'static'),

    #os.path.join(BASE_DIR, 'website', 'static', 'downloads'),

    # Added this section to allow convenient access to the HTML/CSS template
    # purchased from themeforest.
    os.path.join(BASE_DIR, 'website', 'static', 
                 'themeforest-5045697-astrum-responsive-multipurpose-html5-template',
                 'HTML'),
)

# Custom package settings:

LOGIN_REDIRECT_URL = '/'

LANGUAGES = (
    ## Customize this
    ('en', gettext('en')),
)

# Emails Config (testing password reset and verification)
# http://garmoncheg.blogspot.com.au/2012/07/django-resetting-passwords-with.html

EMAIL_HOST = 'smtp.gmail.com'
EMAIL_PORT = 587
EMAIL_HOST_USER = 'loki.labrys'
EMAIL_HOST_PASSWORD = 'gsh08281991!'
EMAIL_USE_TLS = True
DEFAULT_FROM_EMAIL = 'loki.labrys@gmail.com'

#EMAIL_HOST = 'mail.aqtsolutions.com'
#EMAIL_PORT = 587
#EMAIL_HOST_USER = 'atmsinfo'
#EMAIL_HOST_PASSWORD = 'TESTER999'
#EMAIL_USE_TLS = True
#DEFAULT_FROM_EMAIL = 'atmsinfo@aqtsolutions.com'

# You can run the python development/debugging smtpd server with the following
# command from a terminal:
#     python -m smtpd -n -c DebuggingServer localhost:1025
