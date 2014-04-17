fs    = require 'fs'
path  = require 'path'
grunt = require 'grunt'

module.exports.ConfigFile = class ConfigFile

  constructor: (@sitePayload, @path, @options) ->
    @payload =
      site: @sitePayload
      file: null
      options: @options

  init: (callback) ->
    @read (err, data) ->
      return callback? err if err
      @resolvePath()
      @clean()
      callback?()

  resolvePath: (newPath) ->
    @path = newPath if newPath?
    @path = path.relative @sitePayload.source, @path
    @dirname = path.dirname @path
    @ext = path.extname @path
    @basename = path.basename @path, @ext
    @fullpath = path.resolve @sitePayload.source, @path
    @_calcURL()

  _calcURL: ->
    url = if @options.permalink
      @options.permalink
    else
      if @sitePayload.permalink_style is 'pretty'
        if @isIndex and @isHTML
          "/#{@dirname}/"
        else
          "/#{@path}"
      else
        "/#{@path}"
    @url = url.split('/').filter((part) -> not part.match /^\.+$/ ).join('/')
    @url += "/" if url.match /\/$/

  read: (callback) ->
    fs.readFile @fullpath, (err, data) ->
      return callback? err if err
      try
        @data = JSON.parse data
        @payload.file = @data
        @payload.file = @date = grunt.template.process @data, @payload
        callback? null, @data
      catch err
        callback? err

  clean: ->
