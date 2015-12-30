App = Ember.Application.create();

// Ember Definitions

App.Router.map(function() {
    // Web Frame
    this.resource('frame', function() {
        this.resource('applications');
        // Help
        // These pages are plain HTML, and therefore don't have controllers or
        // models.
        this.resource('printing');
        this.resource('uploading');
        this.resource('downloading');
        this.resource('touch-screens');
    });
});


// Index (Login)

// Return the model...
App.IndexRoute = Ember.Route.extend({
    model: function() {
        return credentials;
    }
});


// Frame

// Return the model...
App.FrameRoute = Ember.Route.extend({
   model: function() {
       var model = {}

       // Hit api.login POST view...
       $.ajax({
           type: "POST",
           url: credentials.api_url + "/login",
           contentType: "application/json",
           dataType: "json",
           async: false,
           data: JSON.stringify({
               'username': credentials.username,
               'password': credentials.password
           }),
           success: function(data) {
               // If success...
               if (data.status == '0') {
                   // Flip credentials.verified to "true" and set credentials.token.
                   verifyCredentials(true, data.token);
               } else {
                   verifyCredentials(false, '');
               }
           }
       });

       // Set verified variable to be passed to 'applications' view.
       model['verified'] = credentials.verified;

       return model;
   }
});

// Frame view...for foundation init.
// https://coderwall.com/p/azjwaq/how-to-initialize-foundation-in-your-ember-app
//App.FrameView = Ember.View.extend({
//    initFoundation: function () {
//        Ember.$(document).foundation()
//    }.on('didInsertElement')
//});

// Frame controller...
App.FrameController = Ember.ObjectController.extend({
    showMenu: false,

    actions: { 
        openMenu: function() {
            this.set('showMenu', true);
        },

        closeMenu: function() {
            this.set('showMenu', false);
        },

        exitEmberApp: function() {
            // Cleanup Guacamole database.
            $.ajax({
                type: "DELETE",
                url: credentials.api_url + "/webrdp",
                headers: { 'X-Core-Token': credentials.token },
                contentType: "application/json",
                dataType: "json",
                async: false,
                success: function(data) {
                    // Do nothing.
                }
            });

            // Call logout api.
            $.ajax({
                type: "DELETE",
                url: credentials.api_url + "/login",
                headers: { 'X-Core-Token': credentials.token },
                contentType: "application/json",
                dataType: "json",
                async: false,
                success: function(data) {
                    // Do nothing.
                }
            });
            
            // Reset persistent models.
            resetModels();
            
            // Redirect back to start.
            this.transitionToRoute('index');
        }
    },
});

// Applications

// Return the model...
App.ApplicationsRoute = Ember.Route.extend({
    model: function() {
        var model = {}

        // If credentials were verified...(i.e. received a token)
        // Note: This if may now be deprecated...leaving in case.
        if (credentials.verified) {
            // Query api applications POST view for application list.
            $.ajax({
                type: "POST",
                url: credentials.api_url + "/applications",
                headers: { 'X-Core-Token': credentials.token },
                contentType: "application/json",
                dataType: "json",
                async: false,
                data: JSON.stringify({
                    'username': credentials.username,
                }),
                success: function(data) {
                    // Set model to returned data.
                    model = data;

                    // Handlebars {{#each}} requires an array.
                    var array = [];

                    for (var key in model['application_list']) {
                        array.push(model['application_list'][key]['label']);
                    }

                    model['application_array'] = array;

                    // Handlebars is gimped...an only do 'if' on conditional.
                    var stupidatms = false;
                    var stupidmyatms = false;
                    var stupidconnect = false;

                    for (var key in model['application_list']) {
                        if (model['application_list'][key]['label'] == "ATMS") {
                            stupidatms = true;
                        }

                        if (model['application_list'][key]['label'] == "MyATMS") {
                            stupidmyatms = true;
                        }

                        if (model['application_list'][key]['label'] == "ATMS Connect") {
                            stupidconnect = true;
                        }
                    }

                    model['stupidatms'] = stupidatms;
                    model['stupidmyatms'] = stupidmyatms;
                    model['stupidconnect'] = stupidconnect;

                    // If there was an error returned.
                    if (data.status != '0') {
                        model['error'] = true;
                    } else {
                        model['error'] = false;
                    }
                }
            });            
        }

        // Set application comparison variables.
        model['atms'] = credentials.atms;
        model['myatms'] = credentials.myatms;
        model['connect'] = credentials.connect;

        return model;
        /*
          If you are performing multiple AJAX calls within the same function,
          they may step on eachother so you should set "async: false" (like
          above) to get around this.
        */
    }
});

// Applications controller...
App.ApplicationsController = Ember.ObjectController.extend({
    actions: {
        popGuacWindow: function(app_name) {
            // Create connection_tag to be passed to API.
            var guacVars = prepGuacVars(app_name);

            $.ajax({
                type: "POST",
                url: credentials.api_url + "/webrdp",
                headers: { 'X-Core-Token': credentials.token },
                contentType: "application/json",
                dataType: "json",
                async: false,
                data: JSON.stringify({
                    'password': credentials.password,
                    'app_name': guacVars.app_name,
                    'connection_tag': guacVars.connection_tag
                }),
                success: function(data) {
                    // If success...
                    if (data.status == '0') {
                        // Store returned connection_id in guacVars for use in
                        // creating URL.
                        guacVars['connection_id'] = data.connection_id;
                        guacVars['status'] = data.status;
                    } else {
                        guacVars['status'] = data.status;
                        guacVars['message'] = data.message;
                    }
                }
            });

            // If a connection_id was captured from .ajax call.
            if (guacVars.status == '0') {
                guacURL = createGuacURL(guacVars.connection_id);
                // Open a new window with URL pointed to Guac.
                window.open(guacURL);
            } else {
                // Display generic error.
                alert("Error!  " + guacVars.message);
            }
        },
 
        exitEmberApp: function() {
            // Call logout api.
            $.ajax({
                type: "DELETE",
                url: credentials.api_url + "/login",
                headers: { 'X-Core-Token': credentials.token },
                contentType: "application/json",
                dataType: "json",
                async: false,
                success: function(data) {
                    // Do nothing.
                }
            });
            
            // Reset persistent models.
            resetModels();
            
            // Redirect back to start.
            this.transitionToRoute('index');
        }
    },
});


// Persistent Models

var credentials = {
    username: '',
    password: '',
    token: '',
    verified: false,
    api_url: 'http://api.aqtsolutions.net',
    guac_url: 'http://guac.aqtsolutions.net',
};


// Functions

function resetModels() {
    // Reset credentials
    credentials.password = '';
    credentials.token= '';
    credentials.verified = false;
}

function verifyCredentials(bool, token) {
    credentials.verified = bool;
    credentials.token = token;
}

function prepGuacVars(app_name) {
    // Create connection_tag...
    connection_tag = credentials.username + app_name;

    return {
        app_name: app_name,
        connection_tag: connection_tag
    };
}

function createGuacURL(connection_id) {
    // Create url...
    guacURL = (credentials.guac_url + 
               '/#/client/c/' + 
               connection_id + 
               '/?username=' + 
               credentials.username + 
               '&password=' + 
               credentials.password);

    return guacURL;
}
