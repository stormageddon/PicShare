path = require('path')
electron = require('electron')
app = electron.app
BrowserWindow = electron.BrowserWindow
menubar = require('menubar')({ dir: __dirname, icon: path.join(__dirname, 'dist/PicShare-darwin-x64/PicShare.app/Contents/Resources/app/img/cloud_icon.png') })
Tray = electron.Tray
globalShortcut = electron.globalShortcut
clipboard = electron.clipboard
notifier = require('node-notifier')

cloudmine = require('cloudmine')
shelljs = require('shelljs')
fs = require('fs')
bitcly = require('bitcly')

tmpDir = '/tmp'

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
      console.log fileName
      ws.upload(fileName, path.join(tmpDir, "electron_pic.png"), {contentType: 'image/png'}).on 'success', (data)->
        console.log 'data:', data
        url = "#{BASE_URL}/#{data.key}"
        shortUrl = "#{process.env.APIROOT}/v1/app/#{process.env.APPID}/binary/#{data.key}?apikey=#{process.env.APIKEY}"

        bitcly(shortUrl).then (url)->
          console.log 'short url', url
          clipboard.writeText(url)
          notifier.notify({
            title: 'Your link is available for sharing!'
            message: 'Use \u2318+v to send it!'
            sender: 'com.github.electron'
          })
        .catch (err)->
          console.log 'error:', err

        fs.unlink(path.join(tmpDir, "electron_pic.png"))
      .on 'error', (err)->
        console.log 'Error uploading file:', err
    else
      console.log path.join(tmpDir, "electron_pic.png") + "doesnt exist"

takeScreenshot = ->
  shelljs.exec "screencapture -i /tmp/electron_pic.png", ->
    uploadScreenshot()
    console.log 'lastImages after screenshot:', lastImages
    fetchLastImages()
    #menubar.window.webContents.send('pictures', {images: lastImages, root: process.env.APIROOT, apikey: process.env.APIKEY, appid: process.env.APPID}) if menubar?.window?.webContents
    sendContent(menubar.window)


lastImages = {}

fetchLastImages = ->
  ws.searchFiles('[content_type = "image/png"]', {limit: 5, sort: '__created__:desc'}).on('success', (results)->
    console.log 'results:', results
    lastImages = (val for key, val of results) #convert to array
  ).on 'error', (err)->
    console.log 'error fetching previous images', err

close = ->
  app.quit()

fetchLastImages()

ipcRenderer = require('electron').ipcRenderer;

menubar.on 'show', ->
  fetchLastImages()
  console.log 'Showing menubar!'
  console.log '!', lastImages
  sendContent(menubar.window)

sendContent = (window)->
  window.webContents.send('pictures', {images: lastImages, root: process.env.APIROOT, apikey: process.env.APIKEY, appid: process.env.APPID}) if window?.webContents


menubar.on('after-create-window', ->
  #menubar.window.openDevTools()
  if menubar?.window?.webContents?
    menubar.window.webContents.on 'did-finish-load', ->
      console.log 'sending web contents:'
      #menubar.window.webContents.send('pictures', lastImages)
      sendContent(menubar.window)
    menubar.window.webContents.on 'new-window', (e, url)->
      e.preventDefault()
      require('shell').openExternal(url)
)

require('ipc').on 'exit', (event, shouldExit)->
  console.log 'should exit', shouldExit
  menubar.app.quit() if shouldExit

menubar.on 'ready', ->
  globalShortcut.register('Command+shift+5', takeScreenshot)
  console.log 'app is ready'

  this
