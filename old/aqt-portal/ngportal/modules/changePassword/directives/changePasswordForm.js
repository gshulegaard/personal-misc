(function() {
    
    /**
     * changePasswordForm
     *
     * This is a form directive that handles user requests for changing their
     * password.  Note that a lot of validation is done implicitly by logic
     * governing credentials that are currently stored in auth.AuthManager.
     */
    angular.module('changePassword').directive('changePasswordForm', function() {
         return {
             restrict: 'E',
             templateUrl: 'partials/changePassword/changePasswordForm.html',
             controller: function($scope, $log, MessageManager, Message) {
                 // Create self-store.
                 var changePasswordCtrl = this;

                 // API working variable.
                 this.apiProcessing = false;

                 // Create ng-model for changePasswordForm.
                 this.changePasswordForm = {
                     "newPassword": "",
                     "repeatPassword": ""
                 };

                 // Initialize MessageManager.
                 this.MessageManager = new MessageManager();


                 /**
                  * Change Password
                  */
                 
                 this.submitChange = function() {
                   
                     if (this.changePasswordForm.newPassword ==
                         this.changePasswordForm.repeatPassword) {
                         
                         this.apiProcessing = true;
                         
                         respData = $scope.AuthManager.resetPassword(
                             this.changePasswordForm.newPassword
                         );

                         // We have to use promise chaining in order to delay
                         // the following processing...LAME.
                         respData.then(function(result) {
                             
                             changePasswordCtrl.apiProcessing = false;

                             if (result.status == "0") {
                                 
                                 changePasswordCtrl.MessageManager.clearMessages();
                                 
                                 newMessage = new Message();
                                 newMessage.setMessage("Success",
                                                       result.message);

                                 changePasswordCtrl.MessageManager.addMessage(newMessage);

                                 changePasswordCtrl.changePasswordForm.newPassword = "";
                                 changePasswordCtrl.changePasswordForm.repeatPassword = "";

                             } else {
                                 
                                 changePasswordCtrl.MessageManager.clearMessages();

                                 newMessage = new Message();
                                 newMessage.setMessage("Error",
                                                       result.message);

                                 changePasswordCtrl.MessageManager.addMessage(newMessage);
                             }

                         });

                     } else {
                         
                         this.MessageManager.clearMessages();
                         
                         newMessage = new Message();
                         newMessage.setMessage("Error",
                                               "Passwords do not match.");

                         changePasswordCtrl.MessageManager.addMessage(newMessage);
                     }

                 };


                 /**
                  * Clean-up
                  */

                 // Function to run in order to clean up the state of the
                 // directive when being hidden from view.  This is useful in
                 // situations where the directive is being hidden rather than
                 // removed from the DOM.
                 this.closeModal = function() {
                     this.MessageManager.clearMessages();
                     $scope.changePasswordForm.$setPristine();
                 };
             },
             controllerAs: 'changePasswordCtrl'
         };
     });

}) ();
