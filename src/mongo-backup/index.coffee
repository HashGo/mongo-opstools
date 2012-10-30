# db = require './mongo'

async       = require 'async'
dateFormat  = require 'dateformat'
exec        = (require 'child_process').exec
knox        = require 'knox'
fs          = require 'fs'
sys         = require 'util'

conf  = require './conf'

class MongoBackup
  ###
  
  The `mongodump` command can randomly throw a `Error: Command failed: assertion: 10320 BSONElement: bad type 109`.
  Such error is related to the following [https://jira.mongodb.org/browse/SERVER-6877](SERVER-6877 ISSUE) on [https://jira.mongodb.org](JIRA).

  TODO: Identify _Replica Set_ elements and offer the selection of a _SECONDAY_ to get the snapshot from.
  ###
  DUMP_CMD = "mongodump"

  constructor: ( ) ->
    ### ###
    dbs = conf.get 'backup_dbs'
    ### ###
    @verbose = conf.get "v"
    ### ###
    @mongo_host = mongo_host = conf.get "host" #if conf.get "hosts" then (conf.get "hosts")?[0] else conf.get "host"
    @mongo_port = mongo_port = conf.get "port"
    ### ###
    @outBasePath = outBasePath = conf.get "out"
    ### ###
    backupPrefix  = dateFormat Date.now(), "yyyy-mm-dd_HHMMss_Z"
    backupSuffix  = conf.get "q"
    backupSuffix  = if backupSuffix then "#{backupSuffix}" else ""

    @dirName = "#{backupSuffix}#{backupPrefix}"
 
    @out = out = "#{outBasePath}/#{@dirName}"

    @gzFileName = "#{@dirName}.tar.gz"

    @gzFilePath = "#{outBasePath}/#{@gzFileName}"

    sys.print "Proceeding to dump [#{dbs.join ', '}] at #{dateFormat new Date}\n".grey.italic
    @funcs = dbs.map (db_name) => ( next ) =>
      ### ###
      args  = [
        "--host #{mongo_host}"
        "--port #{mongo_port}"
        # "--oplog" only supported on full dumps
        "--db #{db_name}"
        "--out #{out}"
        "--journal"
        "--forceTableScan"
      ]
      ### ###
      dbpath  = conf.get "dbpath"
      args.push "--dbpath #{dbpath}" if dbpath
      ### ###
      if (conf.get "oplog")
        args.push "--oplog"
      ### ###
      username = conf.get "username"
      if username
        args.push "--username #{username}" if username
        args.push "--password #{conf.get "password"}" if password


      ### ###
      exec_cmd = "#{DUMP_CMD} #{args.join " "}"
     
      sys.print "#{exec_cmd.yellow}\n" if @verbose
      exec exec_cmd, {}, ( error, stdout, stderr ) =>
        sys.print "Dumping #{db_name}...".grey

        if error
          sys.print "\t[Failed]\n".red.bold
          sys.error stderr if @verbose
          return next error
       
        sys.print "\t[OK]\n".green
        console.log stdout if @verbose
        next undefined, db_name


  run : ( ) ->

    async.series [
      ( next ) => @_dump        next
      ( next ) => @_compress    next
      ( next ) => @_uploadToS3  next
      ( next ) => @_cleanup     next
    ], (error, result) =>

      if error
        sys.print "One of the following steps failed:\n+ #{result.join '\n+ '}\n".red
        console.error error
        process.exit -1

      else
        sys.print "Finished at #{dateFormat new Date}\n".grey.italic

        if result and result.length > 0
          sys.print "Steps completed:\n+ #{result.join '\n+ '}\n".grey
        else
          sys.print "We did nothing.".red

        process.exit 1


  _dump : ( callback ) ->
    console.dir @funcs
    unless @funcs
      callback undefined, undefined

    async.series @funcs, ( error, results ) =>
      if error
        callback error, "Dump for #{@mongo_host}:#{@mongo_port} failed."
      else
        callback undefined, "dumped [#{results.join ', '}]"
   
  _compress : ( callback ) ->
    exec "tar cvfz #{@gzFilePath} #{@out}", {}, ( error, stdout, stderr ) =>
      if error
        callback error, "Unable to compress the directory #{@out} : #{stderr}"
      else
        console.log stdout if @verbose
        callback undefined, "compressed the dumps to #{@out}"

  _uploadToS3 : ( callback ) ->
    key    = conf.get "AWS_ACCESS_KEY"
    secret = conf.get "AWS_ACCESS_SECRET"
    bucket = conf.get "AWS_S3_BUCKET"

    key     = conf.get "aws_key"        unless key
    secret  = conf.get "aws_secret"     unless secret
    bucket  = conf.get "aws_s3_bucket"  unless bucket

    client = knox.createClient { key: key, secret: secret, bucket: bucket }

    s3_file = "/mongodumps/#{@gzFileName}"

    client.putFile @gzFilePath, s3_file, {}, ( error, res ) =>
      if error
        callback error, "Unable to upload #{@gzFilePath} to S3."
      else
        callback undefined, "File S3 #{@gzFileName} uploaded to #{bucket} at #{s3_file}."

  _cleanup : ( callback ) ->
    exec "rm -rf #{@gzFile} #{@out}", {}, ( error, stdout, stderr ) =>
      if error
        callback error, "Unable to cleanup after ourselves (#{@out} and #{@gzFile} might still there)."
      else
        callback undefined, "cleanup dir and gz file."

module.exports = new MongoBackup
