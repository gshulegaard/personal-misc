(function() {
    
    /**
     * loginPageController
     *
     * This is the controller definition for the /login route.  It is bound to
     * the 'partials/login/login-page.html' template which contains the
     * loginForm directive.
     */
    angular.module('login').controller('loginPageController', [
        '$window', '$log', '$scope',  
        function($window, $log, $scope) {
            loginPageController = this;

            /**
             * Function that applies the full height of the window to a div
             * selected by "id".
             *
             * @param {string}
             *     ID value in string format.
             */
            this.setFullHeight = function(id) {
                $window.$("#" + id).height($window.innerHeight);
            };


            /**
             * Scope variable that re-applies height values on window height
             * change.
             */
            $scope.$watch(
                function() {
                    return $window.innerHeight;
                },
                function(newValue) {
                    loginPageController.setFullHeight("leftBar");
                }
            );


            /**
             * Bind $scope.$apply() to window resize event.
             */
            angular.element($window).bind("resize", function() {
                $scope.$apply();
            });
            
        }

    ]);

}) ();
