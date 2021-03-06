// Generated by CoffeeScript 1.7.1
var Page, crypto, fs, hogan, path, util, yaml, zlib, _,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

fs = require('fs');

path = require('path');

util = require('util');

zlib = require('zlib');

crypto = require('crypto');

yaml = require('js-yaml');

_ = require('lodash');

hogan = require('hogan.js');

module.exports.Page = Page = (function(_super) {
  __extends(Page, _super);

  function Page(sitePayload, path, options) {
    this.sitePayload = sitePayload;
    this.path = path;
    if (options == null) {
      options = {};
    }
    Page.__super__.constructor.call(this, this.sitePayload, this.path, options);
  }

  Page.prototype.getPayload = function() {
    return _.merge({}, this.options, {
      data: this.data
    });
  };

  Page.prototype.extractYAML = function() {
    yaml = this.source.match(/\A(---\s*\n.*?\n?)^(---\s*$\n?)/m);
    if (yaml) {
      deep_merge(this.options, yaml.safeLoad(yaml), this._options);
      return this.source.replace(/\A(---\s*\n.*?\n?)^(---\s*$\n?)/m, '');
    }
  };

  Page.prototype.compile = function() {
    return this.template = hogan.compile(this.source, this.options.hoganCompileOptions);
  };

  Page.prototype.init = function(callback) {
    return this.readJSON((function(_this) {
      return function() {
        return _this.read(function(err) {
          if (err) {
            return typeof callback === "function" ? callback(err) : void 0;
          }
          _this.extractYAML();
          _this.compile();
          return _this.update(function(err) {
            if (err) {
              return typeof callback === "function" ? callback(err) : void 0;
            }
            _this.clean();
            return typeof callback === "function" ? callback(null, _this) : void 0;
          });
        });
      };
    })(this));
  };

  Page.prototype.render = function() {
    this.rawOutput = this.template.render({
      site: this.sitePayload,
      page: this.getPayload()
    });
    if (!this.options.gzip) {
      return this.output = this.rawOutput;
    }
  };

  Page.prototype.gzip = function(callback) {
    return zlib.gzip(this.rawOutput, (function(_this) {
      return function(error, result) {
        if (error) {
          if (err) {
            if (typeof callback === "function") {
              callback(err);
            }
          }
        }
        _this.output = result;
        if (!_this.options.gzip.keepRawOutput) {
          delete _this.rawOutput;
        }
        return typeof callback === "function" ? callback(null, _this.output) : void 0;
      };
    })(this));
  };

  Page.prototype.update = function(callback) {
    this.sha1sum = crypto.createHash('sha1');
    this.render();
    if (this.options.gzip) {
      return this.gzip((function(_this) {
        return function(err, output) {
          if (err) {
            return typeof callback === "function" ? callback(err) : void 0;
          }
          _this.sha1sum.update(_this.output);
          _this.headers['ETag'] = _this.sha1sum.digest('hex');
          return typeof callback === "function" ? callback() : void 0;
        };
      })(this));
    } else {
      this.sha1sum.update(this.output);
      this.headers['ETag'] = this.sha1sum.digest('hex');
      return process.nextTick(function() {
        if (callback != null) {
          return callback();
        }
      });
    }
  };

  Page.prototype.clean = function() {
    Page.__super__.clean.call(this);
    delete this.extractYAML;
    return delete this.compile;
  };

  return Page;

})(require('./file').File);

module.exports.createPage = function(sitePayload, path, options, callback) {
  var _ref;
  if (typeof options === "function") {
    _ref = [options, null], callback = _ref[0], options = _ref[1];
  }
  return new Page(sitePayload, path, options).init(callback);
};

//# sourceMappingURL=page.map
