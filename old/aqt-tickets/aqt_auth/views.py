from django.shortcuts import render
from django.http import HttpResponse, HttpResponseRedirect
from django.core.urlresolvers import reverse
from django.template import Context

# Required to manipulate User objects from the database.
from django.contrib.auth.models import User
# Required to authenticate from script.
from django.contrib.auth import authenticate, login, logout
# Required for manually managing User passwords.
from django.contrib.auth.hashers import make_password

# Load the AQTS API.
from website.api import aqtsclient


## Helpers

def login_error(request, context):
    # Dispaly login page with whatever context is passed.
    return render(request, 'aqt_auth/login_page.html', context)


## Views

def login_page(request):
    """
    Display a login screen or redirect if already logged in.
    """

    # If user is logged in...
    if request.user.is_authenticated():
        # Render members area if is_staff else prospect area.
        if request.user.is_staff:
            return HttpResponseRedirect(reverse('customer:customer'))
        else:
            return HttpResponseRedirect(reverse('member:member'))

    # If user is not logged in render login template.
    return render(request, 'aqt_auth/login_page.html')

def aqt_login(request):
    """
    Process the Login request from the Login form on splash.

    During this process, username and e-mail are the same.
    """

    ## Initialization

    # Catch all POST data
    email = request.POST['email']
    splitemail = email.split('@', 1)
    username = splitemail[0]
    password = request.POST['password']

    # Create django password hash.
    djpassword = make_password(password, salt=None, hasher='default')

    # Initialize 'context' dictionary.
    context = {
        'email': email,
        'username': username,
        'password': password,
    }

    # Initialize 'error_types' list.
    # This will only be added to 'context' if there is an error.
    error_types = []


    ## SUDS request to SOAP API to check for user.

    # Query SOAP API...
    # Note that username == e-mail, so this queyr is actually passing an e-mail
    # to the API with the 'tmpusername' variable.
    aqtsresult = aqtsclient.service.authenticateuser(email, password)

    # If query was not a success...
    if aqtsresult.retc != 0:
        # Add error type to list.
        if aqtsresult.retc == -1:
            error_types.append('Retrieval error.')
        elif aqtsresult.retc == -2:
            error_types.append('E-mail not found.')
        elif aqtsresult.retc == -3:
            error_types.append('Password invalid.')
        else:
            error_types.append('Unrecognized error.')

        # Add errors list (list of 1) to 'context' dict.
        context.update({'errors': error_types})

        # Return login template with context (including 'errors' var).
        return login_error(request, context)

    # If query was a success...continue


    ## Insert user record into User tables.

    # Check to see if user already exists...
    if User.objects.filter(id = aqtsresult.aqts_id).exists():
        # Retrieve the user.
        user = User.objects.get(id = aqtsresult.aqts_id)

        # Update user information with information from SOAP request.
        user.username = username[:30]
        user.password = djpassword
        user.email = email
        user.first_name = aqtsresult.first_name
        user.last_name = aqtsresult.last_name

        # Set employee boolean.
        user.is_superuser = aqtsresult.is_employee

        # Set customer boolean.
        user.is_staff = aqtsresult.is_customer

        # Make sure user is active.
        user.is_active = True

        # Save the user class to the database.
        user.save()

    else:
        # Insert a new user.

        # Create a new User object and set as 'newuser'.
        newuser = User.objects.create_user(
            id = aqtsresult.aqts_id,
            username = username[:30],
            password = password,
            email = email,
            first_name = aqtsresult.first_name,
            last_name = aqtsresult.last_name
        )
        
        # Set employee boolean.
        newuser.is_superuser = aqtsresult.is_employee

        # Set customer boolean.
        newuser.is_staff = aqtsresult.is_customer

        # Make sure account is set as active for immediate use.
        newuser.is_active = True

        # Save the newuser class to the database.
        newuser.save()


    ## Log user in.
    ## https://docs.djangoproject.com/en/1.7/topics/auth/default/#auth-web-requests

    authuser = authenticate(username=username[:30], password=password)

    # If there is an authuser...
    if authuser is not None:
        # If the authuser is active...
        if authuser.is_active:
            # Log them in.
            login(request, authuser)
            if authuser.is_staff:
                HttpResponseRedirect(reverse('customer:customer'))
            else:
                HttpResponseRedirect(reverse('member:member'))

    # Redirect back to pristine log in page, which will redirect to the appropriate user page.
    return HttpResponseRedirect(reverse('aqt_auth:login_page'))

def aqt_logout(request):
    """
    Log user out of DjangoSessionMiddleware.
    """
    logout(request)

    return HttpResponseRedirect('http://www.aqtsolutions.com/')
