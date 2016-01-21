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
      ws.upload(null, path.join(tmpDir, "electron_pic.png"), {contentType: 'image/png'}).on 'success', (data)->
        console.log 'data:', data
        url = "#{BASE_URL}/#{data.key}"
        shortUrl = "#{process.env.APIROOT}/v1/app/#{process.env.APPID}/binary/#{data.key}?apikey=#{process.env.APIKEY}"
        bitcly(shortUrl).then (url)->
          console.log 'short url', url
          clipboard.writeText(url)
        .catch (err)->
          console.log 'error:', err

        console.log 'url:', url
        #clipboard.writeText(url, 'selection')
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
