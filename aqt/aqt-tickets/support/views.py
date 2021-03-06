from django.shortcuts import render
from django.template import loader, Context
from django.core.mail import send_mail

## Helper
def send_support_email(context):
    """
    Send a support e-mail to atmsinfo@aqtsolutions.com.
    """

    # Load template...
    template = loader.get_template('support/support_contact_email.html')

    # Create template data using Context(context_tuple).
    c = Context(context)

    # Render the template.
    rendered = template.render(c)

    # Send e-mail to atmsinfo@aqtsolutions.com...
    # Documentation: https://docs.djangoproject.com/en/1.6/topics/email/
    send_mail(
        'Contact Support Request from aqtsolutions.com',
        rendered,
        context['email'],
        [
            'atmssupport@aqtsolutions.com',
        ],
        fail_silently=True
    )

def support(request):
    """
    Display a Support Contact form and send an e-mail to atmssupport@aqtsolutions.com.
    """
    
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
            return render(request, 'support/support_contact.html', context)

        send_support_email(context)

        return render(request, 'support/support_contact_success.html')


    return render(request, 'support/support_contact.html', context)
