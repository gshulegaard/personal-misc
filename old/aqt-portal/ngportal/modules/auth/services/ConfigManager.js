(function () {

    /**
     * ConfigManager
     *
     * This manager provides a shared object for managing the retrieval and
     * storage of a JSON configuration from the /core/config api endpoint.
     */
    angular.module('auth').factory('ConfigManager', [
        '$http', '$log', 
        function($http, $log) {
            var ManagedState = function(template) {
                template = template || {};

                /**
                 * The configuration JSON object.  Usually retrieved from the
                 * /core/config api endpoint.
                 */
                this.configObj = null; // Default to null since /core/config is
                                       // a protected end-point that requires a
                                       // valid token to have been assigned
                                       // during login.
                
                /**
                 * Locally stored API variable.
                 */
                this.apiBaseUrl = template.apiBaseUrl || "/api";
            };

            
            /**
             * Method that loads (or re-loads) a JSON config from the
             * /core/config end-point.
             *
             * The embedded AJAX call requires an authorization token retrieved
             * during login.
             *
             * @param {string} token
             *     Properly formatted X-Core-Token to be added to the request
             *     headers.  This token takes form of [username]-[token].
             */
            ManagedState.prototype.loadConfig = function(token) {
                // Must create local variable reference to 'this' to use within
                // AJAX call.
                var thisObj = this;

                // Create request object.
                var req = {
                    method: 'GET',
                    url: thisObj.apiBaseUrl + '/core/config',
                    headers: { 'X-Core-Token': token },
                    contentType: 'application/json', // Might need to remove for GET.
                    data: JSON.stringify(
                        {}
                    ) // Might need to remove for GET.
                };

                // Submit the request.
                $http(req)
                    .success(function(data, status, headers, config) {
                        thisObj.configObj = data;
                    })
                    .error(function(data, status, headers, config) {
                        $log.error("Failed to retrieve JSON " + 
                                   "configuration. " + 
                                   "[auth.ConfigManager.loadConfig()]");
                    });
            };
            
            return ManagedState;
        }
    ]);

}) ();
