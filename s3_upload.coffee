s3 = require 's3'
request = require 'request'
util = require './util.js'
Q = require 'q'


class S3Upload
  constructor: (opts)->
    @client = s3.createClient({
      s3Options:
        accessKeyId: process.env.ACCESS_KEY_ID
        secretAccessKey: process.env.SECRET_ACCESS_KEY
    })

    this

  upload: (file, user, key)->
    deferred = Q.defer()
    params = {
      localFile: file.path
      s3Params:
        Bucket: 'picshario'
        Key: util.uuid()
        ACL: 'public-read'
    }

    upload = @client.uploadFile(params)
    upload.on 'error', (err)->
      console.error 'unable to upload:', err.stack
      deferred.reject(err);

    upload.on 'progress', ->
      console.log 'progress', upload.progressMd5Amount, upload.progressAmount, upload.progressTotal

    upload.on 'end', (data)->
      console.log('end data:', data);
      deferred.resolve(params.s3Params.Key)

    deferred.promise

  getRecentFiles: (user)->
    @_getFileURLs(user)

  _getFileURLs: (user)->
    deferred = Q.defer()
    console.log 'getting images for user', user
    queryString = { username: user.username, sessionToken: user.sessionToken }
    request.get({url: "http://localhost:5001/files", qs: queryString }, (error, response, body)->
        deferred.reject(error) if error
        console.log 'body:', body
        deferred.resolve(JSON.parse(body))
    )
    return deferred.promise



  module.exports = S3Upload
