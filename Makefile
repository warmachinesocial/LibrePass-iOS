DESTDIR = Build/Products/Release-iphoneos
XCODEBUILD ?= xcodebuild

$(DESTDIR)/LibrePass.ipa: $(DESTDIR)/LibrePass.app
	cd $(DESTDIR) && \
		mkdir -p Payload && \
		cp -pr LibrePass.app Payload && \
		zip -r LibrePass.ipa Payload

$(DESTDIR)/LibrePass.app:
	    xcodebuild -workspace LibrePass.xcworkspace -scheme LibrePass -sdk iphoneos -configuration Release CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

clean:
	rm -rf Build
