url         = require 'url'
mongodb     = require 'mongodb'

class Database
  constructor : (@uri, cb)->
    @connecting = false
    @db = false
    @queue = []
    @logger = console.log
    @exec(cb)
    @bson = mongodb.BSONPure

  exec : (cb)->
    if !@connecting || !@db
      @queue.push cb if cb?
    else
      cb(undefined, @db.db)
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

      @db.collection name, cb
      return
    return

  collection : (name)->
    new Collection(@, name)

  serverTime : (cb)->
    @exec (err)=>
      @db.eval 'new Date().getTime()', (err, result)=>
        cb(err, result)

  objectIdFromTime: (time)->
    unixTime = parseInt(time / 1000, 10)
    time4Bytes = mongodb.BinaryParser.encodeInt(unixTime, 32, true, true)
    hexString = ''
    for c in time4Bytes
      value = mongodb.BinaryParser.toByte(c)
      number = (value <= 15 && '0') || ''
      number = number + value.toString(16)
      hexString = hexString + number
    hexString = hexString + '0000000000000000'
    @bson.ObjectID.createFromHexString(hexString)

Database.check = (db)->
  unless typeof db is 'object' && db instanceof Database
    throw new Error("Invalid Mongo Database")
  return true

class Collection
  constructor : (@db, @name)->

  command : (cmd, args)->
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

#proxying collection methods
for m in ['insert', 'update', 'save', 'findAndModify']
  do(m)->
    Collection.prototype[m] = (args...)->
      @command(m, args)

exports.Database = Database
