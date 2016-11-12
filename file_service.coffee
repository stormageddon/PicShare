'use strict'

request = require 'request'
Q = require 'q'

class FileService
  constructor: (opts)->
    this

  @save: (username, fileUrl)->
    deferred = Q.defer()
    request.post 'http://localhost:5001/files',
    { json: {username: username, image_url: fileUrl} },
    (error, response, body)->
        console.log 'error:', error
        console.log 'body:', body
        return deferred.resolve(body) unless error
        deferred.reject(error)

    deferred.promise

  module.exports = FileService                                                                                                                                                
