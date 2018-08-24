const express = require("express");
const bodyParser = require('body-parser');
const path = require('path');
const expressValidator = require('express-validator');
const upload = require("express-fileupload");
const fs = require('fs');
const cors = require('cors');


const app = express();
app.use(cors());


// order important, must put middleware before route handler 
// body parser middleware 
app.use(bodyParser.json()); 
app.use(bodyParser.urlencoded({extended: false})); 
app.use(upload()); 

// express validator middleware 
 app.use(expressValidator({
 	errorFormater: function (param, msg, value) {
 		let namespace = param.split('.');
 		let formParam = namespace.shift();

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
    let url_path;
    let file;
    if (req.body.pdbId) {
        let pdbID = req.body.pdbId.toLowerCase();
    	if (!RegExp('^[a-z0-9]{4}$').test(pdbID)) {
    		console.log('Bad PDB: ' + pdbID);
    		return res.status(400).send(`${pdbID} does not appear to be a valid PDB ID`);
		}
    	file = `/home/pdb-mirror/data/structures/all/pdb/pdb${pdbID}.ent.gz`;
		if (!fs.existsSync(file)){
			console.log('Missing PDB: ' + pdbID);
    		return res.status(400).send(`${pdbID} is not present in the local PDB cache. 
    		Please use the file upload`);
		}
		console.log('Using PDB cache: ' + file);
		url_path = `http://monster.northwestern.edu/files/pdb/pdb${pdbID}.ent.gz`;
		parse(file, url_path, res);

    } else {
        // ensure files are uploaded
        if (!req.files) {
            return res.status(400).send('No files were upload.');
        }
        let pdb = req.files.pdbFile;

        // create a randomly named folder by appending a random number to the upload/ directory
        let epoch = (new Date).getTime().toString();
        let dir = '/home/monster_uploads/upload/' + epoch;

        // while a folder of the same name exists, keep getting random numbers
        while (fs.existsSync(dir)) {
            dir = dir + "_new";
        }

        // create the directory upload the file to it
        fs.mkdirSync(dir);
        fs.chmod(dir, 0o777);
        file = dir + '/' + pdb.name;
        url_path = 'http://monster.northwestern.edu/files/upload/' + epoch + '/' + pdb.name;

        pdb.mv(file, function (err) {
            if (err) {
                return res.status(500).send(err);
            }
            console.log('file uploaded: ' + file);
            // parse the file
            parse(file, url_path, res);
        });
    }
});

app.listen(9000, function() {
	console.log('server started on port 9000')
}); 


// parses the uploaded pdb file. takes the folder as input 
function parse(file, url_path, res) {
    let chains = [];
    let currID = false;
    let startRes = false;
    let endRes = false;
    fs.readFile(file, function(err, data) {
    	if(err) throw err;
        let line;
        let lines = data.toString().split("\n");

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
        	console.log(`Failed to parse file\n ID: ${currID}\n Start Res: ${startRes}\n EndRes: ${endRes}`);
            return res.status(500).send('Unable to parse chains from PDB file');
        }

		console.log(chains);

		res.send( {
			"file_path": url_path,
			"chains": chains,
		});
	});
}
