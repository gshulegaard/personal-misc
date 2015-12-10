from pyramid.view import view_config

@view_config(route_name='default', renderer='templates/mytemplate.pt')
def default_view(request):
    """
    Default view created by pcreate.
    """

    return {'project': 'portal'}


@view_config(route_name='index', renderer='templates/index.jinja2')
def index_view(request):
    """
    Return the EmberJS *.html SPA.
    """

    # In pyramid, you pass variables to the template in the return statement of
    # the view function.  This is opposed to Django which has you pass variables
    # into a 'django.contrib' 'render' function.
    return {}


@view_config(route_name='guac', renderer='templates/guac.jinja2')
def guac_view(request):
    """
    Return the 'guac.html' template.  This view allows Guacamole WebRDP
    instances to be opened in a new window.
    """

    # Pass variables to template rendered with 'return'.
    return {}
