const express = require("express");
const bodyParser = require('body-parser');
const path = require('path');
const https = require('https');
const convert = require('xml-js');
const expressValidator = require('express-validator');
const upload = require("express-fileupload");
const fs = require('fs');
const cors = require('cors');

// Get environment variables
const PORT = process.env.PORT || 9001;
const SSL_KEY = process.env.SSL_KEY || 'server.key';
const SSL_CERT = process.env.SSL_CERT || 'server.cert';
const UPLOAD_DIR = process.env.UPLOAD_DIR || '/home/monster_uploads/uploads';
const UPLOAD_URL = process.env.UPLOAD_URL || 'http://monster.northwestern.edu/files/upload';
const JOBS_DIR = process.env.JOBS_DIR || '/home/monster_uploads/jobs';
const DL_URL = process.env.DL_URL || 'http://monster.northwestern.edu/jobs';


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

app.get('/results/:job_id', function(req, res) {
	const jobs_dir = `${JOBS_DIR}/${req.params.job_id}`;
	const dl_url = `${DL_URL}/${req.params.job_id}`;
	let response = {job_id: req.params.job_id};
	fs.readdirSync(jobs_dir).forEach(item => {
		if (fs.lstatSync(`${jobs_dir}/${item}`).isDirectory()) {
			let chains = [];
			response.models = {};
			response.models[item] = {};
			fs.readdirSync(`${jobs_dir}/${item}`).forEach(file => {
				// Assuming single character chain IDs
				if (file.match(/..bonds\.xml/)) {chains.push(file.slice(0,2))}
			});
			chains.forEach(chain => {
				const xml = fs.readFileSync(`${jobs_dir}/${item}/${chain}bonds.xml`, 'utf8');
				const parsed_xml = convert.xml2json(xml, {compact: true});
				response.models[item][chain] = {
					Results: {
						XML: `${dl_url}/${item}/${chain}bonds.xml`,
						TXT: `${dl_url}/${item}/${chain}bonds.txt`
                    },
					Logs: {
						MSMS: `${dl_url}/${item}/${chain}msms.log`,
						HBPlus: `${dl_url}/${item}/${chain}hb.log`
					},
					PDB: {
						PDB: `${dl_url}/${item}/${chain}.pdb`
					},
					parsed_bonds: parsed_xml
				}
			});
			res.send(response)
		}
	})

});

// handle uploads 
app.post('/upload', function(req, res) {
    let url_path;
    let file;
    // create a randomly named folder by appending a random number to the upload/ directory
	let epoch = (new Date).getTime().toString();
	let dir = UPLOAD_DIR + '/' + epoch;

	// while a folder of the same name exists, keep getting random numbers
	while (fs.existsSync(dir)) {
		dir = dir + "_new";
	}

	// create the directory upload the file to it
	fs.mkdirSync(dir);
	fs.chmodSync(dir, 0o777);
    if (req.body.pdbId) {
        let pdbID = req.body.pdbId.toLowerCase();
    	if (!RegExp('^[a-z0-9]{4}$').test(pdbID)) {
    		console.log('Bad PDB: ' + pdbID);
    		return res.status(400).send(`${pdbID} does not appear to be a valid PDB ID`);
		}
		const web_address = `https://files.rcsb.org/download/${pdbID}.pdb`;
    	const file_path = `${dir}/${pdbID}.pdb`;
    	file = fs.createWriteStream(file_path);
		https.get(web_address, function(response) {
			if (response.statusCode !== 200){
				console.log('Bad PDB Download: ' + pdbID);
				return res.status(400).send(`Failed to fetch a PDB file for ${pdbID} from RCSB`)
			}
			response.pipe(file).on('finish', function () {
				console.log('Download PDB from RCSB: ' + file_path);
				url_path = `${UPLOAD_URL}/${epoch}/${pdbID}.pdb`;
				parse(file_path, url_path, res);
			});
		});

    } else {
        // ensure files are uploaded
        if (!req.files) {
            return res.status(400).send('No files were upload.');
        }
        let pdb = req.files.pdbFile;

        file = dir + '/' + pdb.name;
        url_path = `${UPLOAD_URL}/${epoch}/${pdb.name}`;

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
	console.log('HTTP server started on port 9000')
});

https.createServer({
  key: fs.readFileSync(SSL_KEY),
  cert: fs.readFileSync(SSL_CERT)
}, app).listen(PORT, function () {
  console.log('https app listening on port ' + PORT)
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
