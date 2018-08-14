var express = require("express"); 
var bodyParser = require('body-parser');
var path = require('path'); 
var expressValidator = require('express-validator');  
var upload = require("express-fileupload");
var fs = require('fs');
var cors = require('cors');


var app = express();
app.use(cors());


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
app.set('view engine', 'pug'); 
app.set('views', path.join(__dirname, 'views')); 

// route handler
app.get('/', function (req, res) {
	res.render('index', {
		chains : [], 
        pairs : []
	}); 
}); 

// handle uploads 
app.post('/upload', function(req, res) {
	
    // ensure files are uploaded
	if (!req.files) {
		return res.status(400).send('No files were upload.'); 
	}

	var pdb = req.files.pdbFile;

    // create a randomly named folder by appending a random number to the upload/ directory
	var epoch = (new Date).getTime().toString();
	var dir = '/home/monster_uploads/' + epoch;

    // while a folder of the same name exists, keep getting random numbers
	while (fs.existsSync(dir)) {
		dir = dir + "_new";
	}

    // create the directory upload the file to it
	fs.mkdirSync(dir);
	var file = dir + '/' + pdb.name; 

	pdb.mv(file, function (err) {
		if (err) {
			return res.status(500).send(err); 
		}
		fs.chmod(dir, 777);
		console.log('file uploaded: ' + file);
		// parse the file
		parse(file, res);
	});
});

app.listen(9000, function() {
	console.log('server started on port 9000')
}); 


// parses the uploaded pdb file. takes the folder as input 
function parse(file, res) {
	var chains = [],
		currID = false,
		startRes = false,
		endRes = false;
	fs.readFile(file, function(err, data) {
    	//if(err) throw err;
		// each index of the array holds a line of the pdb file
			var line,
    		lines = data.toString().split("\n");

		for (line of lines){
			//console.log(line);
			if ("ATOM" === line.slice(0,4)){
				if (!currID) {
                    currID = line.substring(21, 22).trim();
                    startRes = line.substring(22, 26).trim();
                }
                endRes = line.substring(22, 26).trim();
			}
			if ("TER" === line.slice(0,3)){
				if (!currID || !startRes) {
					throw "Parsing ERROR";
				}
				chains.push({"name": currID, "start":startRes, "end":endRes});
				currID = false;
			}
			// Only look at the first model to extract chains
			if ("ENDMDL" === line.slice(0,6)){
				break;
			}
		}
		if (!chains.length) {
            return res.status(500).send('Unable to parse chains from PDB file');
        }

		console.log(chains);

		res.send( {
			"file_path": file,
			"chains": chains,
		});
	});
}
