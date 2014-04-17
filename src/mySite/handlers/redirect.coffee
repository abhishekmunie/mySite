configFile = require './config-file'
httpProxy = require 'http-proxy'

module.exports.Proxy = class Proxy extends configFile.ConfigFile

  constructor: ->
    super

  handler: ->
    return (req, res, next) =>
      res.redirect @status, @url
