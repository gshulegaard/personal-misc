from django.conf.urls import patterns, url

from customer import views

urlpatterns = patterns('', 
    # ex: /
    # This displays the members' area.
    url(r'^$', views.customer, name='customer'),
)
