test = require('nodeunit')
Mongo = require('../src/mongo').Mongo

module.exports =
  "#constructor takes a URI and starts a connection" : (test)->
    m = new Mongo "mongodb://localhost/roux_test", (err, db)->
      test.equal "connected", db.state
      test.done()
  "#useCollection selects a connection properly" : (test)->
    m = new Mongo "mongodb://localhost/roux_test"
    m.useCollection "beer", (error, c)->
      test.equal "beer", c.collectionName
      test.done()
