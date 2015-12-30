from django.conf import settings # Import settings.py
from django.shortcuts import render
from django.http import HttpResponseRedirect
from django.core.urlresolvers import reverse
from django.template import loader, Context
from django.core.mail import send_mail

from django.core.paginator import Paginator, EmptyPage, PageNotAnInteger
import os
# Required for generating random number for registration form.
from random import randrange

# Load the AQTS API.
from website.api import aqtsclient

import os, re


from flipbook.models import Base, Image, Bullet

## Helpers

def send_register_email(context):
    """
    Send a registration e-mail to atmsinfo@aqtsolutions.com
    """

    # Load template...
    template = loader.get_template('flipbook/email.html')

    # Create template data using Context(context_tuple)...
    c = Context(context)

    # Render the template...
    rendered = template.render(c)

    # Send e-mail to atmsinfo@aqtsolutions.com...
    # Documentation: https://docs.djangoproject.com/en/1.6/topics/email/
    send_mail(
        'New User Registration for Flipbook on aqtsolutions.com', 
        rendered, 
        'atmsinfo@aqtsolutions.com', 
        [
            'atmsinfo@aqtsolutions.com',
            'donaheye@aqtsolutions.com'
        ],
        fail_silently=True
    )


## Views

def flipbook_view(request, url_slug):
    """
    Handle GET/POST requests for users trying to access online flipbooks.
    """

    try:
        # Get object from database corresponding to URL slug regex.
        b = Base.objects.get(slug=url_slug)
    except:
        return render(request, 'flipbook/404.html')

    # Initialize context dictionary.
    context = {
        'url':            b.url,
        'slug':           b.slug,
        'header':         b.header,
        'form_header':    b.form_header,
        'form_button':    b.form_button,
        'intro':          b.intro,
        'bullet_1':       b.bullet_set.all()[0].text,
        'bullet_2':       b.bullet_set.all()[1].text,
        'bullet_3':       b.bullet_set.all()[2].text,
        'image_name':     b.image_set.all()[0].name,
        'title':          b.title,
        'meta_desc':      b.meta_description,
        'og_article_tag': b.og_article_tag
    }

    # If GET...
    if request.method == 'GET':
        ## Generate new security number.
        context.update(
            { 'security_number': randrange(1, 999999+1) }
        )


    #
    # POST processing
    #

    if request.method == 'POST':

        # Catch all POST data...
        context.update(
            {
                'email':       request.POST['email'],
                'password':    '', # Removed password fields, but still need
                                   # empty string for SOAP.
                'fname':       request.POST['fname'],
                'lname':       request.POST['lname'],
                'company':     request.POST['company'],
                'position':    request.POST['position'],
                'phone':       request.POST['phone'],
                'source':      request.POST['source'],
                'subscribe':   request.POST.get('subscribe', False),
                'error_types': []  # List of errors.
            }
        )
        
        # Check if required fields were filled out...
        if (
                context['email']    == '' or 
                context['fname']    == '' or 
                context['lname']    == '' or 
                context['company']  == '' or
                context['position'] == '' or
                context['phone']    == '' or
                context['source']   == ''
        ):
            context['error_types'].append('empty')
            
        # Check if security code was entered correctly...
        if request.POST['security_check'] != request.POST['security_number']:
            # ...if not...add error type...
            context['error_types'].append('security')
            # ...and regenerate number...
            context.update(
                { 'security_number': randrange(1, 999999+1) }
            )

        # Check if there are any errors... 
        if context['error_types'] != []:
            # ...re-render template early with form validation errors.
            return render(request, 'flipbook/view.html', context)
                    

        ## Registration actions
                    
        # Modify 'subscribe' to fit API.
        if context['subscribe'] == True:
            aqtssubscribe = 'Y'
            # We have to create a new variable because we want to pass the
            # proper string back to the template if there is an error.
        else:
            aqtssubscribe = 'N'
                        
        # Insert user registration record into AQTS.
        aqtsresult = aqtsclient.service.insertuserforapproval(
            context['fname'], 
            context['lname'], 
            context['position'], 
            context['email'],
            context['phone'], 
            context['password'], 
            context['company'], 
            aqtssubscribe, 
            context['source']
        )
                        
        # Catch API error...
        if aqtsresult == -1:
            context['error_types'].append('api')
        else:
            # ...if no API error...
            # Send e-mail to atmsinfo@aqtsolutions.com.
            send_register_email(context)

            # Re-direct to flipbook URL.
            return HttpResponseRedirect(context['url'])


    #
    # GET render/POST API error render
    #

    return render(request, 'flipbook/view.html', context)

def flipbook_copy(request, url_slug):
    """
    Display a flipbook creation form with fields filled out with values from
    another flipbook.
    """

    try:
        # Get object from database corresponding to URL slug regex.
        b = Base.objects.get(slug=url_slug)
    except:
        return render(request, 'flipbook/404.html')

    # Initialize context dicitonary.
    context = {
        'url':            b.url,
        'header':         b.header,
        'intro':          b.intro,
        'form_header':    b.form_header,
        'form_button':    b.form_button,
        'slug':           '', # Slug must be unique.
        'url_slug':       url_slug,
        'bullet_1':       b.bullet_set.all()[0],
        'bullet_2':       b.bullet_set.all()[1],
        'bullet_3':       b.bullet_set.all()[2],
        'image_name':     b.image_set.all()[0],
        'title':          b.title,
        'meta_desc':      b.meta_description,
        'og_article_tag': b.og_article_tag,
        'errors':         [],
        'success':        False
    }

    # Return new.html with context dictionary.
    # Future handling will be done by the "new" view.
    return render(request, 'flipbook/new.html', context)

def flipbook_edit(request, url_slug):
    """
    Handle GET/POST requests for edit flipbooks.
    """

    try:
        # Get object form database corresponding to URL slug regex.
        b = Base.objects.get(slug=url_slug)
    except:
        return render(request, 'flipbook/404.html')

    # Initialize context dicitonary.
    context = {
        'url':            b.url,
        'header':         b.header,
        'intro':          b.intro,
        'form_header':    b.form_header,
        'form_button':    b.form_button,
        'slug':           b.slug,
        'url_slug':       url_slug,
        'bullet_1':       b.bullet_set.all()[0],
        'bullet_2':       b.bullet_set.all()[1],
        'bullet_3':       b.bullet_set.all()[2],
        'image_name':     b.image_set.all()[0],
        'title':          b.title,
        'meta_desc':      b.meta_description,
        'og_article_tag': b.og_article_tag,
        'errors':         [],
        'success':        False
    }


    #
    # Authorization check
    #

    # If not logged in...
    if not request.user.is_authenticated():
        # ...redirect to login page.
        return HttpResponseRedirect(reverse('aqt_auth:login_page'))

    # If not admin (AQT employee)...
    if not request.user.is_superuser:
        # ...display flipbook view.
        return HttpResponseRedirect(reverse('flipbook:view', args=[context['slug']]))


    #
    # POST Processing
    #

    # If there is a POST request...
    # http://stackoverflow.com/questions/25252238/django-check-if-form-data-exists-in-request
    if request.method == 'POST':

        ## Catch Delete request
        if 'delete' in request.POST:
            # Save image name...
            image_name = b.image_set.all()[0].name

            # Construct file target...
            image_target = os.path.join(settings.STATIC_ROOT,
                                        'flipbook',
                                        image_name)

            # ...If DEBUG...
            if settings.DEBUG:
                image_target = os.path.join(settings.BASE_DIR,
                                            'flipbook',
                                            'static',
                                            'flipbook',
                                            image_name)

            # Remove record from the database.
            # Record must be removed before image removal to allow for image
            # removal filter check.
            b.delete()

            # If image name is not used for another flipbook...
            if not Image.objects.filter(name=image_name):
                # ...remove the unused image file.
                os.remove(image_target)


            return HttpResponseRedirect(reverse('flipbook:index'))

        ## Catch POST data and overwrites some context
        context['url'] = request.POST['url']
        context['header'] = request.POST['header']
        context['intro'] = request.POST['intro']
        context['form_header'] = request.POST['form_header']
        context['form_button'] = request.POST['form_button']
        context['slug'] = request.POST['slug'].lower()
        context['bullet_1'] = request.POST['bullet_1']
        context['bullet_2'] = request.POST['bullet_2']
        context['bullet_3'] = request.POST['bullet_3']
        context['title'] = request.POST['title']
        context['meta_desc'] = request.POST['meta_desc']
        context['og_article_tag'] = request.POST['og_article_tag']
        
        # If all fields are in the POST request...
        if not (request.POST['url'] and 
                request.POST['header'] and 
                request.POST['intro'] and
                request.POST['form_header'] and
                request.POST['form_button'] and
                request.POST['slug'] and
                request.POST['bullet_1'] and
                request.POST['bullet_2'] and
                request.POST['bullet_3'] and
                request.POST['title'] and
                request.POST['meta_desc'] and
                request.POST['og_article_tag']):
            # ...else add an error type to the errors list.
            context['errors'].append('missing-field')

        # If request.FILES is not empty...
        if request.FILES != {}:
            # WARN: This code assumes that only a single file is in
            # request.FILES.
            
            # Store filename in context
            # http://stackoverflow.com/questions/3111779/how-can-i-get-the-file-name-from-request-files
            context['image_name'] = str(request.FILES[str(request.FILES.keys()[0])].name)
            
            # Create file_target at /var/opt/aqt-tickets/static/flipbook/
            file_target = os.path.join(settings.STATIC_ROOT, 
                                       'flipbook', 
                                       context['image_name'])

            # If DEBUG...
            if settings.DEBUG:
                # ...use the module static directory.
                file_target = os.path.join(settings.BASE_DIR, 
                                           'flipbook', 
                                           'static',
                                           'flipbook',
                                           context['image_name'])
            
        ## Create object

        # If another database record has the desired slug...
        if Base.objects.filter(slug=context['slug']):
            if url_slug != context['slug']:
                # ...add an error type to the errors list.
                context['errors'].append('slug-taken')

        # If the slug is formatted wrong...
        slugPattern = re.compile('[a-z0-9-]+$')
        if slugPattern.match(context['slug']) is None:
            context['errors'].append('slug-misformat')

        ## POST Success

        # If no errors...
        if context['errors'] == []:
            # ...edit DB objects.

            # Base object
            b.url = context['url']
            b.header = context['header']
            b.intro = context['intro']
            b.form_header = context['form_header']
            b.form_button = context['form_button']
            b.slug = context['slug']
            b.title = context['title']
            b.meta_description = context['meta_desc']
            b.og_article_tag = context['og_article_tag']

            # Bullet object(s)
            for index, bullet in enumerate(b.bullet_set.all()):
                bullet.text = context['bullet_' + str(index + 1)]
                bullet.save()

            # If new Image was uploaded...
            if request.FILES != {}:

                for image in b.image_set.all():
                    # Save old name...
                    old_name = image.name
                    
                    # Save new image name.
                    image.name = context['image_name']
                    image.save()

                    # Delete old file...
                    # If image name is not used elsewhere...
                    if not Image.objects.filter(name=old_name):
                        old_file_target = os.path.join(settings.STATIC_ROOT,
                                                       'flipbook',
                                                       old_name)
                    
                        # If DEBUG...
                        if settings.DEBUG:
                            old_file_target = os.path.join(settings.BASE_DIR,
                                                           'flipbook',
                                                           'static',
                                                           'flipbook',
                                                           old_name)
                            
                        # Remove old file...
                        os.remove(old_file_target)

                # Write the new file...
                f = open(file_target, 'w')

                # Write new image file. Iterate over Uploaded Files .chunks()
                # generator.
                # https://docs.djangoproject.com/en/1.8/ref/files/uploads/#django.core.files.uploadedfile.UploadedFile
                for chunk in request.FILES[str(request.FILES.keys()[0])].chunks(chunk_size=1024):
                    f.write(chunk)

                f.close()

            # Save object to database
            b.save()

            # ...return slug edit with success.
            context['success'] = True

            # If slug has changed, then redirect instead.
            if context['url_slug'] != context['slug']:
                return HttpResponseRedirect(
                    reverse('flipbook:edit', args=[context['slug']])
                )
            
            return render(request, 'flipbook/slug_edit.html', context)

    return render(request, 'flipbook/slug_edit.html', context)

def flipbook_new(request):
    """
    Handle GET/POST requests for new flipbooks.
    """

    # Initialize context dictionary.
    context = {
        'url':            '',
        'header':         '',
        'intro':          '',
        'form_header':    '',
        'form_button':    '',
        'slug':           '',
        'bullet_1':       '',
        'bullet_2':       '',
        'bullet_3':       '',
        'image_name':     '',
        'title':          '',
        'meta_desc':      '',
        'og_article_tag': '',
        'errors':         []
    }


    #
    # Authorization check
    #

    # If not logged in...
    if not request.user.is_authenticated():
        # ...redirect to login page.
        return HttpResponseRedirect(reverse('aqt_auth:login_page'))

    # If not admin (AQT employee)...
    if not request.user.is_superuser:
        # ...display 404.
        return render(request, 'flipbook/404.html')


    #
    # POST processing
    #

    # If there is a POST request...
    # http://stackoverflow.com/questions/25252238/django-check-if-form-data-exists-in-request
    if request.method == 'POST':
        ## Catch POST data

        context = {
            'url':            request.POST['url'],
            'header':         request.POST['header'],
            'form_header':    request.POST['form_header'],
            'form_button':    request.POST['form_button'],
            'intro':          request.POST['intro'],
            'slug':           request.POST['slug'].lower(),
            'bullet_1':       request.POST['bullet_1'],
            'bullet_2':       request.POST['bullet_2'],
            'bullet_3':       request.POST['bullet_3'],
            'image_name':     '', # FILES is handled separately.
            'title':          request.POST['title'],
            'meta_desc':      request.POST['meta_desc'],
            'og_article_tag': request.POST['og_article_tag'],
            'errors':         []
        } # This overwrites previously created context dict.

        # If all fields are in the POST request...
        if not (request.POST['url'] and 
                request.POST['header'] and 
                request.POST['form_header'] and
                request.POST['form_button'] and
                request.POST['intro'] and
                request.POST['slug'] and
                request.POST['bullet_1'] and
                request.POST['bullet_2'] and
                request.POST['bullet_3'] and
                request.POST['title'] and
                request.POST['meta_desc'] and
                request.POST['og_article_tag']):
            # ...else add an error type to the errors list.
            context['errors'].append('missing-field')

            
        ## Catch FILES data
        # https://docs.djangoproject.com/en/1.8/ref/request-response/#django.http.HttpRequest.FILES

        # If request.FILES is not empty...
        if request.FILES != {}:
            # WARN: This code assumes that only a single file is in
            # request.FILES.
            
            # Store filename in context
            # http://stackoverflow.com/questions/3111779/how-can-i-get-the-file-name-from-request-files
            context['image_name'] = str(request.FILES[str(request.FILES.keys()[0])].name)
            
            # Create file_target at /var/opt/aqt-tickets/static/flipbook/
            file_target = os.path.join(settings.STATIC_ROOT, 
                                       'flipbook', 
                                       context['image_name'])

            # If DEBUG...
            if settings.DEBUG:
                # ...use the module static directory.
                file_target = os.path.join(settings.BASE_DIR, 
                                           'flipbook', 
                                           'static',
                                           'flipbook',
                                           context['image_name'])
        else:
            # ...else add an error type to the errors list.
            context['errors'].append('missing-file')

        # If another database record has the desired slug...
        if Base.objects.filter(slug=context['slug']):
            # ...add an error type to the errors list.
            context['errors'].append('slug-taken')

        # If the slug is formatted wrong...
        slugPattern = re.compile('[a-z0-9-]+$')
        if slugPattern.match(context['slug']) is None:
            context['errors'].append('slug-misformat')

        ## POST Success

        ## Create object
        # If no errors...
        if context['errors'] == []:
            # ...create new DB objects.

            # Base object
            b = Base.objects.create(url              = context['url'],
                                    header           = context['header'],
                                    intro            = context['intro'],
                                    form_header      = context['form_header'],
                                    form_button      = context['form_button'],
                                    slug             = context['slug'],
                                    title            = context['title'],
                                    meta_description = context['meta_desc'],
                                    og_article_tag   = context['og_article_tag'])

            # Image object
            b.image_set.create(name = context['image_name'])

            # Bullet object(s)
            b.bullet_set.create(text = context['bullet_1'])
            b.bullet_set.create(text = context['bullet_2'])
            b.bullet_set.create(text = context['bullet_3'])

            # Save object to database
            b.save()

            # Create and write the image.
            f = open(file_target, 'w')

            # Write image file. Iterate over Uploaded Files .chunks() generator.
            # https://docs.djangoproject.com/en/1.8/ref/files/uploads/#django.core.files.uploadedfile.UploadedFile
            for chunk in request.FILES[str(request.FILES.keys()[0])].chunks(chunk_size=1024):
                f.write(chunk)

            f.close()

            # ...return success template.
            return render(request, 'flipbook/new_success.html', context)

    #
    # General render handler...
    #

    # Return new.html with context dictionary.
    # This displays on GET request or on POST with errors.
    return render(request, 'flipbook/new.html', context)

def flipbook_index(request):

    #
    # Authorization Check
    #

    # If not logged in...
    if not request.user.is_authenticated():
        # Redirect to pristine log in page, which will display login template.
        return HttpResponseRedirect(reverse('aqt_auth:login_page'))

    # If not superuser...
    if not request.user.is_superuser:
        # Redirect to aqt_login page.
        return HttpResponseRedirect(reverse('flipbook:base'))


 ## Initialize context dictionary
    context = {
        'flipbook':         '',
        'flipbook_count':   '',
        'header':           '',
        'slug':             '',
    }

    if request.method == 'POST':
        context = {
            'header':           request.POST['header'],
            'slug':             request.POST['slug'],
        }

    if 'clear' in request.POST:
        context = {
            'header': '',
            'slug': '',
        }

    flipbook = []

    # Traverse over the various Python lists.
    for f in Base.objects.all():
        # Add flipbook to 'flipbook' dict.
        flipbook.append(f)

    if context['header'] != '':
        search = []
        for i in range(len(flipbook)):
            if flipbook[i].header.lower() == context['header'].lower():
                search.append(flipbook[i])
        flipbook = search

    if context['slug'] != '':
        search2 = []
        for i in range(len(flipbook)):
            if flipbook[i].slug == context['slug'].lower():
                search2.append(flipbook[i])
        flipbook = search2

    # Sort and add flipbook to 'context' dict.
    # We sort the dictionary items into a nested list since dictionaries are
    # inherently non-indexed.
    context.update({'flipbook': sorted(flipbook, key=lambda f: f.id, reverse=True)})

    # Also add the flipbook count
    context.update({'flipbook_count': len(flipbook)})

    # Display flipbook index template.
    return render(request, 'flipbook/index.html', context)

def flipbook_404(request):
    """
    Serve a generic HTTP 404 (not found) template.
    """

    if request.user.is_superuser:
        return HttpResponseRedirect(reverse('flipbook:index'))

    return render(request, 'flipbook/404.html')


""""
    # View for listing flipbook

def listing(request):
    flipbook_list = Base.objects.all()
    paginator =Paginator(flipbook_list, 5) # Show 5 flipbooks per page
    
    page = request.GET.get('page')
    try:
        flipbook_list = paginator.page(page)
    except PageNotAnInteger:
        # If page is not an integer, deliver first page
        flipbook = paginator.page(1)
    except EmptyPage:
        # If page is out of range, deliver last page of results
        flipbook = paginator.page(paginator.num_pages)
        
    return render_to_response('index.html',{"flipbook":flipbook})
"""
