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
cloudmine = require('cloudmine')
shelljs = require('shelljs')
fs = require('fs')
bitcly = require('bitcly')

tmpDir = '/tmp'

NUM_LAST_IMAGES = 10

ws = new cloudmine.WebService({
  appid: process.env.APPID
  apikey: process.env.APIKEY
  apiroot: process.env.APIROOT
})

BASE_URL = "http://caputo.io/#/gallery" #"localhost:9001/#/gallery"

uploadScreenshot = ->
  fs.exists path.join(tmpDir, "electron_pic.png"), (exists)->
    if exists
      currDate = new Date()
      day = currDate.getDate()
      month = currDate.getMonth() + 1
      year = currDate.getFullYear()
      hour = currDate.getHours()
      minutes = currDate.getMinutes()
      seconds = currDate.getSeconds()
      fileName = "screenshot-#{year}-#{month}-#{day}_at_#{hour}_#{minutes}_#{seconds}"
      ws.upload(fileName, path.join(tmpDir, "electron_pic.png"), {contentType: 'image/png'}).on 'success', (data)->
        url = "#{BASE_URL}/#{data.key}"
        shortUrl = "#{process.env.APIROOT}/v1/app/#{process.env.APPID}/binary/#{data.key}?apikey=#{process.env.APIKEY}"

        getShortUrl(shortUrl).then (shortenedUrl)->
          clipboard.writeText(shortenedUrl)

          notifier.notify({
            title: 'Your link is available for sharing!'
            message: 'Use \u2318+v to send it!'
            sender: 'com.github.electron'
          })
        .catch (err)->
          notifier.notify({
            title: "Something's gone wrong"
            message: 'There was an error processing your request'
            sender: 'com.github.electron'
          })
          console.log 'err', err


        fs.unlink(path.join(tmpDir, "electron_pic.png"))
      .on 'error', (err)->
        console.log 'Error uploading file:', err
    else
      console.log path.join(tmpDir, "electron_pic.png") + "doesnt exist"

takeScreenshot = ->
  shelljs.exec "screencapture -i /tmp/electron_pic.png", ->
    uploadScreenshot()
    fetchLastImages()
    sendContent(menubar.window)

lastImages = {}

fetchLastImages = ->
  ws.searchFiles('[content_type = "image/png"]', {limit: NUM_LAST_IMAGES, sort: '__created__:desc'}).on('success', (results)->
    lastImages = (val for key, val of results) #convert to array
  ).on 'error', (err)->
    console.log 'error fetching previous images', err

close = ->
  app.quit()

fetchLastImages()

ipcRenderer = require('electron').ipcRenderer;

menubar.on 'show', ->
  fetchLastImages()
  sendContent(menubar.window)

sendContent = (window)->
  window.webContents.send('pictures', {images: lastImages, root: process.env.APIROOT, apikey: process.env.APIKEY, appid: process.env.APPID}) if window?.webContents


menubar.on('after-create-window', ->
  menubar.window.openDevTools()
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

require('ipc').on 'exit', (event, shouldExit)->
  menubar.app.quit() if shouldExit
.on 'copy', (event, url)->
  getShortUrl(url).then (shortenedUrl)->
    clipboard.writeText(shortenedUrl)


menubar.on 'ready', ->
  globalShortcut.register('Command+shift+5', takeScreenshot)
  console.log 'app is ready'

  this
