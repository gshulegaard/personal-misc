(function () {

    /**
     * State manager for communication between various layers of PowerPane
     * module.  This object should be instantiated and interacted with in
     * $scope or $rootScope.
     */
    angular.module('powerPane').factory('PowerPaneManager', [ 
        function() {
            // List of states.
            var states = ["minimized", "active", "expanded"];


            var ManagedState = function() {
                /**
                 * The display state of the PowerPane.
                 * 
                 * @type String
                 *     Possible values are states[].
                 */
                this.display = states[0]; // Default to "minimized"

                /**
                 * The current PowerPane application.
                 *
                 * @type String
                 *     Name of application active in PowerPane.
                 */
                this.app = "calendar"; // Default to "calendar"
            };


            /**
             * Method returning the current state of the PowerPane.
             *
             * @return {String}
             */
            ManagedState.prototype.getState = function() {
                return this.display;
            };


            /**
             * Method checking current state against a passed state and
             * returning a boolean.
             * 
             * @param {String} state
             *     State string to be checked against current state.
             *
             * @returns {Boolean}
             *     true if the state is equal to passed state.
             */
            ManagedState.prototype.currentState = function(state) {
                return this.display == state;
            };


            /**
             * Method to increase the state of the PowerPane.
             */
            ManagedState.prototype.expand = function() {
                // If the display value is not the highest...
                if (this.display !== states[2]) {
                    // Set display property to the next greater value
                    this.display = states[
                        (
                            states.indexOf(this.display) + 1
                        )
                    ];
                }
            };


            /**
             * Method to reduce the state of the PowerPane.
             */
            ManagedState.prototype.reduce = function() {
                // If the display value is not the lowest...
                if (this.display !== states[0]) {
                    // Set display property to the next lesser value
                    this.display = states[
                        (
                            states.indexOf(this.display) - 1
                        )
                    ];
                }
            };


            /**
             * Method checking the currently active application.
             *
             * @param {string} app
             *     String name of app to check.
             *
             * @returns {Boolean}
             *     true if the app is equal to the passed value.
             */
            ManagedState.prototype.activeApp = function(app) {
                return this.app == app;
            };


            /**
             * Method to chang the active application.
             *
             * @param {string} app
             *     String name of app to change to.
             */
            ManagedState.prototype.changeApp = function(app) {
                this.app = app;
            };


            return ManagedState;
        }
    ]);

}) ();
