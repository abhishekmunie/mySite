// Generated by CoffeeScript 1.7.1
var DataGraph, DataSource, JSONDataSource, async, events, extract_ds_all_in, fs, getDataSource, grunt, path,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

fs = require('fs');

path = require('path');

async = require('async');

grunt = require('grunt');

events = require('events');

module.exports.DataGraph = DataGraph = (function(_super) {
  __extends(DataGraph, _super);

  function DataGraph() {
    return DataGraph.__super__.constructor.apply(this, arguments);
  }

  return DataGraph;

})(events.EventEmitter);

module.exports.DataSource = DataSource = (function() {
  function DataSource() {}

  DataSource.prototype.initDataSource = function() {};

  DataSource.prototype.initGenerator = function() {};

  return DataSource;

})();

module.exports.JSONDataSource = JSONDataSource = (function(_super) {
  __extends(JSONDataSource, _super);

  function JSONDataSource(json) {
    grunt.template.process(json);
  }

  JSONDataSource.prototype.initDataSource = function() {};

  JSONDataSource.prototype.initGenerator = function() {};

  return JSONDataSource;

})(DataSource);

getDataSource = function(data, options) {
  if (data instanceof DataSource) {
    return data;
  } else if (data.datasource instanceof DataSource) {
    return data.datasource;
  } else {
    return new JSONDataSource(data);
  }
};

extract_ds_all_in = function(dir, options, callback) {
  var list;
  return list = fs.readdir(dir, function(err, files) {
    var ds, extract;
    if (list.length === 0) {
      return typeof callback === "function" ? callback(err) : void 0;
    }
    ds = {};
    extract = function(file, callback) {
      var ext, fn;
      if (file === 'Icon\r' || /(^|\/)\./.test(file)) {
        return;
      }
      fn = path.resolve(dir, file);
      ext = path.extname(file);
      return fs.stat(fn, function(err, stats) {
        if (stats.isDirectory()) {
          return extract_ds_all_in(fn, function(err, datasources) {
            if (err) {
              return typeof callback === "function" ? callback(err) : void 0;
            }
            ds[file] = datasources;
            ds.setSite(this);
            return callback();
          });
        } else if (require.extensions[ext]) {
          return ds[path.basename(file, ext)] = getDataSource(require(fn), options);
        }
      });
    };
    return async.each(list, extract, function(err) {
      return typeof callback === "function" ? callback(err, ds) : void 0;
    });
  });
};

module.exports.readDataSources = function(src, options, callback) {
  var dsg;
  return dsg = extract_ds_all_in(src, options, callback);
};

//# sourceMappingURL=data-source.map
