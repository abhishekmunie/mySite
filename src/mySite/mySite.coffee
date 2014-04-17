fs             = require 'fs'
path           = require 'path'
_              = require 'lodash'
grunt          = require 'grunt'
coffee         = require 'coffee-script'
async          = require 'async'
util           = require 'util'

__             = require './helper'
app            = require './app'
page           = require './handlers/page'
proxy          = require './handlers/proxy'
redirect       = require './handlers/redirect'
data_source    = require './data-source'

module.exports.VERSION = '0.11.2'
module.exports.configConvict = configConvict = require './config'

pc = rc = prc = 0

if process.env["NODE_ENV"] == 'development'
  nvcr = require 'nock-vcr'
  nvcr.insertCassette 'requestCache'
  process.on 'exit', (code) ->
    nvcr.ejectCassette()
  #replay         = require 'replay'
  #replay.mode = "cheat"

debug = ->

module.exports.Site = class Site

  STATUS =
    initializing : "initializing"
    ready        : "ready"
    generating   : "generating"
    updating     : "updating"

  constructor: (options, callback) ->
    @status = STATUS.initializing

    @config = {}
    # Merge mySite::configConvict < _config.yml < _config.json < override
    config_yml = {}
    try config_yml = grunt.file.readYAML path.resolve options.source, '_config.yml' catch e
    configConvict.load config_yml
    configConvict.loadFile json_config_path if fs.existsSync json_config_path = path.resolve options.source, '_config.json'
    configConvict.load options
    unprocessed_options = configConvict.get()
    configConvict.load JSON.parse grunt.template.process JSON.stringify(unprocessed_options), data: unprocessed_options
    # perform validation
    configConvict.validate()

    @config = configConvict.get()

    if @config.env is 'development'
      debug = require('debug') 'mySite'
      debug "Using Config:\n #{util.inspect @config}"

    @source  = @config.source      = path.resolve @config.source
    @destination = @config.destination = path.resolve @config.destination if @config.destination?

    @date         = new Date()
    @dateString   = @date.toDateString()
    @timeString   = @date.toTimeString()

    @datasources = {}
    @model = {}

    @files        = {}
    @pages        = {}
    @redirects    = {}
    @proxies      = {}

    @responses    = {}

    @init callback

  init: (callback) ->
    console.time 'Initialization'
    console.time 'Reading'
    @read =>
      console.timeEnd 'Reading'
      @cleanup =>
        console.timeEnd 'Initialization'
        callback?()

  # Read Site data from disk and load it into internal data structures.
  #
  # Returns nothing.
  read: (callback) ->
    #@readDataSource =>
    #  @readPages callback
    @readPages callback


  readPages: (callback) ->
    c = 0
    e = false
    filesFound = []
    __.walkDirectory @source
    , (err) =>
      console.error err
    , (fn) =>
      c++
      filesFound.push fn
    , () =>
      pc = rc = prc = 0
      async.map filesFound, @createFile.bind(@), (err, files) =>
        return callback err if err?
        for file in files when file?
          @files[file.path] = file
          @responses[file.url] = file
        callback()

  createFile: (fn, callback) ->
    payload = @getPayload()
    if fn.match /\.(html|htm|xml)$/
      page.createPage @, fn, @config.page, (err, page) =>
        return callback err if err?
        @pages[page.url] = page
        callback null, page
    else if fn.match /\/\.redirect$/
      redirect.ceateRedirect @, fn, @config.redirect, (err, redirect) =>
        return callback err if err?
        @redirects[redirect.url] = redirect
        callback null, redirect
    else if fn.match /\/\.proxy$/
      proxy.createProxy @, fn, @config.proxy, (err, proxy) =>
        return callback err if err?
        @proxies[proxy.url] = proxy
        callback null, proxy
    else
      process.nextTick callback


  removeFile: () ->

  cleanup: (callback) ->
    process.nextTick callback if typeof callback is "function"

  getPayload: ->
    _.merge {}, @config,
      source     : @source
      destination: @destination
      date       : @date
      dateString : @dateString
      timeString : @timeString
      pages      : @pages
      html_pages : (page for url, page of @pages when page.isHTML)

  watch: -> console.error 'watch unimplemented'

  serve: (callback) ->
    @app = new app.App(@config.server_config)
    @app.setPageHandler (req, res, next) ->
      uri = url.parse(req.url).pathname

      res.removeHeader 'X-Powered-By'
      #res.removeHeader 'Last-Modified'

      if page = @pages[uri]
        type = (uri.replace(/.*[\.\/]/, '').toLowerCase() or 'html')
        res.set
          'Vary'       : 'Accept-Encoding'
          'Connection' : 'Keep-Alive'
      else
        return next 404
      try
        page.respondTo.apply page, arguments
      catch
        next 500
    @app.configure()
    @app.start (address) ->
      callback?(address)
