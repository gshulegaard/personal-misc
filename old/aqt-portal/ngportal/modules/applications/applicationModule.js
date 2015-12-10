(function() {
    
    /**
     * applicationModule
     *
     * The angular modules definition.  This module provides the primary
     * application logic.  At the moment, current application architecture
     * relies on a single page after login (the applications page) which has
     * consequences regarding the central role this particular module plays.
     */
    angular.module('applications', ['ngCookies',
                                    'client',
                                    'changePassword',
                                    'help']);

}) ();
