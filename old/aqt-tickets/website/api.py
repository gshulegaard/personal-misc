# Import settings to check DEBUG status.
from django.conf import settings

# Required for interacting with SOAP AQTS API.
from suds.client import Client

#
# AQT Services SOAP API (AQTS API)
#

# Set SOAP API url.

# Internal url.
devURL = 'http://tsone/aqts_api/n_aqts_api.asmx?WSDL'
# External IP address.
prodURL = 'http://69.170.22.187/aqts_api/n_aqts_api.asmx?WSDL'

# Initialize SOAP client.
if settings.DEBUG:
    # If DEBUG is "true" (e.g. Development) then initiate SOAP connection using
    # internal URL.
    aqtsclient = Client(devURL)
else:
    # If not (e.g. Production) then initiate SOAP connection using external IP.
    aqtsclient = Client(prodURL)
