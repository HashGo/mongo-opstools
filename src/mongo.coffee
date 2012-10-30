require "colors"
mongoskin = require "mongoskin"

# Get configuration
conf = require "./conf"
# Add nconf so we read the DB Identifier and DB Name from config variables.
env = conf.get "env"
# Mongo Hosts
mongo = conf.get "mongo"

unless mongo
  throw new Error "MongoDB conf is not available,\
 please define a mongo object containing at least a host entry or hosts array."

unless mongo.host || mongo.hosts
  throw new Error "Unable to determine the host(s)\
 values of the mongo configuration!"

# Mongo Options
opts  = mongo.opts
opts = {} unless opts

app_name = conf.get "name"

throw new Error "Application name is not defined." unless app_name
db_name_suffix = ""
db_name_suffix = "-#{env}" unless env == "prod" || env == "production"

opts.database = "#{app_name}#{db_name_suffix}"
console.log "MongoDB Database set to #{opts.database}.".blue

if mongo?.hosts?.length > 0
  console.log "MongoDB hosts set to #{mongo.hosts}.".blue
  db = mongoskin.db mongo.hosts, opts
else if mongo.host
  console.log "MongoDB host set to #{mongo.host}.".blue
  db = mongoskin.db mongo.host, opts
else
  throw new Error "MongodDB Connection is not initialized, host(s) went AWOL."


module.exports = db


