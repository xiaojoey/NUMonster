# NUMonster
A tool for mining atomic coordinate data for macromolecular complexes in the RCSB Protein Data Bank

This code contains the express server for the file upload and job query. Launch the server on by 
calling `npm start`. The default port is 9001.

### Local Development
Call `. test/test_env.sh` to set the appropriate environmental variables for local development and testing. 
Call `npm run devstart` to launch a daemon that will restart the server on changes to the `server.js` file