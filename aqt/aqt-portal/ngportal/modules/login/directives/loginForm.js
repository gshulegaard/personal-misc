(function() {
    
    /**
     * loginForm
     *
     * This directive is a tightly bound form view and control that governs all
     * aspects of handling user login. 
     *
     * FD: The expired password handling could be handled by a separate
     * directive that is also embedded into the "login-page".  This would mean
     * adding visibility controls to the "LoginPageCtrl" which currently does
     * nothing.  Note that this is the motivation behind separating the expired
     * password handling from the login handling (separate MessageManagers and
     * ngModels).
     *
     * FD: Figure out a way to handle sessions in the future.  At the moment the
     * functionality is stubbed out.
     */
    angular.module('login').directive('loginForm', function() {
        return {
            restrict: 'E',
            templateUrl: '/partials/login/login-form.html',
            controller: function($scope, $http, $log, $location, 
                                 $cookies, MessageManager, Message) {
                /**
                 * Instance variables
                 */

                // Create self-store.
                var loginFormCtrl = this;

                // Create ngModel for Login Form.
                this.loginForm = {
                    "username": "",
                    "password": "",
                };

                // Create ngModel for Expired Password form.
                this.expiredForm = {
                    "newPassword": "",
                    "newPassword2": "",
                };

                // Expired password handling.
                this.expiredPassword = false;
                
                // Local API working variable.
                this.apiProcessing = false;

                // Message manager.
                this.MessageManager = new MessageManager();

                // Separate message manager for expired password form.
                this.expiredMessageManager = new MessageManager();


                /**
                 * Session Management
                 */

                // Local variable that tracks whether the session matches.
                this.thisSession = function() {
                    return $scope.SessionManager.validSession();
                };

                this.clearSession = function() {
                    $scope.SessionManager.overrideSession();
                };

                
                /**
                 * Login
                 */

                this.submitLogin = function() {
                    var thisObj = this;

                    // Set the AuthManager Credentials to match the ones in
                    // the login form.
                    $scope.AuthManager.setCredentials(this.loginForm);
                    
                    this.apiProcessing = true;
                    
                    // Then call the login method and store the promise.
                    respData = $scope.AuthManager.login();
                    
                    // We have to use promise chaining in order to delay the
                    // following logic...this is LAME.
                    respData.then(function(result) {

                        // Remove apiProcessing since promise has been
                        // fufilled.
                        thisObj.apiProcessing = false;

                        if (result.status == "0") {
                            // Success
                            
                            // Clear messages.
                            thisObj.MessageManager.clearMessages();
                            
                            // Remove locally stored credentials.
                            thisObj.loginForm.username = "";
                            thisObj.loginForm.password = "";
                            
                            // Make an AJAX request to load the config from
                            // the API in the $scope.ConfigManager.  This is
                            // an async HTTP request.
                            $scope.ConfigManager.loadConfig(
                                $scope.AuthManager.token
                            );
                            // Note that the token has to be passed in since
                            // $scope.ConfigManager does not have access to
                            // the local attributes of $scope.AuthManager.
                            
                            // Change route location.
                            $location.path('/applications');
                            
                        } else if (result.status == "-2") {
                            // Expired Password
                            
                            thisObj.MessageManager.clearMessages();
                            
                            // Create new Message.
                            newMessage = new Message();
                            newMessage.setMessage("Warning",
                                                  "Your password has expired, " +
                                                  "please choose a new one.");
                            // SOAP API is passing back erroneous message on 
                            // Expired password handling.  Hard wire message to 
                            // compensate.
                            
                            // Add message to Store.
                            thisObj.expiredMessageManager.addMessage(newMessage);
                                
                            thisObj.expiredPassword = true;
                            
                        } else {
                            // Error
                            
                            thisObj.MessageManager.clearMessages();
                            
                            // Create new Message.
                            newMessage = new Message();
                            newMessage.setMessage("Error",
                                                  result.message);
                            
                            // Add message to store.
                            thisObj.MessageManager.addMessage(newMessage);
                            
                        }
                            
                    });

                };

                
                /**
                 * Forgot Password
                 */

                this.submitForgotPassword = function() {
                    var thisObj = this;
                    
                    $scope.AuthManager.setCredentials(this.loginForm);

                    this.apiProcessing = true;

                    respData = $scope.AuthManager.recoverPassword();

                    // We have to use promise chaining in order to delay the
                    // following logic...LAME.
                    respData.then(function(result) {

                        thisObj.apiProcessing = false;

                        if (result.status == "0") {
                            // Success
                            
                            thisObj.MessageManager.clearMessages();
                            
                            // Create new message.
                            newMessage = new Message();
                            newMessage.setMessage("Success",
                                                  result.message);
                            
                            // Add message to store.
                            thisObj.MessageManager.addMessage(newMessage);
                            
                        } else {
                            // Error
                            
                            thisObj.MessageManager.clearMessages();
                            
                            // Create new message.
                            newMessage = new Message();
                            newMessage.setMessage("Error",
                                                  result.message);
                            
                            // Add message to store.
                            thisObj.MessageManager.addMessage(newMessage);
                            
                        }

                    });

                };


                /**
                 * Expired Password
                 */

                this.submitExpiredPassword = function() {

                    var thisObj = this;

                    if (this.expiredForm.newPassword ==
                        this.expiredForm.newPassword2) {

                        this.apiProcessing = true;
                        
                        respData = $scope.AuthManager.resetPassword(
                            this.expiredForm.newPassword
                        );

                        // We have to use promise chaining in order to delay the
                        // following logic... LAME.
                        respData.then(function(result) { 
                        
                            thisObj.apiProcessing = false;

                            if (result.status == "0") {
                                
                                thisObj.MessageManager.clearMessages();
                                thisObj.expiredMessageManager.clearMessages();

                                thisObj.expiredPassword = false;
                                
                                $location.path('/applications');

                            } else {
                            
                                thisObj.expiredMessageManager.clearMessages();
                                
                                newMessage = new Message();
                                newMessage.setMessage("Error",
                                                      result.message);
                                
                                thisObj.expiredMessageManager.addMessage(newMessage);

                            }
                           
                        });

                    } else {
                        
                        this.expiredMessageManager.clearMessages();
                        
                        newMessage = new Message();
                        newMessage.setMessage("Error",
                                              "Passwords do not match.");

                        this.expiredMessageManager.addMessage(newMessage);
                    }
                };
                
            },
            controllerAs: 'loginFormCtrl'
        };

    });

}) ();
