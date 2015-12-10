(function () {
    
    /**
     * SessionManager
     *
     * This factory creates and tracks a "session" variable to some-what control
     * simultaneous logins.
     *
     * Note: This "session" management only applies to simultaneous sessions
     * opened within the same browser since it relies on cookies.
     *
     * FD: Handled sessions on the server by extending the Token management
     * class.  Then refactor this SessionManager to simply handle situatiosn
     * where a user's token on the server has been changed.  This change may
     * actually result in the removal of this factory.
     */
    angular.module('login').factory('SessionManager', [
        '$log', '$cookies', 
        function($log, $cookies) {
            var ManagedState = function() {
                /**
                 * Session Key
                 *
                 * Random session key that is generated on initialization.
                 *
                 * @type {integer}
                 */
                this.sessionKey = Math.random();

                // On initialization, store the session key as a cookie provided
                // there doesn't already exist a session.
                if ($cookies.activeSession !== 'true') {
                    $cookies.put("session", this.sessionKey);
                }
            };


            /**
             * Method that checks to see if the browser-wide cookie matches
             * generated sessionKey.
             *
             * @returns {boolean}
             *     True if the session matches.
             */
            ManagedState.prototype.validSession = function() {
                return $cookies.get("session") == this.sessionKey;
            };

            
            /**
             * Method that overrides the browser-wide session cookie to match
             * the stored sessionKey.
             */
            ManagedState.prototype.overrideSession = function() {
                $cookies.put("session", this.sessionKey);
            };


            return ManagedState;
        }
    ]);

}) ();
