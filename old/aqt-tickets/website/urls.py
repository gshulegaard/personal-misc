from django.conf.urls import patterns, include, url
# Disable admin interface since we don't care to enable it for now.
#from django.contrib import admin

urlpatterns = patterns('',
    # Examples:
    # url(r'^$', 'website.views.home', name='home'),
    # url(r'^blog/', include('blog.urls')),

    # Serve the primary ticket application.
    url(r'^', include('aqt_auth.urls', namespace='aqt_auth')),

    # Serve the contact application.
    url(r'^contact/', include('contact.urls', namespace='contact')),

    # Serve the support application.
    url(r'^support/', include('support.urls', namespace='support')),

    # Serve the atms members support application.
    url(r'^atms-support/', include('atms_support.urls', namespace='atms_support')),

    # Serve the atms demo support application.
    url(r'^demo/', include('demo.urls', namespace='demo')),

    # Serve the register application.
    url(r'^register/', include('register.urls', namespace='register')),

    # Serve the download application
    url(r'^download', include('download.urls', namespace='download')),

    # Serve the mobile application.
    url(r'^mobile/', include('mobile.urls', namespace='mobile')),

    # Serve the ticket application.
    url(r'^ticket', include('tickets.urls', namespace='tickets')),

    # Serve the customer  application.
    url(r'^customer/', include('customer.urls', namespace='customer')),

    # Serve the prospect application.
    url(r'^member/', include('member.urls', namespace='member')),

    # Serve the flipbook application.
    url(r'^flipbook/', include('flipbook.urls', namespace='flipbook')),

    # Disable admin interface since we don't care to enable it for now.
    #url(r'^admin/', include(admin.site.urls)),
)
