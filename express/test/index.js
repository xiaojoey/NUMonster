use 'strict'
const test = require('tape');
const request = require('supertest');
const app = require('../sever/index.js');

test('First test!', function(t){
    t.end();
})

test('Testing XML', function(t) {
    request(app)
        .get('/jobxml')
        .expect('Content-Type', /json/)
        .expect(200)
        .end(function (err, res) {
            var expected value =
        })
}) 
