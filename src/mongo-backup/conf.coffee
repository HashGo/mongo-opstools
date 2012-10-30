# TODO : Use a cli tool to enable verbose output. (e.g. commander)
require 'colors'

fs       = require "fs"
nconf    = require "nconf"
optimist = require "optimist"

### ###
nconf.file 'package.json'

### ###
nconf.overrides
  version : nconf.get "version"

### ###
nconf.env()

optimist_argv = optimist.options({
  h:
    alias: 'help'
    describe: 'Show help/usage.'
    default : false

  v:
    alias: 'verbose'
    describe: 'Verbose output.'
    default: false

  host:
    alias : 'host'
    describe: 'Mongo Host'
    default: 'localhost'

  port:
    alias : 'port'
    describe: 'Mongo Port'
    default: 27017

  o:
    alias : 'out'
    describe: 'Path where the mongodump should be saved to'
    default: './dump'

  q:
    alias: 'qualifier'
    describe: 'A string representing a qualifier for the backup, this will be used as suffix of the dump directory.'

  oplog:
    alias: 'oplog'
    describe: 'Enabled oplog for point-in-time snapshots.'
    default: false

  fs:
    alias: 'forceTableScan'
    describe: """Forces to skip the index and scan the data directly. Pleae check the mongo docs at http://docs.mongodb.org/manual/reference/mongodump/ """

  aws_key :
    alias: 'aws_key'
    describe: 'AWS Key'
    require : false

  aws_secret :
    alias: 'aws_secret'
    describe: 'AWS Secret'
    default: false

  aws_s3_bucket:
    alias: 'aws_s3_bucket'
    describe: 'AWS S3 Bucket where the file will be stored'
    default: false


}).usage("""
Invokes the mongodump process and uploads a tar gzipped version to a given S3 bucket.
""").argv

nconf.use 'optimistArgvStore', {type:'literal', store:optimist_argv}

### ###
verbose = nconf.get "v"
### ###
name = nconf.get "name"

### ###
if nconf.get "f"
  file = nconf.get "f"
  console.log "Loadign file #{file}" if verbose
  nconf.file file

else
  files = [
    "/etc/#{name}/conf.json"
    "/etc/#{name}/mongo-backup.json"
  ]
  console.log "Loadign files #{files.join ", "}" if verbose
  files.forEach (f) => nconf.file f

### ###
env = nconf.get 'NODE_ENV'
env = "test" unless env

nconf.defaults
  env : env

  test :
    backup_dbs : [ "test" ]


class ConfManager

  showHelp : () ->
    optimist.showHelp console.err

  get: ( key, value ) ->
    _value = @_getFromEnv key
    _value = nconf.get key unless _value
    _value ? value

  _getFromEnv : ( key ) ->
    envConf = nconf.get "#{env}:#{key}"


module.exports = new ConfManager
