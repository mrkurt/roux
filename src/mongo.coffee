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

  collection : (name)->
    new Collection(@, name)

class Collection
  constructor : (@db, @name)->

  command : (cmd,args...)->
    cb = args[args.length - 1]
    unless typeof cb is 'function'
      cb = (err, result)-> undefined

    @db.useCollection @name, (error, c)=>
      if error?
        @db.logger error
        cb(error, undefined)
        return
      c[cmd].apply(c, args)
      return

  insert : (docs, options, cb)->
    @command('insert', docs, options, cb)

  update : (selector, document, options, cb)->
    @command('update', selector, document, options, cb)

exports.Mongo = Mongo
