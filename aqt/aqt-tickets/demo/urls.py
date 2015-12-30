from django.conf.urls import patterns, url

from demo import views

urlpatterns = patterns('', 
    # ex: /demo/video/
    # This url will serve back a Camtasia player to play our demo video.
    url(r'^video/$', views.demo_video, name='demo_video'),

    # ex: /demo/mobile/
    # This url will serve back the mobile_demo.html page.
# The demo mobile page has been disabled while we decide how to deliver the demo
# Appeon server.
#    url(r'^mobile/$', views.demo_mobile, name='demo_mobile'),
)
