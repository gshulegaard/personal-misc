(function () {
    
    /**
     * The <window-pane> directive.
     *
     * This directive provides the full window container for route elements to be
     * placed within.
     */
    angular.module('windowPane').directive('windowPane', function() {
        return {
            restrict: 'E',
            templateUrl: '/partials/windowPane/windowPane.html',
            controller: function($scope, $window, $route) {
                windowPaneCtrl = this;


                /**
                 * Return the class of the mainPane view.
                 *
                 * @return {String}
                 *    Calculated class string for element.
                 */
                this.mainPaneClass = function() {
                    $scope.WindowPaneManager.setClass(
                        $scope.PowerPaneManager.getState()
                    );

                    return $scope.WindowPaneManager.getClass();
                };


                /**
                 * Return boolean indicating whether PowerPane is currently in
                 * the indicated state.
                 *
                 * @param {String} state
                 *     PowerPane state to check.
                 *
                 * @return {Boolean}
                 *     true if PowerPane is in the indicated state.
                 */
                this.currentState = function(state) {
                    return $scope.PowerPaneManager.currentState(state);
                };


                /**
                 * Calculate and set height of div #mainPane.
                 */
                this.setHeight = function() {
                    $window.$("#mainPane").height($scope.WindowPaneManager.calculateHeight());
                };


                /**
                 * Calculate and set width of div #mainPane.
                 */
                this.setWidth = function() {
                    if ($scope.PowerPaneManager.currentState("minimized")) {
                        $window.$("#mainPane").width($scope.WindowPaneManager.calculateWidth());                        
                    }
                };

                
                /**
                 * Helper function to determine whether or not to show the
                 * compose button shortcut.
                 *
                 * @return {Boolean}
                 *     true when compose button should be shown.
                 */
                this.showCompose = function() {
                    var templateUrl = $route.current.templateUrl;

                    // Compare current template URL against several conditions
                    // with templates that should have the button shown.
                    if (templateUrl == 'partials/mail/mail.html' ||
                        templateUrl == 'partials/security.html') {
                        if (!windowPaneCtrl.currentState('expanded')) {
                            return true;
                        } else {
                            return false;
                        }
                    } else {
                        return false;
                    }
                };


                /**
                 * Helper function for returning position and margin styling for
                 * compose button based on PowerPane state.
                 *
                 * @returns {JSON}
                 *     JSON object expected by 'ng-style' attribute.
                 */
                this.styleCompose = function() {
                    if (!$scope.PowerPaneManager.currentState('minimized')) {
                        return {
                            'bottom': '65px', 
                            'right': '25%', 
                            'margin-right': '40px'
                        };
                    } else {
                        return {'bottom': '65px', 'right': '100px'};
                    }                    
                };


                /**
                 * Monitor PowerPane state to remove explicit width styling when
                 * state is not "minimized".
                 */
                $scope.$watch(
                    function() {
                        return $scope.PowerPaneManager.getState();
                    },
                    function(newValue) {
                        if (newValue != "minimized") {
                            // Remove explicit width definition.
                            $window.$("#mainPane").css("width", "");
                        } else {
                            // Reapply explicit width sizing.
                            windowPaneCtrl.setWidth();
                        }
                    }
                );

                /**
                 * Re-apply setHeight() on window height change.
                 */
                $scope.$watch(
                    function() {
                        return $window.innerHeight;
                    },
                    function(newValue) {
                        windowPaneCtrl.setHeight();
                    }
                );

                /**
                 * Re-apply the setWidth() on window width change.
                 */
                $scope.$watch(
                    function() {
                        return $window.innerWidth;
                    },
                    function(newValue) {
                        windowPaneCtrl.setWidth();
                    }
                );

                /**
                 * Bind $scope.$apply() to window resize event.
                 */
                angular.element($window).bind("resize", function() {
                    $scope.$apply();
                });

            },
            controllerAs: 'windowPaneCtrl'
        };
    });

}) ();
