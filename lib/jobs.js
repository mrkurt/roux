(function() {
  var Runner, Storage, mongo, mongodb, outputCollectionName, _;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  mongo = require('./mongo');
  mongodb = require('mongodb');
  _ = require('underscore');
  Storage = (function() {
    function Storage(db) {
      this.db = db;
      mongo.Database.check(this.db);
      this.manager = this.db.collection('roux.jobs');
      this.collection = this.db.collection('system.js');
    }
    Storage.prototype.get = function(job, cb) {};
    Storage.prototype.store = function(job, cb) {
      var callback, completed, m, _i, _len, _ref, _results;
      completed = [];
      callback = function(err, result) {
        completed.push(result);
        if (completed.length === 3) {
          if (cb != null) {
            return cb(err, completed);
          }
        }
      };
      this.manager.save({
        _id: job.name
      }, {
        safe: true
      }, callback);
      _ref = ["map", "reduce"];
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        m = _ref[_i];
        _results.push(this.storeFunc("" + job.name + "_" + m, job[m], callback));
      }
      return _results;
    };
    Storage.prototype.storeFunc = function(name, f, cb) {
      return this.collection.save({
        _id: name,
        value: new this.db.bson.Code(f)
      }, {
        safe: true
      }, __bind(function(err, result) {
        if (err != null) {
          this.db.logger(err);
          throw new Error(err);
        }
        if (cb != null) {
          return cb(err, result);
        }
      }, this));
    };
    return Storage;
  })();
  exports.Storage = Storage;
  outputCollectionName = function(out) {
    if (typeof out === 'string') {
      return out;
    }
    if (out.inline) {
      return '__inline__';
    }
    return out.replace || out.reduce || out.merge;
  };
  Runner = (function() {
    function Runner(db) {
      this.db = db;
      mongo.Database.check(this.db);
      this.manager = this.db.collection('roux.jobs');
    }
    Runner.prototype.execWithIdRange = function(job, collection, query, f) {
      var maxId, minId;
      if (typeof query === 'function') {
        f = query;
      }
      if (typeof query !== 'object') {
        query = {};
      }
      maxId = false;
      minId = false;
      return this.db.serverTime(__bind(function(err, value) {
        var doc, lastIdPath, lock, lockField, outputName, sort;
        maxId = this.db.objectIdFromTime(value);
        outputName = outputCollectionName(job.out);
        lastIdPath = "collections." + collection.name;
        if (outputName) {
          lastIdPath = "" + lastIdPath + "." + outputName;
        }
        lockField = "" + lastIdPath + ".running";
        lock = {
          _id: job.name
        };
        lock[lockField] = {
          '$ne': true
        };
        doc = {
          '$set': {}
        };
        doc['$set'][lockField] = true;
        sort = [];
        return this.manager.findAndModify(lock, sort, doc, {
          upsert: true
        }, __bind(function(err, doc) {
          var range, _ref, _ref2, _ref3;
          if (!err && !doc) {
            err = {
              type: 'roux_error',
              message: 'job is already locked for that collection'
            };
          }
          if (err != null) {
            f(err);
            return;
          }
          minId = (_ref = doc.collections) != null ? (_ref2 = _ref[collection.name]) != null ? (_ref3 = _ref2[outputName]) != null ? _ref3.lastId : void 0 : void 0 : void 0;
          range = {
            '$lte': maxId
          };
          if (minId) {
            range['$gt'] = minId;
          }
          query['_id'] = range;
          return f(void 0, query);
        }, this));
      }, this));
    };
    Runner.prototype.exec = function(job, opts, cb) {
      var collection, f;
      if (typeof opts === 'function') {
        cb = opts;
      }
      if (typeof opts !== 'object') {
        opts = {};
      }
      collection = this.db.collection(opts.input || job.input);
      f = __bind(function(err, query) {
        var o;
        if (err != null) {
          if (typeof cb === 'function') {
            cb(err);
          }
          return;
        }
        query || (query = {});
        o = {
          query: query,
          out: job.out,
          include_statistics: true
        };
        return collection.mapReduce(job.map, job.reduce, o, __bind(function(err, collection, stats) {
          if (typeof cb === 'function') {
            return cb(err, collection, stats);
          }
        }, this));
      }, this);
      if (job.incremental) {
        return this.execWithIdRange(job, collection, opts.query, f);
      } else {
        return f(void 0, opts.query);
      }
    };
    return Runner;
  })();
  exports.Runner = Runner;
}).call(this);
