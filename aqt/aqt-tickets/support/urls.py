from django.conf.urls import patterns, url

from support import views

urlpatterns = patterns('', 
    # ex: /support/
    # This is a contact support form page.
    url(r'^$', views.support, name='support'),
)
