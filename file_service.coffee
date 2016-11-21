'use strict'

request = require 'request'
Q = require 'q'
config = require('./config.json');

PICSHARIO_URL = config.picshario_url or process.env.picshario_url

class FileService
  constructor: (opts)->
    this

  @save: (username, fileUrl, fileName)->
    deferred = Q.defer()
    request.post "#{PICSHARIO_URL}/files",
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
    request.delete "#{PICSHARIO_URL}/files/#{fileId}",
    { json: {sessionToken: sessionToken, fileUrl: fileUrl} },
    (error, response, body)->
      return deferred.reject(error) if error
      return deferred.resolve(body)

    deferred.promise

  module.exports = FileService
