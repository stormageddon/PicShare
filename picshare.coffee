path = require('path')
electron = require('electron')
app = electron.app
BrowserWindow = electron.BrowserWindow
Menu = require('menu')
Tray = electron.Tray
globalShortcut = electron.globalShortcut
clipboard = electron.clipboard

cloudmine = require('cloudmine')
shelljs = require('shelljs')
fs = require('fs')

tmpDir = '/tmp'

ws = new cloudmine.WebService({
  appid: '933cd5ae80cfc140244a4158c5558db3'
  apikey: 'c6ee6dcbf7e8435ab90edc90fc6c704e'
  apiroot: 'https://api.secure.cloudmine.me'
})

BASE_URL = "http://caputo.io/#/gallery" #"localhost:9001/#/gallery"

uploadScreenshot = ->
  fs.exists path.join(tmpDir, "electron_pic.png"), (exists)->
    if exists
      ws.upload(null, path.join(tmpDir, "electron_pic.png"), {contentType: 'image/png'}).on 'success', (data)->
        url = "#{BASE_URL}/#{data.key}"
        console.log 'url:', url
        clipboard.writeText(url, 'selection')
        fs.unlink(path.join(tmpDir, "electron_pic.png"))
        require('shell').openExternal(url)
      .on 'error', (err)->
        console.log 'Error uploading file:', err
    else
      console.log path.join(tmpDir, "electron_pic.png") + "doesnt exist"

takeScreenshot = ->
  shelljs.exec("screencapture -i /tmp/electron_pic.png", -> uploadScreenshot())

close = ->
  app.quit()

app.on 'ready', ->
  globalShortcut.register('Command+shift+5', takeScreenshot)
  app.dock.hide()
  iconPath = path.join(__dirname, 'img/cloud-icon.png')
  appIcon = new Tray(path.join(__dirname, 'img/cloud_icon.png'))

  labels = [
    {
      label: 'Quit'
      click: close
    }
  ]

  menu = Menu.buildFromTemplate(labels)
  appIcon.setContextMenu(menu)
