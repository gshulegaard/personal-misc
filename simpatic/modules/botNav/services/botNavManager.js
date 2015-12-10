(function() {
    
    /**
     * State manager for the botNav.  This manager will allow the botNav to
     * dynamically size in relation to the state of the PowerPane.
     *
     * This manager implicitly relies on the PowerPaneManager for current 
     * state of the powerPane.
     */
    angular.module('botNav').factory('BotNavManager', [
        function() {

            var ManagedState = function() {
                /**
                 * The calculated class for botNav.  Neccessary to accomodate
                 * sizing issues with the PowerPane.
                 *
                 * @type String
                 *     CSS class string that is computed based on state of PowerPane.
                 */
                this.botNavClass = "";

                /**
                 * The currently displayed view (template/route).
                 *
                 * @type String
                 *     Possible values are states[].
                 */
                this.templateURL = "";
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
                // This only applies to the "active" state since the botNav
                // is full-width otherwise.
                if (state == "active") {
                    this.botNavClass = "col-xs-12 col-md-7 col-lg-9 bot-nav";
                } else {
                    this.botNavClass = "col-xs-12 bot-nav";
                }
            };


            /**
             * Method returning the class string.
             *
             * @return {String}
             *     Returns the currently stored class string.
             */
            ManagedState.prototype.getClass = function() {
                return this.botNavClass;
            };


            /**
             * Method returning the current view.
             *
             * @return {String}
             */
            ManagedState.prototype.getView = function() {
                return this.view;
            };

            
            /**
             * Method checking the current view against a passed view string and
             * returning a boolean.
             *
             * @param {String} view
             *
             * @return {Boolean}
             *     true if the state is equal to the passed view string.
             */
            ManagedState.prototype.currentTemplate = function(templateURL) {
                return this.templateURL == templateURL;
            };

            
            /**
             * Method for changing the stored tempalte URL.
             */
            ManagedState.prototype.changeTemplate = function(templateURL) {
                this.templateURL = templateURL;
            };

            return ManagedState;
        }
    ]);

}) ();
