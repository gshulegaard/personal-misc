from django.shortcuts import render
from django.http import HttpResponseRedirect
from django.core.urlresolvers import reverse


def demo_video(request):
    """
    Serve HTML5 video player page to client if logged in.
    """

    # If not logged in...
    if not request.user.is_authenticated():
        # Redirect to pristine log in page, which will display login template.
        return HttpResponseRedirect(reverse('aqt_auth:login_page'))

    return render(request, 'demo/demo.html')


def demo_mobile(request):
    """
    Mobile Demo page with .plist and .apk for download with instructions.
    """

    ## No authentication since this is for demo purposes.

    return render(request, 'demo/mobile_demo.html')
