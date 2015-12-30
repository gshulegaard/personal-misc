from django.shortcuts import render
from django.http import HttpResponseRedirect
from  django.core.urlresolvers import reverse

def customer(request):
    # Redirect to prospects' area
    if request.user.is_authenticated():
        if request.user.is_staff:
            # Redirect to customers' area
            return render(request, 'customer/members.html')

    return HttpResponseRedirect(reverse('aqt_auth:login_page'))
