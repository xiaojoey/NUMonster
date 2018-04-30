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

	// parse the file 
	var chainInfo = parse(file, res); 


}); 

app.listen(9000, function() {
	console.log('server started on port 9000')
}); 


// parses the uploaded pdb file. takes the folder as input 
function parse(file, res) {
	var lines; 
	var chains; 
	fs.readFile(file, function(err, data) {
    	if(err) throw err;

		// each index of the array holds a line of the pdb file 
    	lines = data.toString().split("\n");
		var len = lines.length;

		// split on space to allow access to individual words 
		for (var i = 0; i < len; i++) {
			lines[i] = lines[i].split(" "); 
		}

		var firstValid = 0; 

	    // get rid of extraneous begining parts  
		while (lines[firstValid][0] != "ATOM") {
			firstValid++;
		}
		lines.splice(0, firstValid); 

		len = lines.length; 

		// eliminate spaces 
		for (var i = 0; i < len; i++) {
			var trimmed = []; 
			var lineLength = lines[i].length; 

			for (var j = 0; j < lineLength; j++) {
				if (lines[i][j] != "") {
					trimmed.push(lines[i][j]); 
				}
			}
			lines[i] = trimmed; 
		}

		var currId = lines[0][4]; 
		chains = []; 
		var chain = new Chain(currId, 0, -1); 	

		for (var i = 0; i < len; i++) {
			if (lines[i][4] != currId && lines[i].length == 12) {
				chain.end = i - 1; 
				chains.push(chain); 
				currId = lines[i][4]; 
				chain = new Chain(currId, i, -1); 
			} else if (lines[i][0] == "MASTER" || lines[i][0] == "ENDMDL") {
				chain.end = i;
				chains.push(chain); 
				break; 
			}
		}

		// error checking writes to files chains.txt and read.txt 
		console.log(chains.length); 
		var print = ''; 
		for (var i = 0; i < chains.length; i++) {
			print += chains[i].id + "\n"; 	
		}
		fs.writeFile("chains.txt", print); 
		 
		var print = '';
		for (var i = 0; i < len; i++) {
			for (var j = 0; j < lines[i].length; j++) {
				print += lines[i][j] + " " ; 
			}
			print += "\n\n"; 

		}
		fs.writeFile("read.txt", print); 

		console.log("length of chains: " + chains.length); 


        // chainNames is the array of chains passed to pug 
		var chainNames = []; 

		for (var i = 0; i < chains.length; i++) {

            // lst is a dictionary mapping chain attributes to chain attribute values 
            var lst = {}; 
            lst["id"] = chains[i].id; 
            lst["start"] = chains[i].start;
            lst["end"] = chains[i].end;
			chainNames.push(lst); 
		}

        // chainpairs is the array of chain pairs passed to pug
        var chainPairs = []; 

        for (var i = 0; i < chains.length - 1; i++) {
            var start = chains[i].id; 
            for (var j = i + 1; j < chains.length; j++) {
                var pair = start + chains[j].id; 
                chainPairs.push(pair); 
            }
        }

		console.log("length of chainNames: " + chainNames.length); 

		console.log(chainNames[0]); 
        console.log("length of chainPairs: " + chainPairs.length); 
        console.log(chainPairs[0]); 

		res.render('index', {

            "pairs": chainPairs,
			"chains": chainNames 
		}); 


        console.log("just checking: " + chainPairs[1]); 

        console.log("just checking: " + chainPairs); 
        console.log("chainNames: " + chainNames);
	});
}






function Chain(id, start, end) {
	this.id = id; 
	this.start = start;
	this.end = end; 
}


function createChainList(chains) {

	for (chain in chains) {
		addItem(chain.id); 
	}
}



function addItem(name) {
        var ul = document.getElementById('chainList'); //ul
        var li = document.createElement('li');//li
        
        var checkbox = document.createElement('input');
            checkbox.type = "checkbox";
            checkbox.value = 1;
            checkbox.name = "todo[]";
        
        li.appendChild(checkbox);
        
        li.appendChild(document.createTextNode(name));
        ul.appendChild(li); 
}








