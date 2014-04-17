fs     = require 'fs'
path   = require 'path'
async  = require 'async'
grunt  = require 'grunt'
events = require 'events'



module.exports.DataGraph = class DataGraph extends events.EventEmitter
  
  

module.exports.DataSource = class DataSource
  constructor: () ->


  initDataSource: () ->


  initGenerator: ()->
    
module.exports.JSONDataSource = class JSONDataSource extends DataSource
  constructor: (json) ->
    grunt.template.process json

  initDataSource: () ->


  initGenerator: ()->
    

getDataSource = (data, options) ->
  if data instanceof DataSource
    return data
  else if data.datasource instanceof DataSource
    return data.datasource
  else
    return new JSONDataSource(data)

# Require all of the modules in the given directory.
extract_ds_all_in = (dir, options, callback) ->
  list = fs.readdir dir, (err, files) ->
    return callback?err if list.length is 0
    ds = {}
    
    extract = (file, callback) ->
      return if file is 'Icon\r' or /(^|\/)\./.test file
      fn = path.resolve dir, file
      ext = path.extname file
      fs.stat fn, (err, stats) ->
        if stats.isDirectory()
          extract_ds_all_in fn, (err, datasources) ->
            return callback?err if err
            ds[file] = datasources
            #ds[file]._isPackage = true
            ds.setSite @
            callback()
        else if require.extensions[ext]
          ds[path.basename(file, ext)] = getDataSource (require fn), options
    
    async.each list, extract, (err) ->
      callback? err, ds

module.exports.readDataSources = (src, options, callback) ->
    dsg = extract_ds_all_in src, options, callback
    
