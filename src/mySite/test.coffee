Site = require('./mySite').Site

config =
  source: 'test/site'
  livereload: 35729
  server_config:
    port: 1337
console.log "Building #{config.source}..."
console.time 'Site Built in'
mySite = new Site config, (err) ->
  return console.error err if err?
  console.timeEnd 'Site Built in'
  console.log "Starting Server..."
  console.time 'Server Started in'
  mySite.serve (address) ->
    console.timeEnd 'Server Started in'
    console.log "Started at http://#{address.address}:#{address.port}"
