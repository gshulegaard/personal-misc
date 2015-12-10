from django.conf.urls import patterns, url

from aqt_auth import views

urlpatterns = patterns('', 
    # ex: /
    # This displays a pristine login form/page.
    url(r'^$', views.login_page, name='login_page'),

    # ex: /login/
    # This is the processing for logging in.
    url(r'^login/$', views.aqt_login, name='aqt_login'),

    # ex: /logout/
    # This is the processing for logging out.
    url(r'^logout/$', views.aqt_logout, name='aqt_logout'),
)
