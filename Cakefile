fs            = require 'fs'
{print}       = require 'sys'
{spawn, exec} = require 'child_process'
{watchTree}   = require 'watch-tree'

build = (watch, callback) ->
  if typeof watch is 'function'
    callback = watch
    watch = false
  options = ['-c', '-o', 'lib', 'src']
  options.unshift '-w' if watch

  coffee = spawn 'coffee', options
  coffee.stdout.on 'data', (data) -> print data.toString()
  coffee.stderr.on 'data', (data) -> print data.toString()
  coffee.on 'exit', (status) -> callback?() if status is 0

task 'docs', 'Generate annotated source code with Docco', ->
  fs.readdir 'src', (err, contents) ->
    files = ("src/#{file}" for file in contents when /\.coffee$/.test file)
    docco = spawn 'docco', files
    docco.stdout.on 'data', (data) -> print data.toString()
    docco.stderr.on 'data', (data) -> print data.toString()
    docco.on 'exit', (status) -> callback?() if status is 0

task 'build', 'Compile CoffeeScript source files', ->
  build()

task 'watch', 'Recompile CoffeeScript source files when modified', ->
  build true

task 'test', 'Run tests', ->
  build ->
    {reporters}   = require 'nodeunit'
    do runTests = -> reporters.default.run ['test']

task 'autotest', 'Run the test suite continuously', ->
  build ->
    do runTests = ->
      exec "coffee -e \"{reporters} = require 'nodeunit'; reporters.default.run ['test']\"", \
           (error, stdout, stderr) ->
             print error if error
             print stdout if stdout
             print stderr if stderr
    testWatcher = watchTree 'test', 'sample-rate': 5
    testWatcher.on 'fileModified', runTests
    libWatcher = watchTree 'src', 'sample-rate': 5
    libWatcher.on 'fileModified', -> build(-> runTests())
