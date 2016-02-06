path = require('path')
electron = require('electron')
app = electron.app
BrowserWindow = electron.BrowserWindow
menubar = require('menubar')({ dir: __dirname, icon: path.join(__dirname, 'dist/PicShare-darwin-x64/PicShare.app/Contents/Resources/app/img/cloud_icon.png'), 'min-width': 200 })
Tray = electron.Tray
globalShortcut = electron.globalShortcut
clipboard = electron.clipboard
notifier = require('node-notifier')
q = require('q')
shelljs = require('shelljs')
fs = require('fs')
bitcly = require('bitcly')
File = require('./file.js')
tmpDir = '/tmp'
Upload = require('./upload.js')
User = require('./user.js')
CURRENT_USER = null


uploader = new Upload({
  appId: process.env.APPID
  apiKey: process.env.APIKEY
  apiRoot: process.env.APIROOT
})

uploader.login('test@test.com', 'testing')
  .then (data)->
    CURRENT_USER = new User(email: data.email, password: data.password, sessionToken: data.sessionToken)
    # Fetch ACLs
    uploader.getAllACLs(data.sessionToken).then (acls)=>
      if acls.length < 1
        uploader.createACL(CURRENT_USER.sessionToken).then (ids)->
          CURRENT_USER.sharedACL = ids[0]
      else
        CURRENT_USER.sharedACL = acls[0]
        console.log 'CURRENT_USER:', CURRENT_USER

  .catch (err)->
    console.log 'Error logging in and fetching ACLs:', err


BASE_URL = "http://caputo.io/#/gallery" #"localhost:9001/#/gallery"

uploadScreenshot = ->
  fs.exists path.join(tmpDir, "electron_pic.png"), (exists)->
    if exists

      file = new File({
        path: path.join(tmpDir, "electron_pic.png")
      })

      uploader.upload(file, CURRENT_USER) # return promise
      .then (file)->
        uploader.addACL(file, CURRENT_USER).then (result)->
          url = "#{BASE_URL}/#{file.key}"
          file.url = "#{process.env.APIROOT}/v1/app/#{process.env.APPID}/user/binary/#{file.key}?apikey=#{process.env.APIKEY}&shared=true"

          getShortUrl(file.url).then (shortenedUrl)->
            clipboard.writeText(shortenedUrl)
            file.shortUrl = shortenedUrl

            notify('Your link is available for sharing!', 'Use \u2318+v to send it!')

          .catch (err)->
            notify("Something's gone wrong", 'There was an error processing your request')
            console.log 'err', err

          fs.unlink(path.join(tmpDir, "electron_pic.png"))
        .catch (err)->
          console.log 'failed to get an acl:', err

    else
      console.log path.join(tmpDir, "electron_pic.png") + "doesnt exist"

notify = (title, message)->
  notifier.notify({
    title: title
    message: message
    sender: 'com.github.electron'
  })

takeScreenshot = ->
  shelljs.exec "screencapture -i /tmp/electron_pic.png", ->
    uploadScreenshot()
    fetchLastImages()
    sendContent(menubar.window)

lastImages = {}

fetchLastImages = ->
  uploader.getRecentFiles().then (files)->
    lastImages = files
  .catch (err)->
    console.log 'error fetching previous images', err

close = ->
  app.quit()

fetchLastImages()

menubar.on 'show', ->
  fetchLastImages()
  sendContent(menubar.window)

sendContent = (window)->
  window.webContents.send('pictures', {images: lastImages, root: process.env.APIROOT, apikey: process.env.APIKEY, appid: process.env.APPID}) if window?.webContents


menubar.on('after-create-window', ->
  #menubar.window.openDevTools()
  if menubar?.window?.webContents?
    menubar.window.webContents.on 'did-finish-load', ->
      sendContent(menubar.window)
    menubar.window.webContents.on 'new-window', (e, url)->
      e.preventDefault()
      require('shell').openExternal(url)
)

getShortUrl = (url)->
  deferred = q.defer()
  bitcly(url).then (shortenedUrl)->
    q.resolve(shortenedUrl)
  .catch (err)->
    console.log 'error:', err
    q.reject(err)

require('electron').ipcMain.on 'exit', (event, shouldExit)->
  menubar.app.quit() if shouldExit
.on 'copy', (event, url)->
  getShortUrl(url).then (shortenedUrl)->
    clipboard.writeText(shortenedUrl)


menubar.on 'ready', ->
  globalShortcut.register('Command+shift+5', takeScreenshot)

  this
