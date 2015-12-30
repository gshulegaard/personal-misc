(function() {
    
    /**
     * Message
     *
     * This factory defines a re-usable message object that can be used to store
     * properties that are required for displaying messages (of various types)
     * to an end-user.
     */
    angular.module('login').factory('Message', [
        function() {
            // List of types.
            var types = ["Success", "Warning", "Error"];

            var Type = function(template) {
                // Use an empty template by default.
                template = template || {};

                /**
                 * Message type.
                 *
                 * @type {types[]}
                 */
                this.type = template.type || types[2]; // Default is "error"
                
                /**
                 * Message text.
                 *
                 * @type {string}
                 */
                this.text = template.text || "";
            };


            // Note that the template handling here allows a new message to be
            // instantiated with contents e.g.:
            //     var message = new Message({"type": "Success", "text": "Some string."})

            
            /**
             * Method that sets the message properties.
             *
             * For simplicitiy's sake, this method should be used for
             * editing/changing the contents of a message as well.
             *
             * Note: This could probably be done individually by accessing the
             * type and text properties of the object directly.
             *
             * @param {types[]} type
             * @param {string} text
             */
            Type.prototype.setMessage = function(type, text) {
                this.type = type;
                this.text = text;
            };


            /**
             * Method that checks the type of the stored message.
             *
             * Note: I don't have an intended use for this method...but it
             * seemed like a useful method to have.
             *
             * @param {types[]} (or any string)
             *
             * @returns {bool}
             *     True if the type matches the checked type.
             */
            Type.prototype.ofType = function(type) {
                return type == this.type;
            };

            
            /**
             * Method that returns the Bootstrap alert class corresponding to
             * the message type.
             *
             * @returns {string}
             *     Properly formatted Bootstrap class.
             */
            Type.prototype.messageClass = function() {
                switch (this.type) {
                    case "Success":
                        return "alert-success";
                    case "Warning":
                        return "alert-warning";
                    case "Error":
                        return "alert-danger";
                    default:
                        return "alert-danger";
                }
            };

            
            return Type;
        }
    ]);

}) ();
