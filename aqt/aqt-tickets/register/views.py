from django.shortcuts import render
from django.template import loader, Context
from django.core.mail import send_mail

# Required for generating random number for registration form.
from random import randrange

# Load the AQTS API.
from website.api import aqtsclient

## Helpers
def send_register_email(context):
    """
    Send a registration e-mail to atmsinfo@aqtsolutions.com
    """

    # Load template...
    template = loader.get_template('register/new_registration_email.html')

    # Create template data using Context(context_tuple)...
    c = Context(context)

    # Render the template...
    rendered = template.render(c)

    # Send e-mail to atmsinfo@aqtsolutions.com...
    # Documentation: https://docs.djangoproject.com/en/1.6/topics/email/
    send_mail(
        'New User Registration on aqtsolutions.com', 
        rendered, 
        'atmsinfo@aqtsolutions.com', 
        [
            'atmsinfo@aqtsolutions.com',
            'donaheye@aqtsolutions.com'
        ],
        fail_silently=True
    )

def register_error(request, error_types, context):
    """
    Render register.html with errors.  Also, regenerate the security number.

    This is required simply to regenerate the security_number.
    """
    
    # Generate a random number for the security field.
    security_number = randrange(1, 999999+1)
    
    # Update the context dict with additional values.
    context.update({'security_number': security_number, 'errors': error_types})

    return render(request, 'register/register.html', context)

def register(request):
    """
    Display registration form.
    """

    # Generate a random number for the security field.
    security_number = randrange(1, 999999+1)

    # Create a context dict to pass the security_number to the template.
    context = {'security_number': security_number}

    return render(request, 'register/register.html', context)


def register_send(request):
    """
    Catch and process registration form data by sending an e-mail to
    atmsinfo@aqtsolutions.com.
    """

    ## Initialization

    # Catch all POST data
    email = request.POST['email']

    # Removed password fields, but still need to pass empty string to SOAP.
    password = ''

    fname = request.POST['fname']
    lname = request.POST['lname']
    company = request.POST['company']
    position = request.POST['position']
    phone = request.POST['phone']

    source = request.POST['source']

    security_check = request.POST['security_check']
    security_number = request.POST['security_number']

    subscribe = request.POST.get('subscribe', False)

    # Define context variable to save values between loads.
    context = {
        'email': email,
        'fname': fname, 
        'lname': lname, 
        'company': company,
        'position': position,
        'phone': phone,
        'source': source,
        'subscribe': subscribe,
    }


    ## Error Checking

    # Initialize error_type list...
    error_types = []

    # Check if required fields were filled out...
    if (
            email == '' or 
            fname == '' or 
            lname == '' or 
            company == '' or
            position == '' or
            phone == '' or
            source == ''
    ):
        error_types.append('empty')

    # Check if security code was entered correctly...
    if security_check != security_number:
        error_types.append('security')

    # Check if there are any errors, if there are call error()
    if error_types != []:
        return register_error(request, error_types, context)


    ## Registration actions

    # Modify 'subscribe' to fit API.
    if subscribe == True:
        aqtssubscribe = 'Y'
    else:
        aqtssubscribe = 'N'

    # Insert user registration record into AQTS.
    aqtsresult = aqtsclient.service.insertuserforapproval(
        fname, 
        lname, 
        position, 
        email,
        phone, 
        password, 
        company, 
        aqtssubscribe, 
        source)

    # Catch API error...
    if aqtsresult == -1:
        error_types.append('api')
        return register_error(request, error_types, context)

    # If no API error...

    # Send e-mail to atmsinfo@aqtsolutions.com...
    send_register_email(context)


    # If the view hasn't exited earlier...return success template.
    return render(request, 'register/register_success.html')
