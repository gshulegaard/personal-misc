from django.conf.urls import patterns, url

from atms_support import views

urlpatterns = patterns('', 
    # ex: /atms_support/
    # This is a contact page for sending an e-mail to
    # atmssupport@aqtsolutions.com.
    url(r'^$', views.atms_support, name='atms_support'),
)
