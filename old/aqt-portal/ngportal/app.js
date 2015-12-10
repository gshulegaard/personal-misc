(function() {

    var app = angular.module('portal', ['ngRoute', 
                                        'ngCookies', 
                                        'auth', 
                                        'login', 
                                        'applications',
                                        'lms']);

    /**
     * Main controller that wraps our entire application to provide modularity
     * and a shared $scope between embedded modules.
     *
     * Standard practice is to attach this controller to the <body> tag of the
     * index.html (or primary HTML template).
     */
    app.controller('appController', function($rootScope, $scope, $http, $log,
                                             $cookies, $route, $routeParams,
                                             $location, AuthManager, 
                                             SessionManager, ConfigManager) {
        /**
         * Instance variables
         */

        // Create self-store.
        var thisCtrl = this;

        // Route Services
        $scope.$route = $route;
        $scope.$location = $location;
        $scope.$routeParams = $routeParams;

        // Instantiate a $scope level AuthManager.
        $scope.AuthManager = new AuthManager();

        // Instantiate a $scope level SessionManager.
        $scope.SessionManager = new SessionManager();

        // Instantiate a $scope level ConfigManager.
        $scope.ConfigManager = new ConfigManager();


        /**
         * Mobile Detection
         */

        // http://www.abeautifulsite.net/detecting-mobile-devices-with-javascript/
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

        // Create mobile detection cookie.
        $cookies.put("isMobile", isMobile.any());


        // Note that the mobile detection code above is not used anywhere within
        // the Angular application (...yet).


        /**
         * Login re-routing.
         */

        // http://stackoverflow.com/questions/11541695/redirecting-to-a-certain-route-based-on-condition

        $rootScope.$on("$locationChangeStart", function(event, next, current) {
            if ( !$scope.AuthManager.isAuthenticated() ) {
                // No user logged in...

                // Redirect to login.
                $scope.$location.path( "/login" );

            } else {
                // User logged in...
                
            }
        });

    });


    app.config(function($routeProvider, $locationProvider) {
        $routeProvider
            .when('/login', {
                templateUrl: '/partials/login/login-page.html',
                controller: 'loginPageController',
                controllerAs: 'loginPageController'
            })
            .when('/applications', {
                templateUrl: '/partials/applications/app-page.html',
                controller: 'appPageController',
                controllerAs: 'appPageController'
            })
            .when('/lms/todo', {
                templateUrl: '/partials/lms/todo-list.html',
                controller: 'todoController',
                controllerAs: 'todoController'
            })
            .when('/lms/launchpage', {
                templateUrl: '/partials/lms/launchpage.html',
                controller: 'launchpageController',
                controllerAs: 'launchpageController'
            })
            .otherwise({
                redirectTo: '/applications'
            });
        
        // Configure HTML5 routing.
        $locationProvider.html5Mode(true);
    });
    
}) ();
