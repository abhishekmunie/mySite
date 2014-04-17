fs      = require 'fs'
path    = require 'path'
util    = require 'util'
zlib    = require 'zlib'
crypto  = require 'crypto'
yaml    = require 'js-yaml'
_       = require 'lodash'
hogan   = require 'hogan.js'

module.exports.Page = class Page extends require('./file').File

  constructor: (@sitePayload, @path, options={}) ->
    super(@sitePayload, @path, options)

  getPayload: ->
    _.merge {}, @options,
      data: @data

  extractYAML: ->
    yaml = @source.match /\A(---\s*\n.*?\n?)^(---\s*$\n?)/m
    if yaml
      deep_merge @options, yaml.safeLoad(yaml), @_options
      @source.replace /\A(---\s*\n.*?\n?)^(---\s*$\n?)/m, ''

  compile: ->
    @template = hogan.compile @source, @options.hoganCompileOptions

  init: (callback) ->
    @readJSON =>
      @read (err) =>
        return callback? err if err
        @extractYAML()
        @compile()
        @update (err) =>
          return callback? err if err
          @clean()
          callback? null, @

  render: ->
    @rawOutput = @template.render
      site: @sitePayload
      page: @getPayload()
    @output = @rawOutput unless @options.gzip

  gzip: (callback) ->
    zlib.gzip @rawOutput, (error, result) =>
      if error
        callback? err if err
      @output = result
      delete @rawOutput unless @options.gzip.keepRawOutput
      callback? null, @output

  update: (callback) ->
    @sha1sum = crypto.createHash 'sha1'
    @render()
    if @options.gzip
      @gzip (err, output) =>
        return callback? err if err
        @sha1sum.update @output
        @headers['ETag'] = @sha1sum.digest 'hex'
        callback?()
    else
      @sha1sum.update @output
      @headers['ETag'] = @sha1sum.digest 'hex'
      process.nextTick -> callback() if callback?

  clean: ->
    super()
    delete @extractYAML
    delete @compile

module.exports.createPage = (sitePayload, path, options, callback) ->
  if typeof options is "function"
    [callback, options] = [options, null]
  new Page(sitePayload, path, options).init callback
