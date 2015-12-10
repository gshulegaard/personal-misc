(function () {

    /*
     *  The <power-pane-nav> directive that houses widget PowerPane navigation
     *  widget embedded in the top navigation bar.
     */
    angular.module('powerPane').directive('powerPaneNav', function() {
        return {
            restrict: 'E',
            templateUrl: '/partials/powerPane/powerPaneNav.html',
            controller: function($scope) {
                /**
                 * Check PowerPane state using the manager.
                 *
                 * @param {String} state
                 *     The state string to match.
                 */
                this.currentState = function(state) {
                    return $scope.PowerPaneManager.currentState(state);
                };

                /**
                 * Expand PowerPane state using the manager.
                 */
                this.expandState = function() {
                    $scope.PowerPaneManager.expand();
                };
                
                /**
                 * Reduce PowerPane state using the manager.
                 */
                this.reduceState = function() {
                    $scope.PowerPaneManager.reduce();
                };
            },
            controllerAs: 'powerPaneNavCtrl'
        };
    });

}) ();
