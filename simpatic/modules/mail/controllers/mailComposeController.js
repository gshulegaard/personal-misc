(function() {

    /**
     * The template controller for the compose route.
     *
     * This controller is part of the mail module and is bound by ngRoute in the
     * primary ng-app definition. 
     */
    angular.module('mail').controller('mailComposeController', function($scope, 
                                                                        $document,
                                                                        $window) {
        // Create self-store
        mailComposeController = this;


        // Handle placeholders...
        $document.bind("touch click", function() {
            // If one of the input fields is clicked, clear the placeholder content.
            if ( $(event.target).attr("contenteditable") == "true" && 
                 ( $(event.target).html() == "Subject" || 
                   $(event.target).html() == "Message..." )) {
                $(event.target).html("");
            }

            // Replace content of empty editable divs.
            if ( $(event.target).attr("class") !== 'subject' && 
                 $(".subject ").html() === "" ) {
                $(".subject").html("Subject");
            } else if ( $(event.target).attr("class") !== 'message' && 
                        $( ".message" ).html() === "" ) {
                $( ".message" ).html("Message...");
            }
        });


        /**
         * Helper function to calculate and set height of "message" input field
         * of compose form.
         */
        this.messageFieldHeight = function() {
            var TotalSpace, UsedSpace, RemainingSpace;
            
            TotalSpace = $(".compose-message").height();

            UsedSpace = ($(".message").offset().top - 
                         ($(".compose-message").offset().top + 15));

            // 12 total top/bot padding on .message.  45px for bottom controls
            // row (15px padding top).
            RemainingSpace = TotalSpace - UsedSpace - 12 - 60;

            $(".message").height(RemainingSpace);
        };


        /**
         * Debug function for displaying the message contents in the
         * contenteditable divs.
         */
        this.debugSend = function() {
            alert( $(".message").html() );
        };


        /**
         * Re-apply setHeight() on window height change.
         */
        $scope.$watch(
            function() {
                return $window.innerHeight;
            },
            function(newValue) {
                mailComposeController.messageFieldHeight();
            }
        );

    });

}) ();
