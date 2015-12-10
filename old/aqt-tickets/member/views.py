from django.shortcuts import render
from django.http import HttpResponseRedirect
from  django.core.urlresolvers import reverse

def member(request):
    # Redirect to prospects' area
    if request.user.is_authenticated():
        if not request.user.is_staff:
            return render(request, 'member/prospect.html')

    return HttpResponseRedirect(reverse('aqt_auth:login_page'))
