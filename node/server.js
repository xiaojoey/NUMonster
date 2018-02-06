var http = require('http'); 
var formidable = require('formidable'); 
var fs = require('fs'); 

fs.readFile('index.html', function (err, html) {
	if (err) {
		throw err;
	}
	http.createServer(function(req, res) {
		response.writeHeader(200, {"Content-Ty"})
	})

})

