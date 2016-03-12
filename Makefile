build-mac:
	$(MAKE) compile
	./node_modules/electron-packager/cli.js . PicShare --platform=darwin --arch=x64 --version=0.36.0 --asar=true --asar-unpack-dir="node_modules/node-notifier/vendor/**" --overwrite --out dist/

compile:
	./node_modules/coffee-script/bin/coffee -c *.coffee

run:
	$(MAKE) build-mac
	./node_modules/electron-prebuilt/dist/Electron.app/Contents/MacOS/Electron .
