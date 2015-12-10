from django.conf.urls import patterns, url

from contact import views

urlpatterns = patterns('', 

    # ex: /contact/
    # This is a contact form page.
    url(r'^$', views.contact, name='contact'),
)
