from django.conf.urls import patterns, url

from member import views

urlpatterns = patterns('', 
    # ex: /
    # This displays the members' area.
    url(r'^$', views.member, name='member'),
)
