(function () {
    
    /**
     * The <bot-nav> directive.
     */
    angular.module('botNav').directive('botNav', function() {
        return {
            restrict: 'E',
            templateUrl: '/partials/botNav/botNav.html',
            controller: function($scope, $route) {
                // Must rename since this directive is embedded within another
                // directive.
                botNavCtrl = this;


                /**
                 * Return the class of the botNav element.  This overall class
                 * depends on the PowerPane state.
                 *
                 * @return {String}
                 *     Calculated class string for element.
                 */
                this.botNavClass = function() {
                    $scope.BotNavManager.setClass(
                        $scope.PowerPaneManager.getState()
                    );

                    return $scope.BotNavManager.getClass();
                };


                /**
                 * Return "navbar-brand-active" class when the current view in
                 * the $scoope.BotNavManager is equal to the passed value.
                 *
                 * @param {String} view
                 *     View string to be checked for "Active".
                 *
                 * @return {String}
                 *     Returns "navbar-brand-active" if true.
                 */
                this.activeView = function(templateURL) {
                    if ($scope.BotNavManager.currentTemplate(templateURL)) {
                        return "navbar-brand-active";
                    }
                };


                /**
                 * Watch for routing template changes and reapply variable
                 * stores.
                 */
                $scope.$watch(
                    function() {
                        return $route.current.templateUrl;
                    },
                    function(newValue) {
                        $scope.BotNavManager.changeTemplate($route.current.templateUrl);
                    }
                );
            },
            controllerAs: 'botNavCtrl'
        };
    });
}) ();
