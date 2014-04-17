// Generated by CoffeeScript 1.7.1
var File, ONE_HOUR, ONE_MONTH, ONE_WEEK, ONE_YEAR, createdDir, fs, path;

fs = require('fs');

path = require('path');

ONE_HOUR = 60 * 60;

ONE_WEEK = ONE_HOUR * 24 * 7;

ONE_MONTH = ONE_WEEK * 4;

ONE_YEAR = ONE_MONTH * 12;

createdDir = {};

File = (function() {
  function File(sitePayload, path, options) {
    this.sitePayload = sitePayload;
    this.path = path;
    this.options = options;
    this.headers = {
      'Vary': 'Accept-Encoding',
      'Connection': 'Keep-Alive'
    };
    this.resolvePath();
  }

  File.prototype.resolvePath = function(newPath) {
    if (newPath != null) {
      this.path = newPath;
    }
    this.path = path.relative(this.sitePayload.source, this.path);
    this.dirname = path.dirname(this.path);
    this.ext = path.extname(this.path);
    this.basename = path.basename(this.path, this.ext);
    this.fullpath = path.resolve(this.sitePayload.source, this.path);
    this.isHTML = this.ext === 'html' || this.ext === 'htm';
    this.isIndex = this.basename === 'index';
    this.calcHeaders();
    return this.calcURL();
  };

  File.prototype.calcHeaders = function() {
    this.status = this.options.defaultStatus;
    this.type = this.ext;
    if (this.options.gzip) {
      this.headers['Content-Encoding'] = 'gzip';
    }
    return this.headers['Cache-Control'] = (function(type) {
      var cc;
      if (/(text\/(cache-manifest|html|htm|xml)|application\/(xml|json))/.test(type)) {
        return cc = 'public,max-age=0';
      } else if (/application\/(rss\+xml|atom\+xml)/.test(type)) {
        return cc = 'public,max-age=' + ONE_HOUR;
      } else if (/image\/x-icon/.test(type)) {
        return cc = 'public,max-age=' + ONE_WEEK;
      } else if (/(image|video|audio|text\/x-component|application\/font-woff|application\/x-font-ttf|application\/vnd\.ms-fontobject|font\/opentype)/.test(type)) {
        return cc = 'public,max-age=' + ONE_MONTH;
      } else if (/(text\/(css|x-component)|application\/javascript)/.test(type)) {
        return cc = 'public,max-age=' + ONE_YEAR;
      } else {
        return cc = 'public,max-age=' + ONE_MONTH;
      }
    })(this.type) + ',no-transform';
  };

  File.prototype.calcURL = function() {
    var url;
    url = this.options.permalink ? this.options.permalink : this.sitePayload.permalink_style === 'pretty' ? this.isIndex && this.isHTML ? "/" + this.dirname + "/" : "/" + this.path : "/" + this.path;
    this.url = url.split('/').filter(function(part) {
      return !part.match(/^\.+$/);
    }).join('/');
    if (url.match(/\/$/)) {
      return this.url += "/";
    }
  };

  File.prototype.readJSON = function(callback) {
    var configPath;
    configPath = path.resolve(this.sitePayload.source, this.dirname, "_" + this.basename + this.ext + ".json");
    return fs.exists(configPath, (function(_this) {
      return function(exists) {
        if (exists) {
          deep_merge(_this.options, require(configPath), _this._options);
        }
        return typeof callback === "function" ? callback() : void 0;
      };
    })(this));
  };

  File.prototype.read = function(callback) {
    return fs.readFile(this.fullpath, (function(_this) {
      return function(err, data) {
        if (err) {
          return typeof callback === "function" ? callback(err) : void 0;
        }
        _this.source = data.toString();
        return typeof callback === "function" ? callback() : void 0;
      };
    })(this));
  };

  File.prototype.sendHeadersTo = function(res) {
    console.log("status: " + this.status);
    res.status(this.status);
    console.log("type: " + this.type);
    res.type(this.type);
    console.log("headers:");
    console.log(this.headers);
    res.set('Content-Length', this.output.length);
    if (this.output instanceof Stream) {
      res.set('Transfer-Encoding', 'chunked');
    }
    return res.set(this.headers);
  };

  File.prototype.sendTo = function(res) {
    this.sendHeadersTo(res);
    if (this.output instanceof Stream) {
      return this.output.pipe(res);
    } else {
      return res.end(this.output);
    }
  };

  File.prototype.clean = function() {
    delete this.source;
    delete this.resolvePath;
    delete this.calcHeaders;
    delete this.calcURL;
    delete this.readJSON;
    return delete this.read;
  };

  return File;

})();

module.exports.File = File;

//# sourceMappingURL=file.map