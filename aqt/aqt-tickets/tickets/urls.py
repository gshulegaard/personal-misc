from django.conf.urls import patterns, url

from tickets import views

urlpatterns = patterns('', 

    # ex: /tickets/
    # This template will display an index of tickets viewable by the user. This
    # template will also have search criteria.
    url(r'^s$', views.tickets, name='tickets'),

    # ex: /tickets/<ticket_id>/
    # This template will show the details of a specific ticket (identified by
    # the ticket number).
    url(r'^/(?P<ticket_id>[0-9]+)/$', views.ticket_detail,
        name='ticket_detail'),

    # ex: /tickets/create
    # This template will display a form for creating a brand new ticket.
    url(r'^/create/$', views.ticket_create, name='ticket_create'),
)
