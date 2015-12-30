from pyramid.config import Configurator


def main(global_config, **settings):
    """ 
    This function returns a Pyramid WSGI application.
    """
    # Import the passed *.ini file.
    config = Configurator(settings=settings)

    # Includes
    config.include('pyramid_chameleon')
    config.include('pyramid_jinja2')

    # Static files
    config.add_static_view('static', 'static', cache_max_age=3600)

    # Routing
    config.add_route('default', '/default/')
    config.add_route('index', '/')
    config.add_route('guac', '/guac/')

    config.scan()
    return config.make_wsgi_app()
