from django.shortcuts import render

def mobile(request):
    """
    Mobile download page with .plist and .apk for download with instructions.
    """

    ## No authentication since customers will want to point their instructors to
    ## this page.

    return render(request, 'mobile/mobile.html')
