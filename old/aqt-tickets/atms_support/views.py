from django.shortcuts import render
from django.http import HttpResponseRedirect
from django.core.urlresolvers import reverse
from django.template import loader, Context
from django.core.mail import send_mail

## Helper
def send_atms_support_email(context):
    """
    Send a support e-mail to atmssupport@aqtsolutions.com.
    """

    # Load template...
    template = loader.get_template('atms_support/atms_support_contact_email.html')

    # Create template data using Context(context_tuple).
    c = Context(context)

    # Render the template.
    rendered = template.render(c)

    # Send e-mail to atmsinfo@aqtsolutions.com...
    # Documentation: https://docs.djangoproject.com/en/1.6/topics/email/
    send_mail(
        'ATMS Support Request from aqtsolutions.com',
        rendered,
        context['email'],
        [
            'atmssupport@aqtsolutions.com',
        ],
        fail_silently=True
    )

def atms_support(request):
    """
    Display a Support Contact form and send an e-mail to atmssupport@aqtsolutions.com.
    """

    ## Check to make sure user is logged in.

    # If not loggged in...
    if not request.user.is_authenticated():
        return HttpResponseRedirect(reverse('aqt_auth:aqt_login'))
    else:
        # If not customer...
        if not request.user.is_staff:
            return HttpResponseRedirect(reverse('support:support'))
    
    ## Initialize

    context = {
        'fname': '',
        'lname': '',
        'email': '',
        'company': '',
        'message': '',
    }


    ## If there is a POST request.

    # http://stackoverflow.com/questions/25252238/django-check-if-form-data-exists-in-request
    if request.method == 'POST':

        context.update(
            {
                'fname': request.POST['fname'],
                'lname': request.POST['lname'],
                'email': request.POST['email'],
                'company': request.POST['company'],
                'message': request.POST['message'],
            }
        )

        if (context['fname'] == '' or
            context['lname'] == '' or
            context['email'] == '' or
            context['company'] == '' or
            context['message'] == ''
        ):
            context.update({'error': 'Empty'})
            return render(request, 'atms_support/atms_support_contact.html', context)

        send_atms_support_email(context)

        return render(request, 'atms_support/atms_support_contact_success.html')


    return render(request, 'atms_support/atms_support_contact.html', context)
