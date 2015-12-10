(function() {
    
    /**
     * changePasswordModule
     *
     * The angular module definition.  This module provides directives and
     * related objects used by the change password functionality of the portal.
     *
     * FD: This module relies on login for it's login.Message type and
     * login.MessageManager factory.  In the future, both of those utilities
     * could be separated into a more generic module.
     */
    angular.module('changePassword', ['login']);

}) ();
