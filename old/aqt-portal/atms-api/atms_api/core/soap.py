"""
ATMS SOAP interface:

This library provides access to the ATMS SOAP API coded in PowerBuilder.  While
we are using a SOAP API, we are forced to use a deprecated python SOAP library
like SUDS.  Since SUDS is deprecated/no longer maintened, it supports Python
2.7+ only (i.e. no Python 3.4+ support).

This library will be included in the Core API to be converted into a
consumable RESTful webservice.

Dependencies:
    - SUDS (https://fedorahosted.org/suds/)

Author: Grant Hulegaard
"""

import os
import xml.etree.ElementTree as et

from suds.client import Client

from atms_api.services.config import Config


try:
    client = Client(
        'http://' + 
        Config['atmsapi']['server'] + 
        '/atms_api/atmsapi.asmx?WSDL'
    )
except:
    client = None


#
# Functions
#

def ValidateLogin(username, password):
    """
    Call the ValidateLogin method of the SOAP API to check if a user is
    authorized.

    @param {string} username
    @param {string} password

    @returns {dict}
        Response from the SOAP API.
    """

    from atms_api.core.soap import client

    response = {}

    # Check to see if a SOAP client was downloaded.
    if client == None:
        response['status'] = '-1000'
        response['message'] = 'There was a problem downloading the SOAP API.'
        return response


    ## Retrieve XML

    # Get XML to populate.
    apidata = client.service.processxmldata(
        'ValidateLogin', 
        1
    )

    # If SOAP returns success.
    if apidata['processxmldataResult'] == 0:
        # Load XML into an object using ElementTree.
        rootxml = et.fromstring(apidata['process_data'].encode('utf-16le'))
    else:
        # Break processing.
        response['status'] = str(apidata['processxmldataResult'])
        response['message'] = 'There was an error retrieving the xml structure.'
        return response

    # Fill out XML to be passed to processdata service.
    payload = rootxml.find('ValidateLogin_Row')
    payload.find('Login').text = username
    payload.find('Password').text = password


    ## Validate Login
    
    # Send XML for processing by SOAP API.
    apidata = client.service.processdata(
        Config['atmsapi']['connection'], 
        'ValidateLogin',
        et.tostring(rootxml)
    )

    # If SOAP returns error.
    if (apidata['processdataResult'] != 0 and
        apidata['processdataResult'] != -2):
        # Break processing.
        response['status'] = str(apidata['processdataResult'])
        response['message'] = str(apidata['process_error'])
        return response


    ## Create success response and return it.

    response['status'] = str(apidata['processdataResult'])
    response['message'] = 'User has been successfully validated.'

    return response

def ChangePassword(username, oldpassword, newpassword):
    """
    Call the ChangePassword method of the SOAP API in order to change a user's
    password.  The RESTful web service/SPA front-end should ensure that the
    'newpassword' parameter is repeated twice to prevent typos.

    @param {string} username
    @param {string} oldpassword
    @param {string} newpassword

    @returns {dict}
        Response from the SOAP API.
    """
    
    from atms_api.core.soap import client

    response = {}

    # Check to see if a SOAP client was downloaded.
    if client == None:
        response['status'] = '-1000'
        response['message'] = 'There was a problem downloading the SOAP API.'
        return response
    

    ## Retrieve XML

    # Get XML to populate.
    apidata = client.service.processxmldata(
        'ChangePassword',
        1
    )

    # If SOAP returns success.
    if apidata['processxmldataResult'] == 0:
        # Load XML into an object using ElementTree.
        rootxml = et.fromstring(apidata['process_data'].encode('utf-16le'))
    else:
        # Break processing.
        response['status'] = str(apidata['processxmldataResult'])
        response['message'] = 'There was an error retrieving the xml structure.'
        return response
    
    # Fill out XML to be passed to processdata service.
    payload = rootxml.find('ChangePassword_Row')
    payload.find('Login').text = username
    payload.find('OldPassword').text = oldpassword
    # Note that the two new passwords here are filled from the same passed
    # parameter.  This means that checking to make sure both password fields
    # match should be done on the front-end.
    payload.find('NewPassword1').text = newpassword
    payload.find('NewPassword2').text = newpassword


    ## Change Password

    # Send XML for processing by SOAP API.
    apidata = client.service.processdata(
        Config['atmsapi']['connection'],
        'ChangePassword',
        et.tostring(rootxml)
    )

    # If SOAP returns error.
    if apidata['processdataResult'] != 0:
        # Break processing.
        response['status'] = str(apidata['processdataResult'])
        response['message'] = str(apidata['process_error'])
        return response


    ## Create success response and return it.
    response['status'] = str(apidata['processdataResult'])
    response['message'] = 'Password has been changed successfully.'

    return response

def EmailPassword(username):
    """
    Call the EmailPassword method of the SOAP API to send a user their password
    via e-mail.
    
    @param {string} username
    
    @returns {dict}
        Response from SOAP API.
    """

    from atms_api.core.soap import client

    response = {}
    
    # Check to see if a SOAP client was downloaded.
    if client == None:
        response['status'] = '-1000'
        response['message'] = 'There was a problem downloading the SOAP API.'
        return response


    ## Retrieve XML

    # Get XML to populate.
    apidata = client.service.processxmldata(
        'EmailPassword',
        1
    )

    # If SOAP returns success.
    if apidata['processxmldataResult'] == 0:
        # Load XML into an object using ElementTree.
        rootxml = et.fromstring(apidata['process_data'].encode('utf-16le'))
    else:
        # Break processing.
        response['status'] = str(apidata['processxmldataResult'])
        response['message'] = 'There was an error retrieving the xml structure.'
        return response

    # Fill out XML to be passed to processdata service.
    payload = rootxml.find('EmailPassword_Row')
    payload.find('Login').text = username


    ## E-mail Password

    # Send XML for processing by SOAP API.
    apidata = client.service.processdata(
        Config['atmsapi']['connection'],
        'EmailPassword',
        et.tostring(rootxml)
    )

    # If SOAP returns error.
    if apidata['processdataResult'] != 0:
        # Break processing.
        response['status'] = str(apidata['processdataResult'])
        response['message'] = str(apidata['process_error'])
        return response


    ## Create success response and return it.
    response['status'] = str(apidata['processdataResult'])
    response['message'] = 'Password has been e-mailed successfully.'

    return response

def ApplicationList(username):
    """
    Call the ApplicationList method of the SOAP API to get a list of authorized
    applications.

    @param {string} username

    @returns {dict}
        Response from SOAP API.
    """

    from atms_api.core.soap import client

    response = {}
    
    # Check to see if a SOAP client was downloaded.
    if client == None:
        response['status'] = '-1000'
        response['message'] = 'There was a problem downloading the SOAP API.'
        return response


    ## Retrieve XML

    # Get XML to populate.
    apidata = client.service.processxmlcriteria(
        'ApplicationList',
        1
    )

    # If SOAP returns success.
    if apidata['processxmlcriteriaResult'] == 0:
        # Load xml into an object using ElementTree.
        rootxml = et.fromstring(apidata['process_criteria'].encode('utf-16le'))
    else:
        # Break processing.
        response['status'] = str(apidata['processxmlcriteriaResult'])
        response['message'] = 'There was an error retrieving the xml structure.'
        return response

    # Fill out XML to be passed to processgetdata service.
    payload = rootxml.find('ApplicationList_Row')
    payload.find('Login').text = username


    ## Get application list

    # Send XML for processing by SOAP API.
    apidata = client.service.processgetdata(
        Config['atmsapi']['connection'], 
        'ApplicationList',
        et.tostring(rootxml)
    )

    # If SOAP returns error.
    if apidata['processgetdataResult'] < 0:
        # Break processing.
        response['status'] = str(apidata['processgetdataResult'])
        response['message'] = str(apidata['process_error'])
        return response

    # Load XML into an object using ElementTree.
    rootxml = et.fromstring(apidata['process_data'].encode('utf-16le'))

    application_list = {}

    # Pull out the applications and put them in the response dict to be returned
    # as JSON.
    for app in rootxml.findall('ApplicationList_Row'):
        # Ignore ApplicationID = 3 (MyATMS Mobile)
        if app.find('ApplicationID').text != '3':
            # Initialize the sub dict to avoid a key error.
            application_list[app.find('ApplicationID').text] = {}
            application_list[app.find('ApplicationID').text]['id'] = app.find('ApplicationID').text
            application_list[app.find('ApplicationID').text]['label'] = app.find('ApplicationLabel').text


    ## Create success response and return it.

    response['status'] = '0'
    response['message'] = ("The user's application list has been successfully"
                           " retrieved.")
    response['application_list'] = application_list
    response['application_count'] = str(apidata['processgetdataResult'])

    return response
