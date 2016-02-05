cloudmine = require('cloudmine')
ws = new cloudmine.WebService({
      appid: process.env.APPID
      apikey: process.env.APIKEY
      apiroot: process.env.APIROOT
    })
CURRENT_USER = null

class User

  constructor: (opts)->
    {
      @username
      @password
      @email
      @sessionToken
    } = opts

    this

  @isAnonymous: ->
    return yes unless @email

  @login: (email, password)->
    ws.login({email: email, password: password}).on 'success', (data)=>
      console.log 'logged in?', data
      @email = email
      @password = password
      @sessionToken = data.session_token

      CURRENT_USER = this
      console.log 'curr user:', CURRENT_USER

  @currentUser: ->
    CURRENT_USER

  module.exports = User
