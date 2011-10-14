test = require('nodeunit')
roux = require('../')
fakeMongo = roux.fakeMongo

module.exports =
  "#runLikeMongo doesn't have node context" : (test)->
    error = false
    someTestObj = {var : 'asdf'}
    fn = ()->
      return 'ugh' if someTestObj.var is 'asdf'

    try
      fakeMongo.runLikeMongo fn
    catch err
      error = err

    test.ok error.type is 'not_defined', "expected a not_defined error"
    test.ok error.arguments[0] is 'someTestObj', "expected err on someTestObj: #{error.arguments[0]}"
    test.done()

  "#runLikeMongo accepts a custom context": (test)->
    someTestObj = {var : 'asdf'}
    fn = ()->
      return 'ugh' if someTestObj.var is 'asdf'

    mongo = fakeMongo.runLikeMongo fn, null, {someTestObj : someTestObj}
    test.ok mongo.result = "ugh"
    test.done()

  "#runLikeMongo accepts a custom scope" : (test)->
    someTestObj = {var : 'asdf'}
    fn = ()->
      return 'ugh' if this.someTestObj.var is 'asdf'

    mongo = fakeMongo.runLikeMongo fn, {someTestObj : someTestObj}
    test.ok mongo.result is "ugh"
    test.done()

  "#runLikeMongo accepts args" : (test)->
    fn = (t1,t2)->
      return t1 + t2

    mongo = fakeMongo.runLikeMongo fn, null, null, 10, 20
    test.ok mongo.result is 30, "Expected t1 + t2 to equal 30"
    test.done()
