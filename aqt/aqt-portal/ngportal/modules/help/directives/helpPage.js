(function() {
    
    /**
     * helpPage
     *
     * A simple directive that binds a help template.
     */
    angular.module('help').directive('helpPage', function() {
        return {
            restrict: 'E',
            templateUrl: 'partials/help/helpPage.html',
            controller: function() {
                // Do nothing.
            },
            controllerAs: 'helpPageCtrl'
        };
    });

}) ();
