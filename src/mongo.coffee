url         = require 'url'
mongodb     = require 'mongodb'

class Mongo
  constructor : (@uri, cb)->
    @connecting = false
    @db = false
    @queue = []
    @logger = console.log
    @exec(cb)

  exec : (cb)->
    if !@connecting || !@db
      @queue.push cb if cb?
    else
      cb(undefined, @db)
      return

    if !@connecting
      callback = (err, db)=>
        @db = db

        for c in @queue
          c(err, @db)

        @queue = []

      mongodb.connect @uri, {db : {autoReconnect : true}}, callback
      @connecting = true
    return

  useCollection : (name, cb)->
    @exec (error, db)=>
      if error?
        @logger(error)
        cb(error, undefined)
        return

      db.collection name, cb
      return
    return

exports.Mongo = Mongo
