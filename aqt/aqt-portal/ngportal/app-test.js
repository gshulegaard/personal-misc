(function() {

    var app = angular.module('portal', ['ngCookies']);

    // Main controller to wrap our entire application in to provide modularity
    // and shared $scope between embedded modules.
    app.controller('appController', function($scope, $cookies) {

        // Load config.json
        $scope.config = {
            apiBaseUrl: 'http://api.aqtsolutions.net',
            guacBaseUrl: 'http://guac.aqtsolutions.net',
            key: 'value'
        };

        // Login information store.
        $scope.credentials = {
            username: 'gshulegaard',
            password: 'Loki847!',
            token: 'this-is-a-test-token',
            isVerified: true
        };

        this.credentials = $scope.credentials;

        this.resetCredentials = function() {
            $scope.credentials.password = '';
            $scope.credentials.token = '';
            $scope.credentials.isVerified = false;
            this.credentials = $scope.credentials;
        };

        this.reset = function() {
            $scope.credentials.password = 'Loki847!';
            $scope.credentials.token = 'this-is-a-test-token';
            $scope.credentials.isVerified = true;
            this.credentials = $scope.credentials;
        };

        // Login cookie.
        $cookies.login = this.credentials;

        this.cookieLogin = $cookies.login;
    });

}) ();
