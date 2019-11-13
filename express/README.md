Call `npm install` to install all the dependencies.

Call `npm start`to start the server. The code for the server is in server/index.js and get exported to index.js. It will listen to port 9001 by default.

Call `npm test` to run the tests in test/index.js. The test checks that the /jobxml endpoint works properly using the xml string in test/jobs/27rv13g098/27rv13g098.xml.

The xml string passed to the /jobxml endpoint is currently saved to monster_uploads. /jobxml will execute perlbackend.sh.

The shell script will echo the job_id to ./monster_web which should start perl script.
