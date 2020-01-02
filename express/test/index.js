'use strict';
const test = require('tape');
const request = require('supertest');
var app = require('../server/');
const fs = require('fs');

//testing done using supertest and tape

//The xml string is taken from the test files
const xml = fs.readFileSync('./test/jobs/27rv13g098/27rv13g098.xml', 'utf8');
console.log(xml);
const newXml = "xml=" + xml;

//Checking that testing framework works
test('First test!', function(t){
    t.end();
});

//Testing the /jobxml endpoint
test('Testing XML', function(t) {
    request(app)
        .post('/jobxml')
        //passing the xml string
        .send(newXml)
        .expect('Content-Type', /json/)
        .expect(200)
        .end(function (err, res) {

            const expectedValue = '27rv13g098';
            const newFile = process.env.JOBS_DIR + '/27rv13g098/27rv13g098.xml';

            t.error(err, 'No Error');
            //Checking if it returns the correct job_id
            t.same(res.body, expectedValue, 'Data as expected');
            //Check if file is saved
            t.same(fs.existsSync(newFile), true, 'File saved');
            const newFileContent = fs.readFileSync(newFile, 'utf8');
            //Check if saved xml string is same
            t.same(newFileContent, xml, 'File content as expected');
            t.end();
        });
});

//might also need to test other endpoints
//private functions will be harder to test
