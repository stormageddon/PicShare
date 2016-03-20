# PicShare
An open source screen shot sharing application. Currently only supported on Mac. Built on ElectronJS and CloudMine.

![Screen shot](/img/example_screenshot.png)

You can download the latest version of PicShare [here](https://s3-us-west-2.amazonaws.com/caputoio-app-downloads/PicShare.zip).

# Building
There is currently an issue with building the app into a .asar file and keeping the desktop notifications working. The easiest way to build and get notifications is to use `make build-dev`. 

# Running in development mode
1. `npm install`
2. `make run`
