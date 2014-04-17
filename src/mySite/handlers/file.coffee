fs   = require 'fs'
path = require 'path'

ONE_HOUR = 60 * 60
ONE_WEEK = ONE_HOUR * 24 * 7
ONE_MONTH = ONE_WEEK * 4
ONE_YEAR = ONE_MONTH * 12


createdDir = {}

class File

  constructor: (@sitePayload, @path, @options) ->
    @headers =
      'Vary'       : 'Accept-Encoding'
      'Connection' : 'Keep-Alive'
    @resolvePath()

  resolvePath: (newPath) ->
    @path = newPath if newPath?
    @path = path.relative @sitePayload.source, @path
    @dirname = path.dirname @path
    @ext = path.extname @path
    @basename = path.basename @path, @ext
    @fullpath = path.resolve @sitePayload.source, @path
    @isHTML = @ext is 'html' or @ext is 'htm'
    @isIndex = @basename is 'index'
    @calcHeaders()
    @calcURL()

  calcHeaders: ->
    @status = @options.defaultStatus
    @type = @ext
    @headers['Content-Encoding'] = 'gzip' if @options.gzip
    @headers['Cache-Control'] = ((type) ->
      if /(text\/(cache-manifest|html|htm|xml)|application\/(xml|json))/.test type
        cc = 'public,max-age=0'
        # Feed
      else if /application\/(rss\+xml|atom\+xml)/.test type
        cc = 'public,max-age=' + ONE_HOUR
        # Favicon (cannot be renamed)
      else if /image\/x-icon/.test type
        cc = 'public,max-age=' + ONE_WEEK
        # Media: images, video, audio
        # HTC files  (css3pie)
        # Webfonts
        # (we should probably put these regexs in a variable)
      else if /(image|video|audio|text\/x-component|application\/font-woff|application\/x-font-ttf|application\/vnd\.ms-fontobject|font\/opentype)/.test type
        cc = 'public,max-age=' + ONE_MONTH
        # CSS and JavaScript
      else if /(text\/(css|x-component)|application\/javascript)/.test type
        cc = 'public,max-age=' + ONE_YEAR
        # Misc
      else
        cc = 'public,max-age=' + ONE_MONTH
      )(@type) + ',no-transform'
    # if @type is 'js'
    #   if fileCache[murl = uri+".map"]
    #     res.setHeader 'X-SourceMap', murl
    #   else  if fileCache[murl = uri.match(/.*[\.\/]/)+"map"]
    #     res.setHeader 'X-SourceMap', murl


  calcURL: ->
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

  readJSON: (callback) ->
    configPath = path.resolve @sitePayload.source, @dirname, "_#{@basename}#{@ext}.json"
    fs.exists configPath, (exists) =>
      if exists
        deep_merge @options, require(configPath), @_options
      callback?()

  read: (callback) ->
    fs.readFile @fullpath, (err, data) =>
      return callback? err if err
      @source = data.toString()
      callback?()

  sendHeadersTo: (res) ->
    console.log "status: #{@status}"
    res.status @status
    console.log "type: #{@type}"
    res.type @type
    console.log "headers:"
    console.log @headers
    res.set 'Content-Length', @output.length
    res.set 'Transfer-Encoding', 'chunked' if @output instanceof Stream
    res.set @headers

  sendTo: (res) ->
    @sendHeadersTo res
    if @output instanceof Stream
      @output.pipe res
    else
      res.end @output

  clean: ->
    delete @source
    delete @resolvePath
    delete @calcHeaders
    delete @calcURL
    delete @readJSON
    delete @read

module.exports.File            = File
