build-mac:
	$(MAKE) compile
	./node_modules/electron-packager/cli.js . /PicShare --platform=darwin --arch=x64 --version=0.36.0 --overwrite --out dist/

compile:
	./node_modules/coffee-script/bin/coffee -c *.coffee

run:
	$(MAKE) build-mac
	APPID="933cd5ae80cfc140244a4158c5558db3" \
	APIKEY="c6ee6dcbf7e8435ab90edc90fc6c704e" \
	APIROOT="https://api.secure.cloudmine.me" \
	./node_modules/electron-prebuilt/dist/Electron.app/Contents/MacOS/Electron .
