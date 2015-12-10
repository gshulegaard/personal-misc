(function() {
    
    /**
     * AuthManager
     *
     * Authentication manager (service) that manages user credentials and
     * tokens.  This is separated into a separate factory in order to allow for
     * the management of multiple user accounts in the future.
     *
     * It should also be noted that this service does NOT handle errors.  Errors
     * should be handled by controller logic to be rendered (MVC) to an
     * end-user.  As such, errors are formatted and passed directly out of
     * methods back to the calling logic.
     *
     * Finally, Password/Account management functions are included in this
     * manager because those functions relate to/use username and passwords.
     * These functions also impact Authentication, so it makes some sense that
     * they live here.
     */
    angular.module('auth').factory('AuthManager', [
        '$http', '$log', '$location', 
        function($http, $log, $location) {
            var ManagedState = function(template) {
                template = template || {};

                /**
                 * Username
                 *
                 * @type {string}
                 *     Username given by the user.
                 */
                this.username = template.username || "";
                
                /**
                 * Password
                 *
                 * @type {string}
                 *     Password given by the user.
                 */
                this.password = template.password || "";
                
                /**
                 * Token
                 *
                 * This is a specially formatted token that is used to manage
                 * authorization for the API.  It is returned by the API upon
                 * accepted authentication at /core/login.
                 *
                 * @type {string}
                 *     Takes the form "[username]-[token]".
                 */
                this.token = template.token || "";

                /**
                 * Locally stored API variable.
                 */
                this.apiBaseUrl = template.apiBaseUrl || "/api";
            };

            
            /**
             * Method that accepts a credentials dictionary and applies it to
             * the stored values (if applicable).
             *
             * @param {dict}
             *     Values: "username", "password", "token"
             */
            ManagedState.prototype.setCredentials = function(template) {
                template = template || {};

                this.username = template.username || "";
                this.password = template.password || "";
                this.token = template.token || "";
            };


            // You have to be careful using setCredentials since you may
            // inadvertantly clear the stored authorization token.


            /**
             * Method that checks the current Authentication status.
             *
             * @returns {bool}
             *     True if authenticated.
             */
            ManagedState.prototype.isAuthenticated = function() {
                return this.token !== "";
                // Note that this method checks whether or not there is a token
                // stored in the AuthManager instance.  There must be care taken
                // to reset the token whenever a token is expired by the API to
                // maintain run-time consistency between the SPA and the API.
            };
            
            
            /**
             * Method that resets the currently stored token.
             */
            ManagedState.prototype.resetToken = function() {
                this.token = "";
            };
            
            
            /**
             * Method that queries the /core/login POST end-point and handles
             * responses.
             *
             * This method does not have any explicit inputs, but relies on
             * username and password values stored in the particular instance.
             *
             * @returns {dict} respData
             *     Values: "status", "message"
             */
            ManagedState.prototype.login = function() {
                // Create local variable reference to 'this' to avoid prototype
                // linking errors.
                var thisObj = this;

                var respData = {};
                
                // Create the request object.
                var req = {
                    method: 'POST',
                    url: thisObj.apiBaseUrl + '/core/login',
                    headers: {},
                    contentType: 'application/json',
                    data: JSON.stringify(
                        {
                            "username": thisObj.username,
                            "password": thisObj.password
                        }
                    ),
                };
                
                // Return the request promise.
                return $http(req)
                    .success(function(data, status, headers, config) {
                        if (data.status == '0' || 
                            data.status == '-2') {
                            // Store the taken in the instance.
                            thisObj.token = data.token;
                        }
                        
                        respData.status  = data.status;
                        respData.message = data.message;
                    })
                    .error(function(data, status, headers, config) {
                        $log.error("Query to login API endpoint failed. " +
                                   "[auth.AuthManager.login()]");
                        
                        respData.status  = "-10000";
                        respData.message = ("HTTP (" + 
                                            status +
                                            ") error.");
                        
                        $log.error(respData.message);
                    })
                    .then(function() {
                        return respData;
                    });
            };
            
            
            /**
             * Method that queries the /core/login DELETE end-point and handles
             * responses.
             *
             * This method does not have any explicit inputs, but relies on the
             * token value stored in the instance.
             *
             * @returns {dict} respData
             *     Values: "status", "message"
             */
            ManagedState.prototype.logout = function() {
                // Create local variable reference to 'this' to avoid prototype
                // linking errors.
                var thisObj = this;
                
                var respData = {};
                
                // Create the request object.
                var req = {
                    method: 'DELETE',
                    url: thisObj.apiBaseUrl + '/core/login',
                    headers: {'X-Core-Token': thisObj.token},
                    contentType: 'application/json',
                    data: JSON.stringify(
                        {}
                    )
                };
                
                // Return the request promise.
                return $http(req)
                    .success(function(data, status, headers, config) {
                        // Clear stored variables that make sense for logout.
                        thisObj.password = "";
                        thisObj.token    = "";
                        
                        respData.status  = data.status;
                        respData.message = data.message;
                    })
                    .error(function(data, status, headers, config) {
                        $log.error("Query to the login API endpoint failed. " +
                                   "[auth.AuthManager.logout()]");
                        
                        respData.status  = "-10000";
                        respData.message = ("HTTP (" + 
                                            status + 
                                            ") error.");
                        
                        $log.error(respData.message);

                        // Hard reset location and vars (something breaks
                        // promise chaining when $http returns error).  This
                        // should be investigated further later.
                        thisObj.password = "";
                        thisObj.token    = "";
                        $location.path("/login");
                    })
                    .then(function() {
                        return respData;
                    });
            };
            
            
            /**
             * Method that queries /core/password POST (password recovery) and
             * handles responses.
             *
             * This method does not have any explicit inputs, but relies on the
             * username stored in the instance.
             *
             * @returns {dict} respData
             *     Values: "status", "message"
             */
            ManagedState.prototype.recoverPassword = function() {
                // Create local variable reference to 'this' to avoid prototype
                // linking errors.
                var thisObj = this;
                
                var respData = {};
                
                // Create the request object.
                var req = {
                    method: 'POST',
                    url: thisObj.apiBaseUrl + '/core/password',
                    headers: {},
                    contentType: 'application/json',
                    data: JSON.stringify(
                        {
                            "username": thisObj.username,
                        }
                    )
                };
                
                // Return the request promise.
                return $http(req)
                    .success(function(data, status, headers, config) {
                        respData.status  = data.status;
                        respData.message = data.message;
                    })
                    .error(function(data, status, headers, config) {
                        $log.error("Query to the login API endpoint failed. " +
                                   "[auth.AuthManager.logout()]");
                        
                        respData.status  = "-10000";
                        respData.message = ("HTTP (" + 
                                            status + 
                                            ") error.");
                        
                        $log.error(respData.message);
                    })
                    .then(function() {
                        return respData;
                    });
            };
            
            
            /**
             * Method that queries /core/password PUT (password reset) and
             * handles responses.
             *
             * This method requires the username, password, and token values
             * that are stored in the instance.  This means that a 'successful'
             * login must have been made before attempting to use this method.
             *
             * @param {string} newpassword
             *
             * @returns {dict} respData
             *     Values: "status", "message"
             */
            ManagedState.prototype.resetPassword = function(newpassword) {
                // Create local variable reference to 'this' to avoid prototype
                // linking errors.
                var thisObj = this;
                
                var respData = {};
                
                // Create the request object.
                var req = {
                    method: 'PUT',
                    url: thisObj.apiBaseUrl + '/core/password',
                    headers: {'X-Core-Token': thisObj.token},
                    contentType: 'application/json',
                    data: JSON.stringify(
                        {
                            "username": thisObj.username,
                            "oldpassword": thisObj.password,
                            "newpassword": newpassword
                        }
                    )
                };
                
                // Return the request promise.
                return $http(req)
                    .success(function(data, status, headers, config) {
                        if (data.status == '0') {
                            thisObj.password = newpassword;
                    }
                        
                        respData.status  = data.status;
                        respData.message = data.message;
                    })
                    .error(function(data, status, headers, config) {
                        $log.error("Query to the login API endpoint failed. " +
                                   "[auth.AuthManager.logout()]");
                        
                        respData.status  = "-10000";
                        respData.message = ("HTTP (" + 
                                            status + 
                                            ") error.");
                        
                        $log.error(respData.message);
                    })
                    .then(function() {
                        return respData;
                    });
            };
            
            
            return ManagedState;
        }
    ]);
    
}) ();
