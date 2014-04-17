fs = require 'fs'

module.exports.equire_all_in = (path) ->
  required = {}
  list = fs.readdirSync dir
  return undefined if list.length is 0
  for file in list
    continue if file is 'Icon\r' or /(^|\/)\./.test(file)
    fn = path.resolve(dir, file)
    ext = path.extname(file)
    stat = fs.statSync fn
    if stat.isDirectory()
      required[file] = require_all_in fn
      required[file].isDirectory = true
    else if require.extensions[ext]
      required[path.basename(file, ext)] = require fn
  required

module.exports.walkDirectory = walkDirectory = (dir, error, onFile, end) ->
  fs.readdir dir, (err, list) ->
    if err
      error(err)
      return end()
    l = list.length
    return end() if l == 0
    for file in list
      if file == 'Icon\r' or /(^|\/)\./.test(file) or /\.(bak|config|sql|fla|psd|ini|log|sh|inc|swp|dist|tmp|node_modules|bin)|~/.test(file)
        end() if --l == 0
        continue
      ((fn) ->
        fs.lstat fn, (err, stat) ->
          if err
            error(err)
            end() if --l == 0
          else if stat and stat.isDirectory()
            walkDirectory fn, error, onFile, ->
              end() if --l == 0
          else
            onFile fn
            end() if --l == 0
      )(dir + '/' + file)

module.exports.merge = (target, objs...) ->
  for obj in objs
    for key, val of obj
      target[key] = obj[key]
  target

module.exports.mkpath = (dirpath, callback) ->
  dirpath = path.resolve dirpath
  fs.stat dirpath, (err, stats) ->
    if err
      if err.code is 'ENOENT'
        mkpath path.dirname(dirpath), (err) ->
          if err
            callback? err
          else if callback? and createdDir[dirpath] is true
            process.nextTick callback
          else
            unless createdDir[dirpath]
              createdDir[dirpath] = []
              console.log "Creating Directory: #{dirpath}"
              fs.mkdir dirpath, ->
                cb arguments for cb in createdDir[dirpath]
            createdDir[dirpath].push callback if callback?
      else
        callback? err
    else if stats.isDirectory()
      callback?()
    else
      callback? new Error(dirpath + ' exists and is not a directory')