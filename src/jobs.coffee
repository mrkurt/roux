mongo = require('./mongo')
mongodb = require('mongodb')
_ = require('underscore')

class Storage
  constructor : (@db)->
    mongo.Database.check(@db)
    @manager = @db.collection('roux.jobs')
    @collection = @db.collection('system.js')

  get : (job, cb)->

  store : (job, cb)->
    completed = []
    callback = (err, result)->
      completed.push result
      if completed.length is 3
        cb(err, completed) if cb?
    @manager.save({_id : job.name}, {safe : true}, callback)
    @storeFunc("#{job.name}_#{m}", job[m], callback) for m in ["map", "reduce"]

  storeFunc : (name, f, cb)->
    @collection.save {_id : name, value : new @db.bson.Code(f)}, { safe : true }, (err, result)=>
      if err?
        @db.logger err
        throw new Error(err)
      cb(err, result) if cb?

exports.Storage = Storage

outputCollectionName = (out)->
  return out if typeof out is 'string'
  return false unless typeof out is 'object' && !out.inline
  return out.replace || out.reduce || out.merge

class Runner
  constructor : (@db)->
    mongo.Database.check(@db)
    @manager = @db.collection('roux.jobs')

  execWithIdRange : (job, collection, f)->
    maxId = false
    minId = false
    @db.serverTime (err, value)=>
      maxId = @db.objectIdFromTime(value) #builds smallest possible id for a given second

      outputName = outputCollectionName(job.out)
      lastIdPath = "collections.#{collection.name}"
      lastIdPath = "#{lastIdPath}.#{outputName}" if outputName
      lockField = "#{lastIdPath}.running"
      lock = {_id : job.name}
      lock[lockField] = {'$ne' : true}
      doc = {'$set' : {}}
      doc['$set'][lockField] = true
      sort = []
      console.log lock
      @manager.findAndModify lock, sort, doc, {upsert : true}, (err, doc)=>
        if !err && !doc
          err = {type : 'roux_error', message : 'job is already locked for that collection'}
        if err?
          f(err)
          return
        minId = doc.collections?[collection.name]?[outputName]?.lastId || false
        query = {'$lte' : maxId}
        query['$gt'] = minId if minId
        f(undefined, {_id : query})

  exec : (job, opts, cb)->
    cb = opts if typeof opts is 'function'
    opts = {} unless typeof opts is 'object'
    collection = @db.collection(opts.input || job.input)

    f = (err, query, finalize)=>
      if err?
        cb(err) if typeof cb is 'function'
        return

      query ||= {}
      o = {query : query, out: job.out, include_statistics: true}
      @collection.mapReduce job.map, job.reduce, o, (err, collection, stats)=>
        cb(err, collection, stats) if typeof cb is 'function'

    f(undefined, opts.query)

exports.Runner = Runner

