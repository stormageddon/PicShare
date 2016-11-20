'use strict'

request = require 'request'
Q = require 'q'

class FileService
  constructor: (opts)->
    this

  @save: (username, fileUrl, fileName)->
    deferred = Q.defer()
    request.post 'http://localhost:5001/files',
    { json: {username: username, image_url: fileUrl, image_name: fileName, timestamp: new Date().toISOString() } },
    (error, response, body)->
        console.log 'error:', error
        console.log 'body:', body
        return deferred.resolve(body) unless error
        deferred.reject(error)

    deferred.promise

  @deleteFile: (sessionToken, fileId, fileUrl)->
    deferred = Q.defer()
    console.log "file id: #{fileId}"
    console.log "file url: #{fileUrl}"
    request.delete "http://localhost:5001/files/#{fileId}",
    { json: {sessionToken: sessionToken, fileUrl: fileUrl} },
    (error, response, body)->
      return deferred.reject(error) if error
      return deferred.resolve(body)

    deferred.promise

  module.exports = FileService
