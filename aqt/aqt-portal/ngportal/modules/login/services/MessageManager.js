(function() {
    
    /**
     * MessageManager
     *
     * This factory is a management wrapper for storing message objects and
     * managing them.
     */
    angular.module('login').factory('MessageManager', ['Message', 
       function(Message) {
            var ManagedState = function() {
                /**
                 * Message store.  Simple array used to manage a collection of
                 * "active" messages.
                 *
                 * @type {array}
                 */
                this.messageStore = [];
            };


           /**
            * Method that adds a message to the store.
            *
            * @param {Message}
            *     This method accepts objects as defined by the Message type
            *     factory for the login module.
            */
           ManagedState.prototype.addMessage = function(message) {
               // Add new element to the end of the array.
               this.messageStore.push(message);

               // This could also be done using .splice(0, 0, message) or with
               // .unshift(message).
           };


           /**
            * Method that removes and returns the first message in the
            * array (this also happens to be the oldest message as well).
            *
            * @returns {Message}
            *     Returns the first message in the array.
            */
           ManagedState.prototype.popMessage = function() {
               return this.messageStore.shift();
               // FD: This can result in "undefined" being returned if this
               // method is called when the messageStore is empty.  This should
               // be handled gracefully in the future.
           };


           // Note: The addMessage and popMessage methods together create a
           // first in, first out behavior for the messageStore.


           /**
            * Method that removes a specific message from the messageStore.
            *
            * @param {Message}
            *     This method accepts a message, and uses it to splice the
            *     messageStore, effectively removing it.  The message is NOT
            *     returned.
            */
           ManagedState.prototype.removeMessage = function(message) {
               var index = this.messageStore.indexOf(message);

               if (index > -1) {
                   this.messageStore.splice(index, 1);
               }

               // Note that this method does not handle duplicate messages
               // well.  It will remove the first instance of a message it finds
               // in the messageStore.
           };


           /**
            * Method that remove all currently stored messages from the
            * messageStore. This is accomplished lazily by simply redefining
            * messageStore as an empty array.
            *
            * Note: The same effect could be accomplished by looping over the
            * popMessage function for the length of the array.
            */
           ManagedState.prototype.clearMessages = function() {
               this.messageStore = [];
           };


           /**
            * Method that returns an indicator reflecting the state of the
            * message store.  This is useful as a visibility flag in for
            * controllers.
            * 
            * @returns {bool}
            *     True if the store is empty.
            */
           ManagedState.prototype.isEmpty = function() {
               return this.messageStore == [];
           };
           
            
            return ManagedState;
        }
    ]);

}) ();
