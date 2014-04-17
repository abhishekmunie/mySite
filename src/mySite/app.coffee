fs           = require 'fs'
url          = require 'url'
path         = require 'path'
http         = require 'http'
zlib         = require 'zlib'

express      = require 'express'
favicon      = require 'static-favicon'
logger       = require 'morgan'
cookieParser = require 'cookie-parser'
bodyParser   = require 'body-parser'

cachelicious = require 'cachelicious'

cacheliciousConnect = cachelicious.connect

module.exports.App = class App
  constructor: (@config) ->
    console.log @config.static_file.source
    @app = express()
    @app.set 'env', @config.env
    # @debug = if @app.get('env') is 'development' then require('debug') 'mySite-server' else ->
    @debug = require('debug') 'mySite-server'

    @staticCache  = cacheliciousConnect @config.static_file.source, maxCacheSize: @config.static_file.cache_size

  setPageHandler: (@pageHandler) ->

  setProxyHandler: (url, proxyHandler) ->
    @app.use url, proxyHandler

  configure: ->
    @app.use favicon()
    @app.use logger immediate: true, format: 'dev' if @app.get('env') is 'development'
    @app.use cookieParser @config.cookie_secret
    @app.use bodyParser.json()
    @app.use bodyParser.urlencoded()
    if @config.session.type is 'express'
      @app.use require('express-session') @config.session.config
    @app.enable 'trust proxy' if @config.trust_proxy

    if @config.force_https.enable is true
      @app.use (req, res, next) ->
        unless req.secure or req.headers['x-forwarded-proto'] == 'https'
          return res.redirect 301,
            (@config.force_https.host or req.headers.host) + req.path
        res.set 'Strict-Transport-Security': "max-age=#{@config.force_https.maxAge}#{@config.force_https.includeSubdomains ? "; includeSubDomains" : ""}"
        res.removeHeader('X-Powered-By')
        next()

    # @app.use '_update', (res, req,next) ->
    @app.use require('express-uncapitalize')() if @config.uncapitalize

    # @app.get /.*\/[^\.\/]*$/, (req, res, next) ->
    #   #res.redirect 303, path.join req.url, @config.index
    #   req.url = path.join req.url, @config.index
    #   next()

    # @app.get /\.(html|htm|xml|xhtml|xht)$/, @pageHandler

    ## static content handler
    @app.use (req, res, next) =>
      @debug "Checking static cache for #{req.url}"
      return next() if req.url[0] is '_' or req.url.indexOf('/_') >= 0
      # req.url = req.url.replace /^(.+)\.(\d+)\.(js|css|png|jpg|gif)$/, '$1.$3' if @config.cache_busting
      # try
      return @staticCache.apply @, arguments
      # catch e
      #   console.error e

    ## catch 404 and forwarding to error handler
    @app.use (req, res, next) ->
      err = new Error('Not Found')
      err.status = 404
      next(err)

    ## error handlers
    @app.use (err, req, res, next) ->
      console.error err
    if @app.get('env') is 'production'
      # production error handler
      # no stacktraces leaked to user
      @app.use (err, req, res, next) ->
        res.status err.status || 500
        if req.xhr
          res.send { error: 'Something blew up!' }
        else
          res.send 'Something blew up!'
    else if @app.get('env') is 'development'
      # development error handler
      # will print stacktrace
      @app.use (err, req, res, next) ->
        res.status err.status || 500
        if req.xhr
          res.send
            message: err.message
            error: err
        else
          res.send 'Something blew up!'
          res.send err

    # if @app.get('env') is 'development'
    #   @app.use require('connect-livereload')
    #     port: 35729

  start: (callback) ->
    @server = http.createServer(@app).listen @config.port, =>
      address = @server.address();
      callback?(address)
