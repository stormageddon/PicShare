class File
  constructor: (opts)->
    {
      @path
      @url
      @shortenedUrl
      @name
    } = opts

    @contentType = 'image/png'
    @created = opts['__created__']
    @_isNew = yes unless @name and @created
    @defaults() if @_isNew

  defaults: ->
    @name = @generateName()

  generateName: ->
    currDate = new Date()
    day = currDate.getDate()
    month = currDate.getMonth() + 1
    year = currDate.getFullYear()
    hour = currDate.getHours()
    minutes = currDate.getMinutes()
    seconds = currDate.getSeconds()
    "screenshot-#{year}-#{month}-#{day}_at_#{hour}_#{minutes}_#{seconds}"

  module.exports = File
