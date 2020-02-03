'use strict';

require('dotenv').config();
const fs = require('fs');
const https = require('https');
const http = require('http');
const SSL_KEY = process.env.SSL_KEY;
const SSL_CERT = process.env.SSL_CERT;

var server = require('./server/index.js');
var port = process.env.PORT;

if (SSL_CERT) {
    https.createServer({
        key: fs.readFileSync(SSL_KEY),
        cert: fs.readFileSync(SSL_CERT)
    }, server).listen(port, function () {
        console.log('https app listening on port ' + port)
    });
} else {
    http.createServer({}, server).listen(port, function () {
      console.log('Server running on port %d', port);
    });
}
