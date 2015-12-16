build-mac:
	$(MAKE) compile
	./node_modules/electron-packager/cli.js . /PicShare --platform=darwin --arch=x64 --version=0.36.0 --overwrite --out dist/

compile:
	./node_modules/coffee-script/bin/coffee -c picshare.coffee

run:
	$(MAKE) compile
	./node_modules/electron-prebuilt/dist/Electron.app/Contents/MacOS/Electron .
