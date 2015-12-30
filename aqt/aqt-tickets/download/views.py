from django.http import HttpResponse, HttpResponseRedirect
from django.core.urlresolvers import reverse

import os
from django.conf import settings

# Required to manipulate User objects from the database.
from django.contrib.auth.models import User
# Required to authenticate from script.
from django.contrib.auth import authenticate
# Required for manually managing User passwords.

def download(request):
    """
    Serve a static file for download to an anonymous client.
    """

    filename = request.GET['filename']
    folder = request.GET['folder']
    contenttype = request.GET['type']

    file_obj = open(
        os.path.join(
            settings.STATIC_ROOT, 
            'downloads', 
            folder, 
            filename
        )
    ).read()

    response = HttpResponse(file_obj, content_type=contenttype)
    response['Content-Disposition'] = 'attachment; filename="%s"' % filename

    return response


def download_secure(request):
    """
    Serve a static file for download to an authenticated client.
    """

    ## Check to make sure user is logged in.

    # If not logged in...
    if not request.user.is_authenticated():
        # Redirect to pristine log in page, which will display login template.
        return HttpResponseRedirect(reverse('aqt_auth:login_page'))

    filename = request.GET['filename']
    folder = request.GET['folder']
    contenttype = request.GET['type']

    file_obj = open(
        os.path.join(
            settings.STATIC_ROOT, 
            'downloads', 
            folder, 
            filename
        )
    ).read()

    response = HttpResponse(file_obj, content_type=contenttype)
    response['Content-Disposition'] = 'attachment; filename="%s"' % filename

    return response
