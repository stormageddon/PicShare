pkg = require('./package.json')
path = require('path')
electron = require('electron')
app = electron.app
BrowserWindow = electron.BrowserWindow
menubar = require('menubar')({ dir: __dirname, index: 'file://' + path.join(__dirname, 'login.html'), icon: path.join(__dirname, 'img/cloud_icon.png'), resizable: yes, preloadWindow: yes })
Tray = electron.Tray
Menu = electron.Menu
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
config = require('./config.json')

CURRENT_USER = null

APP_ID = if config.app_id then config.app_id else process.env.APPID
API_KEY = if config.api_key then config.api_key else process.env.APIKEY
API_ROOT = if config.api_root then config.api_root else process.env.APIROOT

# Set up autolaunch
AutoLaunch = require('auto-launch')

picshareAutoLauncher = new AutoLaunch({
    name: 'Minecraft',
})

picshareAutoLauncher.enable();
#minecraftAutoLauncher.disable();


uploader = new Upload({
  appId: APP_ID
  apiKey: API_KEY
  apiRoot: API_ROOT
})

init = ->
  console.log 'initing'


setLoginError = ->
  console.log 'sending error', window
  window.webContents.send('errorMessage', 'Invalid username or password') if window?.webContents

login = (email, password)->
  console.log 'logging in with ' + email + ' and ' + password
  uploader.login(email, password)
    .then (data)->
      console.log 'logged in as', data
      CURRENT_USER = new User(email: data.email, password: data.password, sessionToken: data.sessionToken)

      deferred = q.defer()
      # Fetch ACLs
      uploader.getAllACLs(data.sessionToken).then (acls)=>
        if acls.length < 1
          console.log 'creating an ACL'
          uploader.createACL(CURRENT_USER.sessionToken).then (ids)=>
            CURRENT_USER.sharedACL = ids[0]
            fetchLastImages()
            deferred.resolve(CURRENT_USER)
        else
          CURRENT_USER.sharedACL = acls[0]
          console.log 'CURRENT_USER:', CURRENT_USER
          fetchLastImages()
          deferred.resolve(CURRENT_USER)

        menubar.window.loadURL(path.join('file://', __dirname, 'index.html'))

      deferred.promise

    .catch (err)->
      console.log 'Error logging in and fetching ACLs:', err
      setLoginError()

createFileUrl = (file)->
  file.url = "#{API_ROOT}/v1/app/#{APP_ID}/user/binary/#{file.filename}?apikey=#{API_KEY}&shared=true"

  getShortUrl(file.url).then (shortenedUrl)->
    clipboard.writeText(shortenedUrl)
    file.shortUrl = shortenedUrl



uploadScreenshot = ->
  fs.exists path.join(tmpDir, "electron_pic.png"), (exists)->
    if exists

      file = new File({
        path: path.join(tmpDir, "electron_pic.png")
      })

      uploader.upload(file, CURRENT_USER, API_KEY) # return promise
      .then (file)->
        uploader.addACL(file, CURRENT_USER).then (result)->
          file.url = "#{API_ROOT}/v1/app/#{APP_ID}/user/binary/#{file.key}?apikey=#{API_KEY}&shared=true"

          getShortUrl(file.url).then (shortenedUrl)->
            clipboard.writeText(shortenedUrl)
            file.shortUrl = shortenedUrl

            notify('Your link is available for sharing!', 'Use \u2318+v to send it!')

            fetchLastImages()

          .catch (err)->
            notify("Something's gone wrong", 'There was an error processing your request')
            console.log 'err', err

          fs.unlink(path.join(tmpDir, "electron_pic.png"))
        .catch (err)->
          error = (val for key, val of err)
          console.log 'failed to get an acl:', error[0]
          console.log 'err:', err

    else
      console.log path.join(tmpDir, "electron_pic.png") + "doesnt exist"

notify = (title, message)->
  console.log 'notifying 1'
  #Notification.requestPermission();
  #console.log 'notifying 2'
  #Notification(title, { body: message, icon: 'img/icon.png' });
  #console.log 'notifying 3'
  #ipc.send('notify', {title: title, body: message, icon: 'img/cloud_icon.png'})
  notifier.notify({
    title: title
    message: message
    sender: 'com.github.electron'
  })

takeScreenshot = ->
  shelljs.exec "screencapture -i /tmp/electron_pic.png", ->
    uploadScreenshot()
    fetchLastImages()

lastImages = {}

fetchLastImages = ->
  uploader.getRecentFiles(CURRENT_USER.sessionToken).then (files)->
    lastImages = files
    sendContent(menubar.window)
  .catch (err)->
    console.log 'error fetching previous images', err

close = ->
  app.close()

menubar.on 'show', ->
  sendContent(menubar.window)

sendContent = (window)->
  console.log("Sending content");
  window.webContents.send('pictures', {images: lastImages, root: API_ROOT, apikey: API_KEY, appid: APP_ID, version: pkg.version}) if window?.webContents

  window.webContents.send('authedUser', CURRENT_USER) if window?.webContents and CURRENT_USER?.sessionToken

showSettingsPanel = ->
  console.log 'showing settings menu'
  menubar.window.webContents.send 'contextMenu'

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
.on 'login', (event, credentials)->
  console.log 'credentials:', credentials
  login(credentials.email, credentials.password)
.on 'openSettings', (event)->
  #menubar.window.openDevTools()
  showSettingsPanel()
.on 'storedUser', (event, user)->
  menubar.window.loadURL(path.join('file://', __dirname, 'index.html'))
  CURRENT_USER = new User(JSON.parse(user))
  CURRENT_USER.sharedACL = JSON.parse(user).sharedACL
  console.log 'found user:', CURRENT_USER
  fetchLastImages()
.on 'openDevTools', (event)->
  menubar.window.openDevTools()
.on 'register', (event, credentials)->
  uploader.register(credentials).then (response)->
    console.log 'register response:', response
  .catch (err)->
    console.log 'error registering', err
.on 'logout', (event)->
  console.log 'CURRENT USER TO LOG OUT:', CURRENT_USER
  uploader.logout(CURRENT_USER.sessionToken).then ->
    menubar.window.loadURL(path.join('file://', __dirname, 'login.html'))
.on 'quit', (event)->
  menubar.app.quit()
.on 'copyFile', (event, file)->
  console.log 'Copy file link:', file
  createFileUrl(JSON.parse(file))
  notify('Your link is available for sharing!', 'Use \u2318+v to send it!')
.on 'downloadFile', (event, file)->
  uploader.download(file, CURRENT_USER).then ->
    console.log 'Download success!'
.on 'deleteFile', (event, file)->
  uploader.deleteFile(JSON.parse(file), CURRENT_USER).then (data)->
    console.log 'Deleted file', data
    fetchLastImages()


menubar.on 'ready', ->
  globalShortcut.register('Command+shift+5', takeScreenshot)

  this
