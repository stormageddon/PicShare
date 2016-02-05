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
      appid: process.env.APPID
      apikey: process.env.APIKEY
      apiroot: process.env.APIROOT
    })

  upload: (file, user)->
    deferred = q.defer()
    opts = {contentType: file.contentType}
    console.log 'current user:', user
    opts['session_token'] = user?.sessionToken if not user?.sessionToken
    console.log
    @__ws.upload(file.name, file.path, {contentType: file.contentType, apikey: process.env.CREATE_KEY}).on 'success', (data)->
      console.log 'uploaded!', data
      deferred.resolve(data)
    .on 'error', (err)->
      console.log 'error uploading:', err
      deferred.reject(err)
    deferred.promise



  addACL: (file, aclId)->
    console.log 'the file:', file
    deferred = q.defer()
    @__ws.update(file.key, {'__access__': [aclId]}).on 'success', (data)->
      deferred.resolve(data)
    .on 'error', (err)->
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

  getRecentFiles: ->
    deferred = q.defer()
    @__ws.searchFiles('[content_type = "image/png"]', {limit: FILE_LIMIT, sort: '__created__:desc'}).on 'success', (results)->
      # Convert to array
      fileArray = (val for key, val of results)
      deferred.resolve(fileArray)
    .on 'error', (err)->
      deferred.reject(err)

    deferred.promise

  login: (email, password)->
    deferred = q.defer()
    @__ws.login({email: email, password: password}).on 'success', (data)->
      deferred.resolve(data)
    .on 'error', (err)->
      deferred.reject(err)
    deferred.promise

  module.exports = Upload
