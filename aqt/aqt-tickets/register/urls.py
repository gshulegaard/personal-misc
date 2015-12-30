from django.conf.urls import patterns, url

from register import views

urlpatterns = patterns('', 
    # ex: /register/
    # This template will allow users to fill out a form to be sent via e-mail to
    # an administrator at atmsinfo@aqtsolutions.com requesting a web login.
    url(r'^$', views.register, name='register'),

    # ex: /register/send/
    # This is a the processing for submitted registration form.
    url(r'^send/$', views.register_send, name='register_send'),
)
