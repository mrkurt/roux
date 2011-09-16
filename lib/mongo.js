(function() {
  var Collection, Mongo, mongodb, url;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __slice = Array.prototype.slice;
  url = require('url');
  mongodb = require('mongodb');
  Mongo = (function() {
    function Mongo(uri, cb) {
      this.uri = uri;
      this.connecting = false;
      this.db = false;
      this.queue = [];
      this.logger = console.log;
      this.exec(cb);
    }
    Mongo.prototype.exec = function(cb) {
      var callback;
      if (!this.connecting || !this.db) {
        if (cb != null) {
          this.queue.push(cb);
        }
      } else {
        cb(void 0, this.db);
        return;
      }
      if (!this.connecting) {
        callback = __bind(function(err, db) {
          var c, _i, _len, _ref;
          this.db = db;
          _ref = this.queue;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            c = _ref[_i];
            c(err, this.db);
          }
          return this.queue = [];
        }, this);
        mongodb.connect(this.uri, {
          db: {
            autoReconnect: true
          }
        }, callback);
        this.connecting = true;
      }
    };
    Mongo.prototype.useCollection = function(name, cb) {
      this.exec(__bind(function(error, db) {
        if (error != null) {
          this.logger(error);
          cb(error, void 0);
          return;
        }
        db.collection(name, cb);
      }, this));
    };
    Mongo.prototype.collection = function(name) {
      return new Collection(this, name);
    };
    return Mongo;
  })();
  Collection = (function() {
    function Collection(db, name) {
      this.db = db;
      this.name = name;
    }
    Collection.prototype.command = function() {
      var args, cb, cmd;
      cmd = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      cb = args[args.length - 1];
      if (typeof cb !== 'function') {
        cb = function(err, result) {
          return;
        };
      }
      return this.db.useCollection(this.name, __bind(function(error, c) {
        if (error != null) {
          this.db.logger(error);
          cb(error, void 0);
          return;
        }
        c[cmd].apply(c, args);
      }, this));
    };
    Collection.prototype.insert = function(docs, options, cb) {
      return this.command('insert', docs, options, cb);
    };
    Collection.prototype.update = function(selector, document, options, cb) {
      return this.command('update', selector, document, options, cb);
    };
    return Collection;
  })();
  exports.Mongo = Mongo;
}).call(this);
