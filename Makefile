compile:
	./node_modules/coffee-script/bin/coffee -c picshare.coffee

run:
	$(MAKE) compile
	./node_modules/electron-prebuilt/dist/Electron.app/Contents/MacOS/Electron .
