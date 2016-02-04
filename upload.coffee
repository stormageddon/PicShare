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
      appid: @appId
      apikey: @apiKey
      apiroot: @apiRoot
    })

  upload: (file)->
    deferred = q.defer()
    @__ws.upload(file.name, file.path, {contentType: file.contentType}).on 'success', (data)->
      deferred.resolve(data)
    .on 'error', (err)->
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

  module.exports = Upload
