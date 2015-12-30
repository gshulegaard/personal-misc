(function() {
    
    /**
     * launchpageController
     *
     * The controller definition for the lms To-Do list.
     */
    angular.module('lms').controller('launchpageController', [
        "$route", "$routeParams", "$scope", "$window",
        function($route, $routeParams, $scope, $window) {
            /**
             * Instance Variables
             */
            
            // Instantiate self reference
            this.launchpageController = this;

            // Content Path grabbed from the query params in the url.
            // https://docs.angularjs.org/api/ngRoute/service/$routeParams
            this.contentPath = $routeParams.content;


            /**
             * Set height of iframe to max height
             */

            this.setFullHeight = function(id) {
                $window.$("#" + id).height($window.innerHeight);
            };

            // Scope variable that re-applies height values on window height
            // change.
            $scope.$watch(
                function() {
                    return $window.innerHeight;
                },
                function(newValue) {
                    loginPageController.setFullHeight("content");
                }
            );

            // Bind $scope.$apply() to window resize event.
            angular.element($window).bind("resize", function() {
                $scope.$apply();
            });

        }

    ]);

}) ();
