from django.shortcuts import render
from django.http import HttpResponseRedirect
from django.core.urlresolvers import reverse

# Load the AQTS API.
from website.api import aqtsclient

## Helpers
def ticket_edit(request, ticket_id):
    """
    Handle POST requests from 'ticket_detail.html' template.
    """

    ## Initialize

    context = {
        'issue_id': ticket_id,
        'errors': False,
    }

    # If POST request is for 'addticketresponse'...
    if request.POST.get('action', False):
        response_text = request.POST['new_response_text']
        customer_id = request.user.id
        issue_id = ticket_id
        
        aqtsresult = aqtsclient.service.addticketresponse(
            issue_id,
            customer_id, 
            response_text
        )
        
        # If client.service call was not a success...
        if aqtsresult.retc != 0:
            context['errors'] = True
    # Else POST request is for 'editticket'...
    else:
        # Retrieve current ticket information
        aqtsresult = aqtsclient.service.viewticketdetail(ticket_id)

        # Set the context to current information since our submitted form will
        # only have 'issue_type' and 'priority'.
        context.update(
            {
                'ticket_number': aqtsresult.ticket_number,
                'reported_by': aqtsresult.reported_by,
                'reported_date': aqtsresult.reported_date,
                'assigned_to': aqtsresult.assigned_to,
                'issue_type': aqtsresult.issue_type,
                'priority': aqtsresult.priority,
                'product': aqtsresult.product,
                'release': aqtsresult.release,
                'description': aqtsresult.description,
            }
        )

        # keywords are left out if there are none.

        if hasattr(aqtsresult, 'keywords'):
            context.update({'keywords': aqtsresult.keywords})
        else:
            context.update({'keywords': ''})

        # Set context values to POST request changed values.
        context['issue_type'] = request.POST['issue_type']
        context['priority'] = request.POST['priority']

        # Use the SOAP client to change ticket details.
        aqtsresult = aqtsclient.service.editticket(
            ticket_id,
            context['reported_by'],
            context['issue_type'],
            context['priority'],
            context['description'],
            context['product'],
            context['release'],
            context['keywords']
        )
        
        # If client.service call was not a success...
        if aqtsresult.retc != 0:
            context['errors'] = True


    # Return error status.
    return context['errors']

def tickets(request):
    """
    Query SOAP API for filtered ticket list and display them in a template.
    """

    ## Check to make sure user is logged in.

    # If not logged in...
    if not request.user.is_authenticated():
        # Redirect to pristine log in page, which will display login template.
        return HttpResponseRedirect(reverse('aqt_auth:login_page'))

    # If not customer...
    if not request.user.is_staff:
        # Redirect to prospect's page. This is not the best way to handle this, but is
        # being left as adequate for the time being.
        return HttpResponseRedirect(reverse('member:member'))


    ## Initialize

    # Initialize 'context' dict with default values.
    context = {
        'issue_id': 0,
        'status': 'Open',
        'release': '0',
        'keywords': '0',
        'company': '',
        'company_id': 0,
    }

    # If there is a POST request...
    # http://stackoverflow.com/questions/25252238/django-check-if-form-data-exists-in-request
    if request.method == 'POST':
        # Set 'context' dict values to the request information.

        if request.POST['issue_id'] == '':
            context['issue_id'] = 0
        else:
            context['issue_id'] = request.POST['issue_id']

        if request.POST['status'] == 'All':
            context['status'] = '0'
        else:
            context['status'] = request.POST['status']

        if request.POST['release'] == 'All':
            context['release'] = '0'
        else:
            context['release'] = request.POST['release']

        if request.POST['keywords'] == '':
            context['keywords'] = '0'
        else:
            context['keywords'] = request.POST['keywords']

    # If submit is "clear"...reset search criteria.
    if 'clear' in request.POST:
        context = {
            'issue_id': 0,
            'status': 'Open',
            'release': '0',
            'keywords': '0',
            'company': '',
            'company_id': 0,
        }


    ## Query SOAP API for tickets.

    # First get company information from SOAP API.
    aqtsresult = aqtsclient.service.getidandcompany(request.user.email)

    # Store returned company name for later use.
    company = aqtsresult.company_name
    company_id = aqtsresult.cp_id

    # Update 'context' dict.
    context.update({'company': company, 'company_id': company_id})

    # If user is AQT, set company_id to API expected 0 integer.
    if request.user.is_superuser:
        context['company_id'] = 0

    # Query SOAP API for tickets accessible by user.
    # Params are: Ticket #, status, release, keywords, company ID#
    aqtsresult = aqtsclient.service.viewtickets(
        context['issue_id'], 
        context['status'], 
        context['release'], 
        context['keywords'], 
        context['company_id']
    )


    ## Parse 'aqtsresult' and create a usable ticket dictionary to add to
    ## 'context'.

    tickets = {}

    # Traverse over the various Python lists.
    for i in range(aqtsresult.ticket_count):
        # Add ticket to 'tickets' dict.
        tickets.update(
            {
                str(aqtsresult.ticket_number[0][i]): {
                    'ticket_number': aqtsresult.ticket_number[0][i],
                    'reported_by': aqtsresult.reported_by[0][i],
                    'reported_date': aqtsresult.reported_date[0][i],
                    'assigned_to': aqtsresult.assigned_to[0][i],
                    'issue_type': aqtsresult.issue_type[0][i],
                    'priority': aqtsresult.priority[0][i],
                    'product': aqtsresult.product[0][i],
                    'release': aqtsresult.release[0][i],
                    'description': aqtsresult.short_description[0][i],
                }
            }
        )
        # Access of tickets would be like:
        #   tickets['1111'] --> returns dict of ticket '1111'
        #   tickets['1111']['release'] --> returns release of ticket '1111'

        # If the description length was truncated...add elipsis.
        if len(tickets[str(aqtsresult.ticket_number[0][i])]['description']) >= 248:
            tickets[str(aqtsresult.ticket_number[0][i])]['description'] += '...'

    # Sort and add tickets to 'context' dict.
    # We sort the dictionary items into a nested list since dictionaries are
    # inherently non-indexed.
    context.update({'tickets': sorted(tickets.iteritems(), reverse=True)})

    # Also add the ticket count...
    context.update({'ticket_count': aqtsresult.ticket_count})


    ## Change context variables to human readable form for render...

    if context['issue_id'] == 0:
        context['issue_id'] = ''

    if context['status'] == '0':
        context['status'] = 'All'

    if context['release'] == '0':
        context['release'] = 'All'

    if context['keywords'] == '0':
        context['keywords'] = ''


    # Display ticket index template.
    return render(request, 'tickets/tickets.html', context)


def ticket_detail(request, ticket_id):
    """
    Query SOAP API for specific ticket details and display them in a template.
    """

    ## Check to make sure user is logged in.

    # If not logged in...
    if not request.user.is_authenticated():
        # Redirect to pristine log in page, which will display login template.
        return HttpResponseRedirect(reverse('aqt_auth:login_page'))

    # If not customer...
    if not request.user.is_staff:
        # Redirect to prospect's area. This is not the best way to handle this, but is
        # being left as adequate for the time being.
        return HttpResponseRedirect(reverse('member:member'))


    ## Initialize

    context = {
        'issue_id': ticket_id,
        'errors': False,
    }


    ## If there is a POST request.

    # http://stackoverflow.com/questions/25252238/django-check-if-form-data-exists-in-request
    if request.method == 'POST':
        context['errors'] = ticket_edit(request, ticket_id)
         

    ## Query SOAP API for ticket.

    aqtsresult = aqtsclient.service.viewticketdetail(ticket_id)


    ## Parse 'aqtsresult' and add information to a tempalte usable dictionary.

    context.update(
        {
            'ticket_number': aqtsresult.ticket_number,
            'reported_by': aqtsresult.reported_by,
            'reported_date': aqtsresult.reported_date,
            'assigned_to': aqtsresult.assigned_to,
            'issue_type': aqtsresult.issue_type,
            'priority': aqtsresult.priority,
            'product': aqtsresult.product,
            'release': aqtsresult.release,
            'description': aqtsresult.description,
        }
    )

    # 'keywords' and 'num_responses' are left out of SOAP api if there are none.

    if hasattr(aqtsresult, 'keywords'):
        context.update({'keywords': aqtsresult.keywords})
    else:
        context.update({'keywords': ''})

    if hasattr(aqtsresult, 'num_responses'):
        context.update({'num_responses': aqtsresult.num_responses})
    else:
        context.update({'num_responses': '0'})

    # For responses, traverse through the various python lists to create a
    # usable dictionary for responses.

    responses = {}

    for i in reversed(range(aqtsresult.num_responses)):
        # Add response to 'responses' dict with appropriate values.
        responses.update(
            {
                str(i): {
                    'response_date': aqtsresult.response_date[0][i],
                    'response_name': aqtsresult.response_name[0][i],
                    'response_text': aqtsresult.response_text[0][i],
                }
            }
        )
        # Access of responses would be like:
        #   responses['1'] --> returns dict of response '1'
        #   responses['1']['response_text'] --> returns text of ticket '1'

    # Sort dictionary items into a nested list and pass that into context.
    # We do this because dictionaries are inherently non-indexed.
    context.update({'responses': sorted(responses.iteritems(), reverse=True)})


    # Display ticket detail template w/ information.
    return render(request, 'tickets/ticket_detail.html', context)


def ticket_create(request):
    """
    Display a create ticket form and handle POST requests from it.
    """

    ## Check to make sure user is logged in.

    # If not logged in...
    if not request.user.is_authenticated():
        # Redirect to aqt_auth which will display login template.
        return HttpResponseRedirect(reverse('aqt_auth:login_page'))

    # If not customer...
    if not request.user.is_staff:
        # Redirect to prospect's area. This is not the best way to handle this, but is
        # being left as adequate for the time being.
        return HttpResponseRedirect(reverse('member:member'))

    ## Intitialize

    context = {
        'errors': False,
        'product': 'select',
        'release': 'select',
        'priority': 'select',
        'issue_type': 'select',
    }


    ## If there is a POST request.

    # http://stackoverflow.com/questions/25252238/django-check-if-form-data-exists-in-request
    if request.method == 'POST':
        if (request.POST['product'] != 'select' and
            request.POST['release'] != 'select' and
            request.POST['priority'] != 'select' and
            request.POST['issue_type'] != 'select' and
            request.POST['issue'] != ''
        ):
            context.update(
                {
                    'aqts_id': request.user.id,
                    'product': request.POST['product'],
                    'release': request.POST['release'],
                    'priority': request.POST['priority'],
                    'issue_type': request.POST['issue_type'],
                    'window': request.POST['window'],
                    'keywords': request.POST['keywords'],
                    'issue': request.POST['issue'],
                }
            )
            
            # Call API to create a new ticket.
            aqtsresult = aqtsclient.service.createticket(
                context['aqts_id'],
                context['product'],
                context['release'],
                context['priority'],
                context['issue_type'],
                context['window'],
                context['keywords'],
                context['issue']
            )

            # Web Site releases are different, so change release to something
            # suitable if product is 'AQT Web Site'.
            if context['product'] == 'AQT Web Site':
                context['release'] = 'TBD'
                
            # If API call IS NOT a success.
            if aqtsresult.retc != 0:
                context['errors'] = True
            else:
                # If API call IS a success, add new issue_id to context and render
                # success template.
                context.update({'issue_id': aqtsresult.is_id})
                return render(request, 'tickets/ticket_create_success.html', context)
        else:
            context['errors'] = 'Empty'

            # Update the context with captured POST variables to keep data from
            # the first submission.
            context.update(
                {
                    'aqts_id': request.user.id,
                    'product': request.POST['product'],
                    'release': request.POST['release'],
                    'priority': request.POST['priority'],
                    'issue_type': request.POST['issue_type'],
                    'window': request.POST['window'],
                    'keywords': request.POST['keywords'],
                    'issue': request.POST['issue'],
                }
            )


    return render(request, 'tickets/ticket_create.html', context)
