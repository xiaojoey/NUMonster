var express = require("express"); 
var bodyParser = require('body-parser');
var path = require('path'); 
var expressValidator = require('express-validator');  
var upload = require("express-fileupload");
var fs = require('fs');
var mkdirp = require('mkdirp'); 

var app = express(); 


// order important, must put middleware before route handler 
/*
var logger = function (req, res, next) {
	console.log('Logging...'); 
	next(); 
}

app.use(logger); 
*/ 

// body parser middleware 
app.use(bodyParser.json()); 
app.use(bodyParser.urlencoded({extended: false})); 
app.use(upload()); 

// set static path
 //app.use(express.static(path.join(__dirname, 'public'))); 

// express validator middleware 
 app.use(expressValidator({
 	errorFormater: function (param, msg, value) {
 		var namespace = param.split('.')
 		, root = namespace.shift()
 		, formParam = root; 

 		while (namespace.length) {
 			formParam += '[' + namespace.shift() + ']'; 
 		}
 		return {
 			param : formParam,
 			msg : msg,
 			value : value
 		}; 
 	}
 })); 

// view engine 
app.set('view engine', 'ejs'); 
app.set('views', path.join(__dirname, 'views')); 

// route handler
app.get('/', function (req, res) {
	res.render('index'); 
}); 

app.post('/upload', function(req, res) {
	/*

	req.checkBody('require first name last name') 48 on 
	*/ 
	if (!req.files) {
		return res.status(400).send('No files were upload.'); 
	}

	var pdb = req.files.pdbFile; 
	var d = new Date(); 

	var append = Math.floor(Math.random() * 1000) + d.getFullYear() + d.getMonth() + d.getDate() +  + d.getMilliseconds(); 

	var dir = './upload/' + append; 
	if (!fs.existsSync(dir)) {
		fs.mkdirSync(dir); 
	}


	pdb.mv(dir + '/' + pdb.name, function (err) {
		if (err) {
			return res.status(500).send(err); 
		}
		console.log("here"); 
	}); 
	console.log(pdb.name); 
	console.log('file uploaded'); 
	res.render('index'); 

}); 

app.listen(9000, function() {
	console.log('server started on port 9000')
}) 

