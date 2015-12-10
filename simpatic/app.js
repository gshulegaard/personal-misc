(function() {

    var app = angular.module('simpatic', ['ngRoute',
                                          'ngCookies', 
                                          'topNav',
                                          'windowPane',
                                          'mail']);

    /**
     * Main controller of the base angular module.  Top of the $scope tree and
     * is loaded first.
     *
     * Most of the $scope definitions end up here and this functions as a
     * GLOBAL/$rootscope replacement that can also house processing.
     */
    app.controller('rootController', function($scope, $http, $log, $cookies,
                                              $route, $routeParams, $location,
                                              PowerPaneManager, 
                                              WindowPaneManager,
                                              BotNavManager) {

        // Create self-store.
        var thisCtrl = this;

        // Route services.
        $scope.$route = $route;
        $scope.$location = $location;
        $scope.$routeParams = $routeParams;


        /**
         * Authentication
         */
        $scope.isAuthenticated = false;
        $scope.user = "";
        $scope.password = "";


        /**
         * Simple Mobile detection.
         * http://www.abeautifulsite.net/detecting-mobile-devices-with-javascript/
         */
        var isMobile = {
            Android: function() {
                return navigator.userAgent.match(/Android/i);
            },
            BlackBerry: function() {
                return navigator.userAgent.match(/BlackBerry/i);
            },
            iOS: function() {
                return navigator.userAgent.match(/iPhone|iPad|iPod/i);
            },
            Opera: function() {
                return navigator.userAgent.match(/Opera Mini/i);
            },
            Windows: function() {
                return navigator.userAgent.match(/IEMobile/i);
            },
            any: function() {
                return ( isMobile.Android() || 
                         isMobile.BlackBerry() || 
                         isMobile.iOS() || 
                         isMobile.Opera() || 
                         isMobile.Windows()
                       );
            }
        };

        $cookies.put("isMobile", isMobile.any());


        /**
         * PowerPane management.
         *
         * This also affects the display of the various directives for windowPane.
         */
        $scope.PowerPaneManager = new PowerPaneManager();

        /**
         * WindowPane Management.
         *
         * Depends on PowerPaneManager for PowerPane display states.
         */
        $scope.WindowPaneManager = new WindowPaneManager();

        /**
         * BotNav Management.
         *
         * Depends on PowerPane Manager for PowerPane display states.
         */
        $scope.BotNavManager = new BotNavManager();


        /**
         * Temporary datastore with user/encryption secrets.
         */
        $scope.users = {
            "johndoe@simpatic.co": {"password": "password"},
            "peterparker@simpatic.co": {"password": "spiderman"}
        };
        
        $scope.secret = [-52, 115, 57, -115, 83, -54, 34, 98, 12, -32, -25, 13, 55, -2, 104, 64, -24, -121, -28, 10, 14, -69, -17, -128, 20, -9, -20, -119, -3, 78, -34, -100];
        
    });

    app.config(function($routeProvider, $locationProvider) {
        $routeProvider
            .when('/mail', {
                templateUrl: 'partials/mail/mail.html',
                //controller: 'BookController'
            })
            .when('/mail/compose', {
                templateUrl: 'partials/mail/compose.html',
                controller: 'mailComposeController'
            })
            .when('/chat', {
                templateUrl: 'partials/chat.html',
                //controller: 'ChapterController'
            })
            .when('/security', {
                templateUrl: 'partials/security.html',
                //controller: 'SecurityController'
            })
            .otherwise({
                redirectTo: '/mail'
            });
        
        // configure html5 to get links working on jsfiddle
        $locationProvider.html5Mode(true);
    });

}) ();
