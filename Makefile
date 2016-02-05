build-mac:
	$(MAKE) compile
	./node_modules/electron-packager/cli.js . /PicShare --platform=darwin --arch=x64 --version=0.36.0 --overwrite --out dist/

compile:
	./node_modules/coffee-script/bin/coffee -c *.coffee

run:
	$(MAKE) build-mac
	APPID="933cd5ae80cfc140244a4158c5558db3" \
	APIKEY="30693a81d8a84f839439449357a427b2" \
	APIROOT="https://api.secure.cloudmine.me" \
	CREATE_KEY="62750a6629e24dbabac4ac70e9dd2a75" \
	./node_modules/electron-prebuilt/dist/Electron.app/Contents/MacOS/Electron .
