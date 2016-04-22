# PicShare
An open source screen shot sharing application. Currently only supported on Mac. Built on ElectronJS and CloudMine.

![Screen shot](/img/example_screenshot.png)

You can download the latest version of PicShare [here](https://s3-us-west-2.amazonaws.com/caputoio-app-downloads/PicShare.zip).

# Configuration
PicShare reads in configuration data from `config.json`. This makes it easy for you to create your own app on [CloudMine](https://compass.cloudmine.io) to host all of your PicShare images. If you wish to run your own instance (which is required for development work), you can see `example_config.json` for an example of what you'll need to add to a new `config.json` file.

Alternatively, PicShare supports configuration via environment variable. You can set `APPID`, `APIKEY`, and `APIROOT` in your environment and PicShare will read them in.

# Building
There is currently an issue with building the app into a .asar file and keeping the desktop notifications working. The easiest way to build and get notifications is to use `make build-dev`. 

# Running in development mode
1. `npm install`
2. `make run`
