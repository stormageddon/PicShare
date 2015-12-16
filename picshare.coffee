path = require('path')
electron = require('electron')
app = electron.app
BrowserWindow = electron.BrowserWindow
menu = require('menu')
Tray = electron.Tray
globalShortcut = electron.globalShortcut
clipboard = electron.clipboard

cloudmine = require('cloudmine')
shelljs = require('shelljs')
fs = require('fs')

ws = new cloudmine.WebService({
  appid: '933cd5ae80cfc140244a4158c5558db3'
  apikey: 'c6ee6dcbf7e8435ab90edc90fc6c704e'
  apiroot: 'https://api.secure.cloudmine.me'
})

BASE_URL = "http://caputo.io/#/gallery" #"localhost:9001/#/gallery"

uploadScreenshot = ->
  fs.exists path.join(__dirname, "electron_pic.png"), (exists)->
    if exists
      ws.upload(null, path.join(__dirname, "electron_pic.png"), {contentType: 'image/png'}).on 'success', (data)->
        console.log 'Successfully uploaded:', data
        url = "#{BASE_URL}/#{data.key}"
        console.log 'url:', url
        clipboard.writeText(url, 'selection')
        fs.unlink(path.join(__dirname, "electron_pic.png"))
        require('shell').openExternal(url)
      .on 'error', (err)->
        console.log 'Error uploading file:', err

takeScreenshot = ->
  shelljs.exec("screencapture -i electron_pic.png", -> uploadScreenshot())

app.on 'ready', ->
  globalShortcut.register('Command+shift+5', takeScreenshot)
  app.dock.hide()
  iconPath = path.join(__dirname, 'img/cloud-icon.png')
  console.log 'icon path', iconPath
  appIcon = new Tray(path.join(__dirname, 'img/cloud_icon.png'))
