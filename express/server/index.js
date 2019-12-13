const express = require("express");
const bodyParser = require('body-parser');
const path = require('path');
const https = require('https');
const convert = require('xml-js');
const expressValidator = require('express-validator');
const upload = require("express-fileupload");
const fs = require('fs');
const cors = require('cors');
const exec = require('child_process').exec;

// Get environment variables
const PORT = process.env.PORT || 9001;
const SSL_KEY = process.env.SSL_KEY;
const SSL_CERT = process.env.SSL_CERT;
const UPLOAD_DIR = process.env.UPLOAD_DIR || '/home/monster_uploads/upload';
const UPLOAD_URL = process.env.UPLOAD_URL || 'http://monster.northwestern.edu/files/upload';
const JOBS_DIR = process.env.JOBS_DIR || '/home/monster_uploads/jobs';
const DL_URL = process.env.DL_URL || 'http://monster.northwestern.edu/jobs';


const app = express();
app.use(cors());


// order important, must put middleware before route handler
// body parser middleware
app.use(bodyParser.urlencoded({extended: true}));
app.use(bodyParser.json());
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
	response.models = {};
	fs.readdirSync(jobs_dir).forEach(item => {
		if (fs.lstatSync(`${jobs_dir}/${item}`).isDirectory()) {
			let chains = [];
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
			})
		} else if (item.match(/consensus\.xml/)) {
			const chain = item.slice(0,2);
			if (!response.models.Consensus) {
                response.models.Consensus = {};
            }
            const xml = fs.readFileSync(`${jobs_dir}/${item}`, 'utf8');
			const parsed_xml = convert.xml2json(xml, {compact: true});
            response.models.Consensus[chain] = {
				Results: {
						XML: `${dl_url}/${chain}consensus.xml`,
						TXT: `${dl_url}/${chain}consensus.txt`
                    },
				parsed_bonds: parsed_xml
			}

		}
	});
	res.send(response);
});

// handle uploads
app.post('/upload', function(req, res) {
    let url_path;
    let file;
    let email = req.body.email;
    console.log(req.body.email)
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

//This endpoint takes xml requests, parses the job_id, saves the xml string
//to a local file and calls the shell script

app.post('/jobxml', function (req, res) {
    //file is directory to store the xml string
    //will need to be changed to the correct directory later
    let file = JOBS_DIR;
    if(!fs.existsSync(file)){
        fs.mkdirSync(file);
    }
    let xml ='';
    let job_id = req.body.job_id;
    //regex string matching to find job_id from xml string
    let regex = /index='([^']*)/;
    //sh is the location of the shell script that activates monster_web
    let sh = './perlbackend.sh';
    //gets xml sent in the request
    console.log(req.body)
    console.log(req.headers)
    xml = req.body.xml;
    //finds job_id
    console.log(xml)

    if(job_id == null){
        job_id = xml.match(regex)[1];
    }

    console.log(job_id);

    //calls the makeXMLFile()function to save the xml string in a file
    //saves the xml string to the monster_uploads directory
    makeXMLFile(job_id, file, xml, (err) => {
        let message = (err) ? err : job_id + '.xml has been saved';
        console.log(message);
        //returns the job_id
        res.json(job_id);
        if(!err){
            //activates the shell script that starts the perl backend
            //passes the shell script the job_id
            exec(sh + ' '+ job_id, (error, stdout, stderr) => {
                   console.log(stdout);
                   console.log(stderr);
                   if (error !== null) {
                       console.log(`exec error: ${error}`);
                   }
            });
        }
    });
});

//exports as a module to enable unit testing
module.exports = app;

if (SSL_CERT) {
    https.createServer({
        key: fs.readFileSync(SSL_KEY),
        cert: fs.readFileSync(SSL_CERT)
    }, app).listen(PORT, function () {
        console.log('https app listening on port ' + PORT)
    });
}


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

//takes the job_id, the path for the upload directory, and the xml string
//saves the xml string to the upload directory in a xml file
function makeXMLFile(job_id, file, xml, callback) {
    //makes a new filepath
    let dirxml = file  + '/' + job_id;
    let i = 2;
    //if directory exists then create a new one with a different version number
    let olddir = dirxml;
    while(fs.existsSync(dirxml)){
        dirxml = olddir + '-' + i;
        i++;
    }

    //makes the directory with the file path generated
    fs.mkdirSync(dirxml);
    console.log('New folder created!');
    //changes permissions on the directory
    fs.chmodSync(dirxml, 0o777);
    filexml = dirxml + '/' + job_id + '.xml';
    //makes the new xml file and writes to it
    fs.writeFile(filexml, xml, (err) => {
        if (err) callback(err);
        console.log('The xml file has been saved!');
        callback(err);
    });
}
