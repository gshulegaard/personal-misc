from django.shortcuts import render
from django.template import loader, Context
from django.core.mail import send_mail

## Helper
def send_contact_email(context):
    """
    Send a contact e-mail to atmsinfo@aqtsolutions.com.
    """

    # Load template...
    template = loader.get_template('contact/contact_email.html')

    # Create template data using Context(context_tuple).
    c = Context(context)

    # Render the template.
    rendered = template.render(c)

    # Send e-mail to atmsinfo@aqtsolutions.com...
    # Documentation: https://docs.djangoproject.com/en/1.6/topics/email/
    send_mail(
        'Contact message from aqtsolutions.com',
        rendered,
        context['email'],
        [
            'atmsinfo@aqtsolutions.com',
        ],
        fail_silently=True
    )

def contact(request):
    """
    Display a Contact form and send an e-mail to atmsinfo@aqtsolutions.com.
    """
    
    ## Initialize

    context = {
        'fname': '',
        'lname': '',
        'email': '',
        'company': '',
        'position': '',
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
                'position': request.POST['position'],
                'message': request.POST['message'],
            }
        )

        if (context['fname'] == '' or
            context['lname'] == '' or
            context['email'] == '' or
            context['company'] == '' or
            context['position'] == '' or
            context['message'] == ''
        ):
            context.update({'error': 'Empty'})
            return render(request, 'contact/contact.html', context)

        send_contact_email(context)

        return render(request, 'contact/contact_success.html')


    return render(request, 'contact/contact.html', context)
