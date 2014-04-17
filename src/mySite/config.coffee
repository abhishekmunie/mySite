convict = require 'convict'
validator   = require 'validator'
fs      = require 'fs'
path    = require 'path'

# define a schema

existingFolder = (val) ->
  throw new Error("Source should be a directory") unless fs.statSync(path.resolve val).isDirectory()

configConvict = convict
  env:
    doc: "The applicaton environment."
    format: ["production", "development", "test"]
    default: "development"
    env: "NODE_ENV"
    arg: 'env'
  source:
    doc: ""
    format: existingFolder
    default: '.'
    arg: 'source'
  default_update_interval:
    doc: ""
    format: "duration"
    default:  60*60*100
  data_source:
    disable:
      doc: ""
      format: Boolean
      default: false
  page:
    keepSource:
      doc: ""
      format: Boolean
      default: false
    gzip:
      keepRawOutput:
        doc: ""
        format: Boolean
        default: true
    defaultStatus:
      doc: ""
      format: [200]
      default: 200
  template:
    default_engine:
      doc: ""
      format: ['hogan', 'handlebars', 'ejs']
      default: 'hogan'
  redirect:
    default_status_code:
      doc: ""
      format: [302]
      default: 302
  proxy:
    allowedDomains:
      doc: ""
      format: "*"
      default: ''
  site:
    name:
      doc: ""
      format: "*"
      default: ''
  server_config:
    env:
      doc: "The applicaton environment."
      format: ["production", "development", "test"]
      default: '<%= env %>'
    trust_proxy:
      doc: ""
      format: Boolean
      default: false
      env: "TRUST_PROXY"
    redirect_www:
      doc: ""
      format: Boolean
      default: true
      env: "REDIRECT_WWW"
    force_https:
      enable:
        doc: ""
        format: Boolean
        default: false
        env: "FORCE_HTTPS_HOST"
      host:
        doc: ""
        format: "*"
        default: null
      maxAge:
        doc: ""
        format: "*"
        default: null
      includeSubdomains:
        doc: ""
        format: Boolean
        default: false
    cookie_secret:
      doc: ""
      format: "*"
      default: null
      env: "COOKIE_SECRET"
    session:
      type:
        doc: ""
        format: ['express', 'pg', false]
        default: false
        env: "SESSION_TYPE"
      config:
        secret:
          doc: ""
          format: (val) -> throw new Error() unless configConvict.get('server_config.session.type') and typeof val is 'string' and val isnt ''
          default: undefined
          env: "SESSION_SECRET"
        key:
          doc: ""
          format: "*"
          default: undefined
        cookie:
          secure:
            doc: ""
            format: Boolean
            default: false
          # path: '/'
          # httpOnly: true
          # maxAge: null
        proxy:
          doc: ""
          format: Boolean
          default: false
    uncapitalize:
      doc: ""
      format: Boolean
      default: false
    index:
      doc: ""
      format: "*"
      default: 'index.html'
    cache_busting:
      doc: ""
      format: Boolean
      default: false
    ip:
      doc: "The IP address to bind."
      format: (val) -> throw new Error('must be an IP address') unless !validator || validator.isIP(val)
      default: undefined
      env: "IP_ADDRESS"
      arg: "host"
    port:
      doc: "The port to bind."
      format: "port"
      default: 0
      env: "PORT"
      arg: "port"
    livereload:
      doc: "The port to bind livereload event."
      format: "port"
      default: 35729
      arg: "livereload"
    static_file:
      source:
        doc: ""
        format: "*"#existingFolder
        default: '<%= source %>'
      cache_size:
        doc: ""
        format: "nat"
        default: 300 * 1024 *1024

# load environment dependent configuration

env = configConvict.get 'env'
configConvict.loadFile path.resolve __dirname, "../config/#{env}.json"

module.exports = configConvict