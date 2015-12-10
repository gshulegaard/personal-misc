(function() {
    
    /**
     * appPageController
     *
     * The controller definition for the /applications route
     * (partials/applications/applications.html).
     */
    angular.module('applications').controller('appPageController', [
        '$scope', '$cookies', '$http', '$log', '$injector', '$location', 
        function($scope, $cookies, $http, $log, $injector, $location) {
            /**
             * Instance variables
             */

            // Guacamole required services.
            var $document     = $injector.get('$document');
            var $window       = $injector.get('$window');
            var guacAudio     = $injector.get('guacAudio');
            var guacVideo     = $injector.get('guacVideo');
            var ManagedClient = $injector.get('ManagedClient');

            // Create self-store.
            var appPageController = this;

            // API working variable.
            this.apiProcessing = true; // Initialize as true since an HTTP
                                       // request is fired on controller load.


            /**
             * Applications List
             */
            
            // This $http request runs when the controller is loaded.
            var req = {
                method: 'GET',
                url: $scope.AuthManager.apiBaseUrl + '/core/applications',
                headers: { 'X-Core-Token': $scope.AuthManager.token },
                contentType: 'application/json',
                data: JSON.stringify(
                    {}
                )
            };

            $http(req)
                .success(function(data, status, headers, config) {

                    if (data.status == '0') {
                        appPageController.appList = data.application_list;
                    }

                    appPageController.apiProcessing = false;

                })
                .error(function(data, status, headers, config) {

                    $log.error("Query to the applications API endpoint failed. " +
                               "[applications.appPageController]");
                    
                    appPageController.apiProcessing = false;

                    $log.error("HTTP (" + 
                               status + 
                               ") error.");

                    // FD: There should be some sort of error handling when the
                    // applications list fails to load.
                });


            /**
             * Guacamole Client Management
             */

            // Visibility variable governing display of guac-client.
            this.showClient    = false;
            // Focus variable governing control of keyboard input.
            this.activeClient  = false;
            // Keep track of current client that is visible.
            this.currentClient = null;
            // The currently visisble Guacamole client, if any.  If no
            // client is visible, this will be null.
            $scope.client      = null;

            // Loading gif/screen.
            this.loadingClient = false;
            
            this.loadingTimer = function() {
                // Wait three seconds and then remove loading screen.
                setTimeout(
                    function() {
                        appPageController.loadingClient = false;

                        $scope.$apply();
                    }, 
                    3000
                );
            };


            /**
             * Guacamole Client HTTP Query Parameters
             */

            var connectionParams = function(id) {
                
                // Calculate optimal dimensions for display
                var pixel_density  = $window.devicePixelRatio || 1;
                var optimal_dpi    = pixel_density * 96;
                var optimal_width  = $window.innerWidth * pixel_density;
                var optimal_height = $window.innerHeight * pixel_density;

                // Build base connect string
                var connectParams = 
                    "id="      + encodeURIComponent(id) +
                    "&width="  + Math.floor(optimal_width) +
                    "&height=" + Math.floor(optimal_height) +
                    "&dpi="    + Math.floor(optimal_dpi);

                // Add audio mimetypes.
                guacAudio.supported.forEach(function(mimetype) {
                    connectParams += "&audio=" + encodeURIComponent(mimetype);
                });

                // Add video mimetypes.
                guacVideo.supported.forEach(function(mimetype) {
                    connectParams += "&video=" + encodeURIComponent(mimetype);
                });

                // AQT Configuration

                var appName = function(id_num) {
                    switch(id_num) {
                        case '1':
                            return 'atms_core';
                        case '2':
                            return 'atms_web';
                        case '3':
                            return 'atms_mobile';
                        case '4':
                            return 'atms_connect';
                    }
                };

                var appAlias = '||' + appName(id);

                var remoteapp_parameters = function(connection,
                                                    username,
                                                    password,
                                                    isMobile) {
                    
                    if (isMobile == 'null'){
                        stringParams = 
                            'connection=' + connection + 
                            ' ' + 
                            'login=' + username + '/' + password + 
                            ' ' +
                            'webrdp';                           
                    } else {
                        stringParams = 
                            'connection=' + connection + 
                            ' ' + 
                            'login=' + username + '/' + password + 
                            ' ' +
                            'mobilerdp';                            
                    }
                    
                    return stringParams;
                    
                };
                
                // Add the two AQT values to the connect string.
                connectParams += 
                    "&server=" + 
                    encodeURIComponent($scope.ConfigManager.configObj.webrdp.server) + 
                    "&port=" + 
                    encodeURIComponent($scope.ConfigManager.configObj.webrdp.port) + 
                    "&username=" + 
                    encodeURIComponent($scope.ConfigManager.configObj.webrdp.username) +
                    "&password=" + 
                    encodeURIComponent($scope.ConfigManager.configObj.webrdp.password) + 
                    "&domain=" + 
                    encodeURIComponent($scope.ConfigManager.configObj.webrdp.domain) +
                    "&remote-app=" + 
                    encodeURIComponent(appAlias) + 
                    "&remote-app-parameters=" + 
                    encodeURIComponent(
                        remoteapp_parameters(
                            $scope.ConfigManager.configObj.webrdp.connection,
                            $scope.AuthManager.username,
                            $scope.AuthManager.password,
                            $cookies.get("isMobile")
                        )
                    );
                
                return connectParams;

            };

            /**
             * Client Start/Stop
             */

            // Create the client
            this.startClient = function(app) {
                this.client = ManagedClient.getInstance(
                    app,
                    connectionParams(app)
                );

                // Attach the client to the directive element.
                $scope.client = this.client;

                this.showClient = true;
                this.loadingClient = true;
                this.activateKeyboard();
                this.currentClient = app;

                this.loadingTimer();
            };

            // Disconnect and remove the client.
            this.stopClient = function() {
                this.client.client.disconnect();

                // Detach the client from the directive element.
                $scope.client = null;

                this.showClient = false;
                this.releaseKeyboard();
                this.currentClient = null;
                this.activeMenu = false;
                this.activeClipboard = false;

                // Reset clipboard position to default.
                $window.$("#clipboard-container").css({"top": "50px",
                                                       "left": "auto",
                                                       "right": "10px"});
            };

            
            /**
             * Guacamole Keyboard
             */

            // Create event listeners at the global level.
            var keyboard = new Guacamole.Keyboard($document[0]);

            // Broadcast keydown events
            keyboard.onkeydown = function onkeydown(keysym) {
                
                // Do not handle key events if not active client.
                if (!appPageController.activeClient)
                    return true;

                // If not prevented, fire corresponding keydown event.
                var guacKeydownEvent = $scope.$broadcast('guacKeydown',
                                                         keysym,
                                                         keyboard);

                return !guacKeydownEvent.defaultPrevented;

            };

            // Broadcast keyup events
            keyboard.onkeyup = function onkeyup(keysym) {
              
                // Do not handle key events if not active client.
                if (!appPageController.activeClient)
                    return;

                // If not prevented, fire corresponding keyup event
                $scope.$broadcast('guacKeyup', keysym, keyboard);
  
            };

            // Release all keys when window loses focus.
            $window.onblur = function() {
                keyboard.reset();
            };

            appPageController.releaseKeyboard = function() {
                this.activeClient = false;
            };

            this.activateKeyboard = function() {
                this.sendLocalClipboard();
                this.activeClient = true;
            };


            /**
             * Guacamole Menu (File Loading)
             */

            this.activeMenu = false;
            
            this.showMenu = function() {
                this.activeMenu = true;
                this.releaseKeyboard();
            };

            this.hideMenu = function() {
                this.activeMenu = false;
                this.activateKeyboard();
            };

            // Show file transfer menu if new file transfers have started.
            $scope.$watch(
                'client.uploads.length + client.downloads.length',
                function transfersChanged(count, oldCount) {
                    
                    // Show menu.
                    if (count > oldCount) {
                        thisCtrl.showMenu();
                    }
                    
                });


            /**
             * Clipboard (Guacamole copy/paste)
             */

            this.activeClipboard = false;

            this.toggleClipboard = function() {
                this.activeClipboard = !this.activeClipboard;
            };

            // Used for explicit hiding of the clipboard when other modals are
            // being opened.
            this.hideClipboard = function() {
                this.activeClipboard = false;
            };

            this.clipboardStyle = function() {
                if (this.activeClipboard) {
                    return {'color': '#FF5400'};
                } else {
                    return {};
                }
            };

            // Update the RDP clipboard.
            // For now this update is performed when the client resumes control
            // fo the keyboard. (see this.activateKeyboard())
            this.sendLocalClipboard = function() {
                $scope.$broadcast('guacClipboard', 'text/plain', $scope.client.clipboardData);
            };


            /**
             * Logout
             */

            this.logout = function() {
                respData = $scope.AuthManager.logout();

                respData.then(function(result) {
                    $location.path("/login");
                });
            };

        }

    ]);

}) ();
