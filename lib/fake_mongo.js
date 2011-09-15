(function() {
  var MongoContext, ObjectId, crypto, fs, mongodb, vm;
  var __hasProp = Object.prototype.hasOwnProperty, __slice = Array.prototype.slice;
  mongodb = require('mongodb');
  crypto = require('crypto');
  vm = require('vm');
  fs = require('fs');
  MongoContext = function(context) {
    var k, v;
    if (context != null) {
      for (k in context) {
        if (!__hasProp.call(context, k)) continue;
        v = context[k];
        this[k] = v;
      }
    }
  };
  MongoContext.prototype.hex_md5 = function(raw) {
    var h;
    h = crypto.createHash('md5');
    h.update(raw);
    return h.digest('hex');
  };
  MongoContext.prototype.ObjectId = ObjectId = function(raw) {
    var id;
    id = mongodb.pure().ObjectID(raw);
    id.getTimestamp = function() {
      return new Date(id.generationTime);
    };
    return id;
  };
  exports.runLikeMongo = function() {
    var args, context, emits, fn, scope, script;
    fn = arguments[0], scope = arguments[1], context = arguments[2], args = 4 <= arguments.length ? __slice.call(arguments, 3) : [];
    scope || (scope = {});
    args || (args = []);
    context = new MongoContext(context);
    context.emits = emits = [];
    context.emit = function(key, value) {
      return emits.push([key, value]);
    };
    context.scope = scope;
    context.args = args;
    context.log = function(msg) {
      return console.log(msg);
    };
    context.result = null;
    script = "result = (" + (fn.toString()) + ").apply(scope, args);";
    vm.runInNewContext(script, context, "op.js");
    return context;
  };
}).call(this);
