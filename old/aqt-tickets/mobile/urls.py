from django.conf.urls import patterns, url

from mobile import views

urlpatterns = patterns('',
    # ex: /mobile/
    # This url will serve back the mobile.html page.
    url(r'^$', views.mobile, name='mobile'),
)
