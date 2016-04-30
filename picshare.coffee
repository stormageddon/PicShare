pkg = require('./package.json')
path = require('path')
electron = require('electron')
app = electron.app
BrowserWindow = electron.BrowserWindow
menubar = require('menubar')({ dir: __dirname, index: 'file://' + path.join(__dirname, 'login.html'), icon: path.join(__dirname, 'img/picshare_logo.png'), resizable: yes, preloadWindow: yes })
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

# Constants
KEYBOARD_COMMAND = "Command+shift+5"

CURRENT_USER = null

APP_ID = if config.app_id then config.app_id else process.env.APPID
API_KEY = if config.api_key then config.api_key else process.env.APIKEY
API_ROOT = if config.api_root then config.api_root else process.env.APIROOT

# Set up autolaunch
AutoLaunch = require('auto-launch')
picshareAutoLauncher = new AutoLaunch({
    name: 'PicShare'
})

setAutoLaunch = (enable)->
  config.autolaunch = enable
  configPath = path.join(__dirname, 'config.json')
  fs.writeFile(configPath, JSON.stringify(config), (err)->
    return console.log 'error writing config file' if err
    return picshareAutoLauncher.enable() if enable
    picshareAutoLauncher.disable();
  )


uploader = new Upload({
  appId: APP_ID
  apiKey: API_KEY
  apiRoot: API_ROOT
})

setLoginError = ->
  console.log 'sending error', window
  this

login = (email, password)->
  uploader.login(email, password).then (data)->
    CURRENT_USER = new User(username: data.username, password: data.password, sessionToken: data.sessionToken)

    deferred = q.defer()
    # Fetch ACLs
    uploader.getAllACLs(data.sessionToken).then (acls)=>
      if acls.length < 1
        uploader.createACL(CURRENT_USER.sessionToken).then (ids)=>
          CURRENT_USER.sharedACL = ids[0]
          fetchLastImages()
          deferred.resolve(CURRENT_USER)
      else
        CURRENT_USER.sharedACL = acls[0]
        fetchLastImages()
        deferred.resolve(CURRENT_USER)

      menubar.window.loadURL(path.join('file://', __dirname, 'index.html'))
    globalShortcut.register(KEYBOARD_COMMAND, takeScreenshot)
    deferred.promise

  .fail (err)->
    menubar.window.webContents.send('errorMessage', 'Invalid username or password')


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

lastImages = {}

fetchLastImages = ->
  uploader.getRecentFiles(CURRENT_USER.sessionToken).then (files)->
    lastImages = files
    sendContent(menubar.window)
  .catch (err)->
    console.log 'error fetching previous images', err
    notify('Something went wrong', 'There was an error fetching your previous images')

close = ->
  app.close()

menubar.on 'show', ->
  sendContent(menubar.window)

sendContent = (window)->
  window.webContents.send('pictures', {images: lastImages, root: API_ROOT, apikey: API_KEY, appid: APP_ID, version: pkg.version, autolaunch: config.autolaunch}) if window?.webContents

  data =
    user: CURRENT_USER
    autolaunch: config.autolaunch
  window.webContents.send('authedUser', data) if window?.webContents and CURRENT_USER?.sessionToken

showSettingsPanel = ->
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
  login(credentials.email, credentials.password)

.on 'openSettings', (event)->
  showSettingsPanel()
.on 'storedUser', (event, user)->
  menubar.window.loadURL(path.join('file://', __dirname, 'index.html'))
  CURRENT_USER = new User(JSON.parse(user).user)
  CURRENT_USER.sharedACL = JSON.parse(user).user.sharedACL
  globalShortcut.register(KEYBOARD_COMMAND, takeScreenshot)
  fetchLastImages()
.on 'openDevTools', (event)->
  menubar.window.openDevTools()
.on 'register', (event, credentials)->
  uploader.register(credentials).then (response)=>
    login(credentials.username, credentials.password)
  .catch (err)->
    console.log 'error registering', err
    this
.on 'logout', (event)->
  uploader.logout(CURRENT_USER.sessionToken).then ->
    globalShortcut.unregisterAll()
    menubar.window.loadURL(path.join('file://', __dirname, 'login.html'))
.on 'quit', (event)->
  globalShortcut.unregisterAll()
  menubar.app.quit()
.on 'copyFile', (event, file)->
  createFileUrl(JSON.parse(file))
  notify('Your link is available for sharing!', 'Use \u2318+v to send it!')
.on 'downloadFile', (event, file)->
  uploader.download(file, CURRENT_USER).then ->
.on 'deleteFile', (event, file)->
  uploader.deleteFile(JSON.parse(file), CURRENT_USER).then (data)->
    fetchLastImages()
.on 'toggleCheck', (event, checked)->
  setAutoLaunch(checked)

menubar.on 'ready', ->
  this
