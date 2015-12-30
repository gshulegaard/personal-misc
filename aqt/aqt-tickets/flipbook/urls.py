from django.conf.urls import patterns, url

from flipbook import views

urlpatterns = patterns('', 
    # ex: /flipbook/
    # This url will catch base url and display 404.
    url(r'^$', views.flipbook_404, name='base'),

    # ex: /flipbook/index/
    # This url will serve the all the slugs for viewing.
    url(r'^index/$', views.flipbook_index, name='index'),

    # ex: /flipbook/new/
    # This url will serve the new slug template.
    url(r'^new/$', views.flipbook_new, name='new'),

    # ex: /flipbook/copy/<slug>
    # This url will serve the new slug template.
    url(r'^copy/(?P<url_slug>[a-z0-9\-]+)/$', views.flipbook_copy, name='copy'),

    # ex: /flipbook/<slug>/
    # This url will serve the slug for viewing.
    url(r'^(?P<url_slug>[a-z0-9\-]+)/$', views.flipbook_view, name='view'),

    # ex: /flipbook/<slug>/edit/
    # This url will serve the slug for editing.
    url(r'^(?P<url_slug>[a-z0-9\-]+)/edit/$', views.flipbook_edit, name='edit'),
)
