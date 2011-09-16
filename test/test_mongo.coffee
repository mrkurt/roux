test = require('nodeunit')
Mongo = require('../src/mongo').Mongo

testMongo = (cb)->
  new Mongo "mongodb://localhost/roux_test", cb
module.exports =
  "#constructor takes a URI and starts a connection" : (test)->
    m = new Mongo "mongodb://localhost/roux_test", (err, db)->
      test.equal "connected", db.state
      test.done()
  "#useCollection selects a collection properly" : (test)->
    m = testMongo()
    m.useCollection "beer", (error, c)->
      test.equal "beer", c.collectionName
      test.done()
  "Collection#insert inserts a doc" : (test)->
    m = testMongo()
    col = m.collection('test_insert')
    col.insert {kurt : 'rocks'}, {safe : true}, (err, result)->
      test[0]?.equal result.kurt, "rocks"
      test.done()
  "Collection#update updates a doc" : (test)->
    m = testMongo()
    col = m.collection('test_update')
    col.update {id : 'non-existant'}, {asdf : 'jkml'}, {safe : true}, (err, result)->
      test.equal 0, result
      test.done()
