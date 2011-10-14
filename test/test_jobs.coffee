test = require('nodeunit')
jobs = require('../src/jobs')
mongo = require('../src/mongo')

db = new mongo.Database("mongodb://localhost/roux_test")
runner = new jobs.Runner(db)

testJob =
  name: "test"
  out : 
    inline: true
  map : ()->
    emit('doc', 1)

  reduce : (key, values)->
    value = 0
    for v in values
      value = value + v
    return value

docs = [{_id: 1},{_id:2},{_id:3},{_id:4}]
testJobExec = (test, expectedCount)->
  c = db.collection('mr_test_input')
  job = testJob
  f = ()->
    c.insert docs, ()->
      runner.exec job, {input : 'mr_test_input'}, (err, collection, stats)->
        test.equal docs.length, collection[0]?.value, "map reduce should have counted the docs"
        test.done()
  c.command('drop', [f])

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

  "Runner#execWithIdRange should give a min ID, sometimes": (test)->
    f = (err, query)->
      test.ok query._id?['$lte'], 'Expected and upper range on query'
      test.ok query._id?['$gt'], 'Expected a lower range on query'
      test.done()

    job = {'$set' : {'collections.test_input.__inline__.lastId' : 'asdf'}}
    c = db.collection('test_input')
    db.collection('roux.jobs').update {_id : 'test'}, job, {safe: true,upsert: true}, (err, result)->
      runner.execWithIdRange(testJob, c, f)

  "Runner#exec should run mapReduce" : (test)->
    testJobExec(test, docs.length)

  "Runner#exec should run incremental mapReduce" : (test)->
    job = {'$set' : {'collections.mr_test_input.__inline__.lastId' : 2}}
    c = db.collection('mr_test_input')
    db.collection('roux.jobs').update {_id : 'test'}, job, {safe: true, upsert: true}, (err, result)->
      testJobExec(test, 2)
