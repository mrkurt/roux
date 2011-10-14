# Fake Mongo attempts to run javascript functions like Mongo would. JS runs
# with an empty scope (by default) and a context that includes emulated versions of some of the 
# MongoDB javascript library functions.
mongodb = require('mongodb')
crypto = require('crypto')
vm = require('vm')
fs = require('fs')

MongoContext = (context)->
  if context?
    for own k,v of context
      @[k] = v
  return

MongoContext::hex_md5 = (raw)->
    h = crypto.createHash('md5')
    h.update(raw)
    h.digest('hex')

MongoContext::ObjectId = ObjectId = (raw)->
  id = mongodb.pure().ObjectID(raw)
  id.getTimestamp = ()->
    new Date(id.generationTime)
  id

exports.runLikeMongo = (fn, scope, context, args...)->
  scope ||= {}
  args ||= []
  context = new MongoContext(context)
  context.emits = emits = []
  context.emit = (key,value)->
    emits.push [key, value]
  context.scope = scope
  context.args = args
  context.log = (msg)-> console.log(msg)
  context.result = null

  script = "result = (#{fn.toString()}).apply(scope, args);"

  vm.runInNewContext(script, context, "op.js")
  context
