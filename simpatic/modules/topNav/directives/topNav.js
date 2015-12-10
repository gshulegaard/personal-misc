(function() {

    /*
     *  The <top-nav> directive.
     */
    angular.module('topNav').directive('topNav', function() {
        return {
            restrict: 'E',
            templateUrl: '/partials/topNav/topNav.html',
            controller: function($scope) {
                topNavCtrl = this;


                /**
                 * Helper function for returning margin and padding styling for
                 * icons based on PowerPane state.
                 *
                 * @returns {JSON}
                 *     JSON object expected by 'ng-style' attribute.
                 */
                this.iconMarginStyle = function() {
                    if (!$scope.PowerPaneManager.currentState('minimized')) {
                        return {'margin-right': '25%', 'padding-right': '15px'};
                    } else {
                        return {'margin-right': '0', 'padding-right': '60px'};
                    }
                };
            },
            controllerAs: 'topNavCtrl'
        };
    });

}) ();
