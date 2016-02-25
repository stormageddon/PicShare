cloudmine = require('cloudmine')
q = require('q')

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

  @login: (email, password, window)->
    console.log 'logging in:'
    deferred = q.defer()
#    console.log 'here?', window.localStorage


#    savedEmail = window.localStorage.getItem('user.email')
#    savedSession = window.localStorage.getItem('user.session')
#    possibleUser = null if not savedEmail is email or not savedSession
#    possibleUser = {email: savedEmail, sessionToken: savedSesssion}


    possibleUser = null

    console.log 'possible user:', possibleUser
    if not possibleUser
      console.log 'no user found locally'
      ws.login({email: email, password: password}).on 'success', (data)=>
        console.log 'logged in?', data
        @email = email
        @sessionToken = data.session_token

        CURRENT_USER = this
        console.log 'curr user:', CURRENT_USER
        deferred.resolve(this)

        #window.localStorage.setItem('user.name', @username)
        #window.localStorage.setItem('user.email', @email)
        #window.localStorage.setItem('user.session', @sessionToken)

      .on 'error', (err)->
        deferred.reject(err)
    else
      @email = possibleUser.email
      @sessionToken = possibleUser.sessionToken
      CURRENT_USER = this
      deferred.resolve(this)

    deferred.promise

  @loadLocal: (email, storage)->
    console.log 'loading local', email, storage
    savedEmail = storage.getItem('user.email')
    savedSession = storage.getItem('user.session')
    return null if not savedEmail is email or not savedSession
    {email: savedEmail, sessionToken: savedSesssion}

  @saveLocal: (storage)->
    storage.setItem('user.name', @username)
    storage.setItem('user.email', @email)
    storage.setItem('user.session', @sessionToken)
    console.log 'saved to local storage!', storage.getItem('user.email')

  @currentUser: ->
    CURRENT_USER

  @isLoggedIn: ->
    console.log 'User.isLoggedIn not yet implemented'
    no

  module.exports = User
