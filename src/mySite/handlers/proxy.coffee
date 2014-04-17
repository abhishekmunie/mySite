configFile = require './config-file'
httpProxy = require 'http-proxy'

module.exports.Proxy = class Proxy extends configFile.ConfigFile

  constructor: ->
    super

  handler: ->
    proxy = new httpProxy.createProxyServer target: @data.target
    return (req, res, next) =>
      proxy.web req, res
