'use strict'

User = require './user.js'
request = require 'request'
Q = require 'q'
config = require './config.json'

PICSHARIO_URL = config.picshario_url or process.env.picshario_url

CURRENT_USER = null
class UserService
  constructor: (opts)->
    this

  @login: (username, password)->
    deferred = Q.defer()
    request.post "#{PICSHARIO_URL}/login",
    { json: {username: username, password: password } },
    (error, response, body)->
      console.log 'error:', error
      console.log 'response:', response
      console.log 'body:', body
      return deferred.resolve(body) unless error
      deferred.reject(error)

    deferred.promise

  @register: (credentials)->
    deferred = Q.defer()
    request.post "#{PICSHARIO_URL}/register",
    {json: credentials},
    (error, response, body)->
      return deferred.resolve(body) unless error
      deferred.reject(error)

    deferred.promise

  @logout: (user)->
    deferred = Q.defer()
    request.post "#{PICSHARIO_URL}/logout",
    { json: {sessionToken: user.sessionToken, username: user.username} },
    (error, response, body)->
      return deferred.resolve(body) unless error
      deferred.reject(error)

    deferred.promise

  getCurrentUser: ->
    return CURRENT_USER

  module.exports = UserService
