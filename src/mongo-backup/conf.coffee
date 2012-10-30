# TODO : Use a cli tool to enable verbose output. (e.g. commander)

require 'colors'

fs      = require "fs"
nconf   = require "nconf"

nconf.file 'package.json'

nconf.overrides
  version : nconf.get "version"

# console.log "Loading argv and env configuration...".blue
argv = nconf.argv({
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
    describe: """Forces to skip the index and scan the data directly. Typically there are two cases where this behavior is preferable to the default:

If you have key sizes over 800 bytes that would not be present in the _id index.
Your database uses a custom _id field.
When you run with --forceTableScan, mongodump does not use $snapshot. As a result, the dump produced by mongodump can
reflect the state of the database at many different points in time."""

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


})
### ###
nconf.env()
### ###
verbose = nconf.get "v"
### ###
name = nconf.get "name"
### ###
file = (nconf.get "f") ? "/etc/#{name}/conf.json"
console.log "Loading file #{file} if available...".blue if verbose
nconf.file file
### ###
env = nconf.get 'NODE_ENV'
env = "test" unless env

nconf.defaults
  env : env

  test :
    backup_dbs : [ "test" ]

class ConfManager

  get: ( key, value ) ->
    _value = @_getFromEnv key
    _value = nconf.get key unless _value
    _value ? value

  _getFromEnv : ( key ) ->
    envConf = nconf.get "#{env}:#{key}"


module.exports = new ConfManager
