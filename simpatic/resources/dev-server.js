// https://www.npmjs.com/package/connect
// https://github.com/senchalabs/connect

// Requirements

// connect is a nodejs simple web server.
var connect = require('connect');
// Load the path nodejs API for use in creating a relative path.
var path = require('path');
// serve-static is a connect middleware for serving static files.
var serveStatic = require('serve-static');
// http is a nodejs API for handling http requests.
var http = require('http');


// Create a connect server object.
var app = connect();

// Create relative path the ngportal directory.
var relPath = path.join(__dirname, '../');

// Serve ngportal directory from the relative path.
var serveStatic = require('serve-static');
app.use(serveStatic(relPath));

//create node.js http server and listen on port
http.createServer(app).listen(5000)
