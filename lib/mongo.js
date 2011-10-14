(function() {
  var Collection, Database, m, mongodb, url, _fn, _i, _len, _ref;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __slice = Array.prototype.slice;
  url = require('url');
  mongodb = require('mongodb');
  Database = (function() {
    function Database(uri, cb) {
      this.uri = uri;
      this.connecting = false;
      this.db = false;
      this.queue = [];
      this.logger = console.log;
      this.exec(cb);
      this.bson = mongodb.BSONPure;
    }
    Database.prototype.exec = function(cb) {
      var callback;
      if (!this.connecting || !this.db) {
        if (cb != null) {
          this.queue.push(cb);
        }
      } else {
        cb(void 0, this.db.db);
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
    Database.prototype.close = function(cb) {
      return this.exec(__bind(function(error, db) {
        this.connecting = false;
        this.db.close(cb);
        return this.db = false;
      }, this));
    };
    Database.prototype.useCollection = function(name, cb) {
      this.exec(__bind(function(error, db) {
        if (error != null) {
          this.logger(error);
          cb(error, void 0);
          return;
        }
        this.db.collection(name, cb);
      }, this));
    };
    Database.prototype.collection = function(name) {
      return new Collection(this, name);
    };
    Database.prototype.serverTime = function(cb) {
      return this.exec(__bind(function(err) {
        return this.db.eval('new Date().getTime()', __bind(function(err, result) {
          return cb(err, result);
        }, this));
      }, this));
    };
    Database.prototype.objectIdFromTime = function(time) {
      var c, hexString, number, time4Bytes, unixTime, value, _i, _len;
      unixTime = parseInt(time / 1000, 10);
      time4Bytes = mongodb.BinaryParser.encodeInt(unixTime, 32, true, true);
      hexString = '';
      for (_i = 0, _len = time4Bytes.length; _i < _len; _i++) {
        c = time4Bytes[_i];
        value = mongodb.BinaryParser.toByte(c);
        number = (value <= 15 && '0') || '';
        number = number + value.toString(16);
        hexString = hexString + number;
      }
      hexString = hexString + '0000000000000000';
      return this.bson.ObjectID.createFromHexString(hexString);
    };
    return Database;
  })();
  Database.check = function(db) {
    if (!(typeof db === 'object' && db instanceof Database)) {
      throw new Error("Invalid Mongo Database");
    }
    return true;
  };
  Collection = (function() {
    function Collection(db, name) {
      this.db = db;
      this.name = name;
    }
    Collection.prototype.command = function(cmd, args) {
      var cb;
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
    return Collection;
  })();
  _ref = ['insert', 'update', 'save', 'findAndModify', 'find', 'findOne', 'mapReduce'];
  _fn = function(m) {
    return Collection.prototype[m] = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this.command(m, args);
    };
  };
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    m = _ref[_i];
    _fn(m);
  }
  exports.Database = Database;
}).call(this);
