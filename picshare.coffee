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

BASE_URL = "localhost:9001/#/gallery" #http://caputo.io/#/gallery

console.log 'ws:', ws

uploadScreenshot = ->
  console.log 'uploading screenshot to CloudMine'
  ws.upload(null, path.join(__dirname, "electron_pic.png"), {contentType: 'png'}).on 'success', (data)->
    console.log 'Successfully uploaded:', data
    url = "#{BASE_URL}/#{data.key}"
    console.log 'url:', url
    clipboard.writeText(url, 'selection')
    fs.unlink(path.join(__dirname, "electron_pic.png"))
  .on 'error', (err)->
    console.log 'Error uploading file:', err
  .on 'complete', (data)->
    console.log 'delete file here'


takeScreenshot = ->
  shelljs.exec("screencapture -i electron_pic.png", -> uploadScreenshot())

app.on 'ready', ->
  globalShortcut.register('Command+shift+5', takeScreenshot)
  iconPath = path.join(__dirname, 'img/cloud-icon.png')
  console.log 'icon path', iconPath
  appIcon = new Tray(path.join(__dirname, 'img/cloud_icon.png'))
