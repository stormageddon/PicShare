cloudmine = require('cloudmine')
q = require('q')

FILE_LIMIT = 10

class Upload
  constructor: (opts)->
    {
      @appId
      @apiRoot
      @apiKey
    } = opts

    @__ws = null
    @webservice = @getWebService()

    this

  getWebService: ->
    return @__ws if @__ws
    @__ws = new cloudmine.WebService({
      appid: @appId #process.env.APPID
      apikey: @apiKey #process.env.APIKEY
      apiroot: @apiRoot #process.env.APIROOT
    })

  upload: (file, user)->
    deferred = q.defer()
    opts = {contentType: file.contentType}
    opts['session_token'] = user.sessionToken
    @__ws.upload(file.name, file.path, {contentType: file.contentType, apikey: process.env.CREATE_KEY, session_token: user.sessionToken}).on 'success', (data)->
      console.log 'uploaded:', data
      deferred.resolve(data)
    .on 'error', (err)->
      console.log 'error uploading:', err
      deferred.reject(err)
    deferred.promise


  createACL: (sessionToken)->
    deferred = q.defer()
    deferred.reject("Invalid session token") if not sessionToken

    @__ws.updateACL({members: [], permissions: ['r'], segments: { public: true, logged_in: false }}).on 'success', (response)->
      console.log 'created ACL', response
      ids = (key for key, val of response)
      deferred.resolve(ids)
    .on 'error', (err)->
      deferred.reject(err)

    deferred.promise

  getAllACLs: (sessionToken)->
    deferred = q.defer()
    @__ws.api('/access', {session_token: sessionToken, app_level: no}).on 'success', (data)->
      console.log 'data', data
      ids = (key for key, val of data)
      console.log 'fetched acl ids:', ids
      deferred.reject('User has more than 1 acl') if ids.length > 1
      deferred.resolve(ids)
    .on 'error', (err)->
      deferred.reject(err)

    deferred.promise

  addACL: (file, user)->
    deferred = q.defer()
    console.log 'add acl user', user
    @__ws.update(file.key, {'__access__': [user.sharedACL]}, {session_token: user.sessionToken}).on 'success', (data)->
      deferred.resolve(data)
    .on 'error', (err)->
      console.log 'Failed to add ACL', err
      deferred.reject(err)
    deferred.promise

  setupACL: (file)->
    deferred = q.defer()
    aclExists()
      .then (createACL)
      .then (acl)=>
        @__ws.update(file.filename, { '__access__': [acl['__id__']] }).on 'success', (data)->
          deferred.resolve(data)
        .on 'error', (err)->
          deferred.reject(err)
      .catch (err)->
        deferred.reject(err)
    deferred.promise

  getRecentFiles: (sessionToken = null)->
    deferred = q.defer()
    wsOptions = {limit: FILE_LIMIT, sort: '__created__:desc'}
    wsOptions['session_token'] = sessionToken if sessionToken
    console.log 'wsOptions:', wsOptions
    @__ws.searchFiles('[content_type = "image/png"]', wsOptions).on 'success', (results)->
      # Convert to array
      console.log 'file results', results
      fileArray = (val for key, val of results)
      deferred.resolve(fileArray)
    .on 'error', (err)->
      deferred.reject(err)

    deferred.promise

  login: (email, password)->
    deferred = q.defer()
    @__ws.login({email: email, password: password}).on 'success', (data)->
      console.log 'logged in?', data
      console.log 'info:', email, password
      deferred.resolve({email: email, password: password, sessionToken: data.session_token})
    .on 'error', (err)->
      deferred.reject(err)
    deferred.promise

  logout: (token)->
    deferred = q.defer()
    @__ws.logout(token).on 'success', (data)->
      console.log 'logged out', data
      deferred.resolve(data)
    .on 'error', (err)->
      console.log 'issue logging out', err
      deferred.reject(err)
    deferred.promise

  module.exports = Upload
