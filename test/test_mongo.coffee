test = require('nodeunit')
roux = require('../')
mongo = roux.mongo

db = false
testMongo = (cb)->
  db = new mongo.Database "mongodb://localhost/roux_test", cb
  db

module.exports = test.testCase
  setUp : (cb)->
    cb()
  tearDown : (cb)->
    if db
      db.close()
      db = false
    cb()

  "Storage#store should save job map/reduce" : (test)->
    test.done()

  "Database#constructor takes a URI and starts a connection" : (test)->
    m = testMongo (err, db)->
      test.equal "connected", db.state
      test.done()

  "Database#useCollection selects a collection properly" : (test)->
    m = testMongo()
    m.useCollection "beer", (error, c)->
      test.equal "beer", c.collectionName
      test.done()
  "Database#check should pass when valid db" : (test)->
    result = mongo.Database.check(testMongo())
    test.equal result, true, "Should have gotten true"
    test.done()

  "Database#check should throw when invalid db" : (test)->
    error = false
    try
      mongo.Database.check({notA : 'database'})
    catch err
      error = err
    test.notEqual error, false, "Expecting an exception"
    test.done()

  "Database#serverTime should return a valid time" : (test)->
    testMongo().serverTime (err, value)->
      test.equal 'number', typeof value, 'should have returned a number'
      test.done()

  "Database#objectIdFromTime should return an ObjectId": (test)->
    t = new Date().getTime()
    objectId = testMongo().objectIdFromTime(t)
    t = parseInt(t / 1000) * 1000 #objectIds only include second
    test.equal t, objectId.generationTime, "ObjectId and provided time don't match"
    test.done()

  "Collection#insert inserts a doc" : (test)->
    m = testMongo()
    col = m.collection('test_insert')
    col.insert {asdf : 'fdsa'}, {safe : true}, (err, result)->
      test[0]?.equal result.asdf, "fdsa"
      test.done()
  "Collection#update updates a doc" : (test)->
    m = testMongo()
    col = m.collection('test_update')
    col.update {id : 'non-existant'}, {asdf : 'jkml'}, {safe : true}, (err, result)->
      test.equal 0, result
      test.done()
