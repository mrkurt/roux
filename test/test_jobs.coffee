test = require('nodeunit')
jobs = require('../src/jobs')
mongo = require('../src/mongo')

db = new mongo.Database("mongodb://localhost/roux_test")
runner = new jobs.Runner(db)

module.exports = test.testCase
  setUp : (cb)->
    callback = (err, result)-> cb()
    db.collection('roux.jobs').command('drop', [callback])
  tearDown : (cb)->
    db.close(cb)

  "Storage#store should save job map/reduce" : (test)->
    job = {name: 'testJob', map : (()-> "map"), reduce : (()-> "reduce")}
    s = new jobs.Storage(db)
    s.store job, (err, result)->
      test.equal 3, result.length, "expected two saved functions in mongo"
      test.done()

  "Runner#execWithIdRange should give a max ID" : (test)->
    f = (err, query)->
      test.ok query._id?['$lte'], "Expected an upper range on query"
      test.done()
    c = db.collection('test_input')
    job = {out : {'replace' : 'test_output'}, name : "test_job"}
    runner.execWithIdRange(job, c, f)
  "Runner#exec should run mapReduce" : (test)->
    test.done()
