var express = require("express"); 
var bodyParser = require('body-parser');
var path = require('path'); 
var expressValidator = require('express-validator');  
var upload = require("express-fileupload");
var fs = require('fs');
var mkdirp = require('mkdirp'); 

var app = express(); 


// order important, must put middleware before route handler 


// body parser middleware 
app.use(bodyParser.json()); 
app.use(bodyParser.urlencoded({extended: false})); 
app.use(upload()); 

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

// handle uploads 
app.post('/upload', function(req, res) {
	
	if (!req.files) {
		return res.status(400).send('No files were upload.'); 
	}

	var pdb = req.files.pdbFile; 
	var d = new Date(); 

	var append = 0; 
	var dir = './upload/' + append;

	while (fs.existsSync(dir)) {
		append = Math.floor(Math.random() * 1000000000) + d.getFullYear() + d.getMonth() + d.getDate() +  + d.getMilliseconds(); 
		dir = './upload/' + append; 
	}

	fs.mkdirSync(dir);
	var file = dir + '/' + pdb.name; 

	pdb.mv(file, function (err) {
		if (err) {
			return res.status(500).send(err); 
		}
		console.log("here"); 
	}); 
	console.log(pdb.name); 
	console.log('file uploaded'); 
	res.render('index'); 

	// parse the file 
	parse(file); 
}); 

app.listen(9000, function() {
	console.log('server started on port 9000')
}); 


// parses the uploaded pdb file. takes the folder as input 
function parse(file) {
	var array; 
	fs.readFile(file, function(err, data) {
    	if(err) throw err;
    	array = data.toString().split("\n");
	    for(i in array) {
	        console.log(array[i]);
	    }
	});
}



















