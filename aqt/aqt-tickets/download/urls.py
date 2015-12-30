from django.conf.urls import patterns, url

from download import views

urlpatterns = patterns('', 
    # ex: /download?filename=atms_mobile.plist&folder=mobile&type=text/plain
    # This is a download link that will cause the server to serve up a file to
    # the client without needing to be authenticated.
    url(r'^$', views.download, name='download'),

    # ex: /download-secure?filename=atms_core.exe&folder=ver510&type=text/plain
    # This is a download link that will cause the server to serve up a file to
    # the client if they are authenticated.
    url(r'^-secure$', views.download_secure, name='download-secure'),
)
