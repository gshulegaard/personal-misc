(function() {
    
    /**
     * State manager for managing various states of the windowPane.  Manages the
     * combined display of the mainPane and the powerPane within the main
     * windowPane.
     *
     * This manager implicitly relies on the PowerPaneManager for retrieving
     * information about the state of the PowerPane.
     */
    angular.module('windowPane').factory('WindowPaneManager', ['$window', 
        function($window) {
            var ManagedState = function() {
                /**
                 * The calculated class for mainPane. Necessary to accomodate
                 * ngRoute.
                 *
                 * @type String
                 *     CSS class string that is computed based on state of PowerPane.
                 */
                this.mainPaneClass = "";

                /**
                 * The calculated height for the mainPane.
                 *
                 * @type Float
                 *     The height of the div for the mainPane.
                 */
                this.mainPaneHeight = 0;

                /**
                 * The calculated height for the mainPane.
                 *
                 * @type Float
                 *     The width of the dive for the mainPane.
                 */
                this.mainPaneWidth = 0;
            };


            /**
             * Method setting the appropriate class string for the mainPane
             * based on the PowerPane state.
             *
             * @param {String} state
             *     State string for the current state of the PowerPane.
             */
            ManagedState.prototype.setClass = function(state) {
                // Check state and set class string appropriately.
                // This only applies to "minimized" and "active" states.  In
                // "expanded" state, the mainPane will be hidden. 
                if (state == "minimized") {
                    this.mainPaneClass = "col-xs-12 main-pane-minimized";
                } else {
                    // When state is "active"
                    this.mainPaneClass = "col-xs-12 col-md-7 col-lg-9 main-pane-active";
                }
            };


            /**
             * Method returning the class string.
             *
             * @return {String}
             *     Returns the currently stored class string.
             */
            ManagedState.prototype.getClass = function() {
                return this.mainPaneClass;
            };

            
            /**
             * Method calculating and saving the height of the mainPane.
             *
             * @return {Float}
             *     Returns the height in pixels for the mainPane.
             */
            ManagedState.prototype.calculateHeight = function() {
                // Subtract 40 pixels for topNav and 55 (45 + 10 pad) for botNav
                this.mainPaneHeight = ($window.innerHeight - 95);

                return this.mainPaneHeight;
            };

            /**
             * Method calculating and saving the width of the mainPane.
             *
             * @return {Float}
             *     Returns the height in pixels for the mainPane.
             */
            ManagedState.prototype.calculateWidth = function() {
                // Subtract 60 pixels for the minimized powerPane width.
                this.mainPaneWidth = ($window.innerWidth - 60);
                
                return this.mainPaneWidth;
            };

            return ManagedState;
        }
    ]);

}) ();
