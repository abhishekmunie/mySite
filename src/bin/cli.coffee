`#!/usr/bin/env node
`
fs        = require 'fs'
path      = require 'path'
commander = require 'commander'

lib  = path.join(path.dirname(fs.realpathSync(__filename)), '../lib')
Site = require(lib + '/mySite').Site

# Recursively merges objects into target, excluding properties starting with '_'
deep_merge_ex_ = (target, objects...) ->
  for obj in objects
    for key, val of obj when key[0] isnt '_'
      if target[key] and typeof val is "object" and typeof target[key] is "object"
        deep_merge_ex_ target[key], obj[key]
      else
        target[key] = obj[key]
  target

commander
  .version '0.0.1'
  .description 'static site generator'

  .option '-s, --source [DIR]', 'Source directory (defaults to ./)'         , './'
  .option '--safe'            , 'Safe mode (defaults to false)'
  .option '--plugins [DIR]'   , 'Plugins directory (defaults to ./_plugins)', './_plugins'
  .option '--layouts [DIR]'   , 'Layouts directory (defaults to ./_layouts)', './_layouts'

  .on '--help', ->
    console.log '  Examples:'
    console.log ''
    console.log '    $ mySite --help'
    console.log '    $ mySite build'
    console.log '    $ mySite serve --port $PORT'
    console.log ''

commander
  .command 'serve'
  .description 'Serve your site with continous in-memory build'

  .option '-w, --watch'            , 'Watch for changes and rebuild'
  .option '-p, --port [PORT]'      , 'Port to listen on'            , parseInt, 4000
  .option '-h, --host [HOST]'      , 'Host to bind to'                        , '0.0.0.0'
  .option '-b, --baseurl [URL]'    , 'Base URL'                               , '/'
  .option '-l, --livereload [PORT]', 'Livereload on changes'        , parseInt, 35729

  .on '--help', ->
    console.log '  Examples:'
    console.log ''
    console.log '    $ mySite serve --port $PORT'
    console.log '    $ mySite serve --watch --port $PORT'
    console.log ''

  .action (options) ->
    # config = deep_merge_ex_ {}, commander, options
    console.log "Building #{commander.source}..."
    console.time 'Site Built in'
    mySite = new Site {source: commander.source}, (err) ->
      return console.error err if err?
      console.timeEnd 'Site Built in'
      console.log "Starting Server..."
      console.time 'Server Started in'
      mySite.serve (address) ->
        console.timeEnd 'Server Started in'
        console.log "Started at http://#{address.address}:#{address.port}"

commander.parse process.argv
