s3 = require('s3')
util = require('./util.js')

class S3Upload
  constructor: (opts)->
    @client = s3.createClient({
      s3Options:
        accessKeyId: process.env.ACCESS_KEY_ID
        secretAccessKey: process.env.SECRET_ACCESS_KEY
    })

    this

  upload: (file, user, key)->
    params = {
      localFile: file.path
      s3Params:
        Bucket: 'picshario'
        Key: util.uuid()
    }

    upload = @client.uploadFile(params)
    upload.on 'error', (err)->
      console.error 'unable to upload:', err.stack

    upload.on 'progress', ->
      console.log 'progress', upload.progressMd5Amount, upload.progressAmount, upload.progressTotal

  module.exports = S3Upload
