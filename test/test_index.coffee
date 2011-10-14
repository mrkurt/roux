test = require('nodeunit')
roux = require('../')

module.exports =
  "#fakeMongo exists" : (test)->
    test.ok roux.fakeMongo?, "Expected a fakeMongo on the roux instance"
    test.ok roux.fakeMongo?.runLikeMongo?, "Expected a runLikeMongo function"
    test.done()
