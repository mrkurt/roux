(function() {
  var Mongo, mongodb, url;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
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
    return Mongo;
  })();
  exports.Mongo = Mongo;
}).call(this);
