Be sure to maintain and update your version of node and npm. nvm is recommended for doing so: https://github.com/nvm-sh/nvm

The contents of package-lock.json may cause problems if the dependencies listed in package.json are significantly changed/updated, so, before running the commands below, it'll help to delete package-lock.json if you run into any major errors.

Call `npm install` to install all the dependencies.

Call `npm start`to start the server. The code for the server is in server/index.js and get exported to index.js. It will listen to port 9001 by default.

For testing purposes, the scripts rely on finding some hard-coded directories, but this can be bypassed by using the two environment variables:
UPLOAD_DIR and JOBS_DIR, so you should run: `export UPLOAD_DIR=./upload/` and `export JOBS_DIR=./jobs/` before calling the test script

Call `npm test` to run the tests in test/index.js. The test checks that the /jobxml endpoint works properly using the xml string in test/jobs/27rv13g098/27rv13g098.xml.

The xml string passed to the /jobxml endpoint is currently saved to monster_uploads. /jobxml will execute perlbackend.sh.

The shell script will echo the job_id to ./monster_web which should start perl script. This will likely fail due to the set of required perl dependencies, we will use a separate test perl script to show that the interaction between the JS and perl is working.
