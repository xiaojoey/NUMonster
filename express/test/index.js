'use strict';
const test = require('tape');
const request = require('supertest');
var app = require('../server/');
const fs = require('fs');

//The xml string is taken from the test files
var xml = fs.readFileSync('./test/jobs/27rv13g098/27rv13g098.xml', 'utf8');
console.log(xml);
xml = "xml=" + xml;

//Checking that testing framework works
test('First test!', function(t){
    t.end();
});

//Testing the /jobxml endpoint's ability to return the correct job_id when passed the xml string
test('Testing XML', function(t) {
    request(app)
        .post('/jobxml')
        .send(xml)
        .expect('Content-Type', /json/)
        .expect(200)
        .end(function (err, res) {
            var expectedValue = '27rv13g098';
            t.error(err, 'No Error');
            t.same(res.body, expectedValue, 'Data as expected');
            t.end();
        });
});
