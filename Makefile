# qMD - Build and release script
# Compiles the Swift package and assembles macOS .app bundles

APP_NAME = qmd
DISPLAY_NAME = qMD
BUILD_DIR = .build/release
APP_BUNDLE = $(DISPLAY_NAME).app
PKG_ID = com.b4ryon.qmd.pkg
DIST_DIR = dist

VERSION ?= $(shell /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Info.plist)

.PHONY: build run clean release release-build release-pkg release-publish

build:
	swift build -c release
	rm -rf $(APP_BUNDLE)
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	mkdir -p $(APP_BUNDLE)/Contents/Resources
	cp $(BUILD_DIR)/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/
	cp Info.plist $(APP_BUNDLE)/Contents/
	@if ls $(BUILD_DIR)/*.bundle 1>/dev/null 2>&1; then \
		cp -r $(BUILD_DIR)/*.bundle $(APP_BUNDLE)/Contents/Resources/; \
	fi
	cp Sources/qmd/Resources/AppIcon.icns $(APP_BUNDLE)/Contents/Resources/

run: build
	open $(APP_BUNDLE)

clean:
	swift package clean
	rm -rf $(APP_BUNDLE) $(DIST_DIR)

release-build:
	@echo "Building qMD $(VERSION) for arm64 and x86_64..."
	rm -rf $(DIST_DIR)
	mkdir -p $(DIST_DIR)
	@for arch in arm64 x86_64; do \
		echo ""; \
		echo "Building $$arch..."; \
		swift build -c release --arch $$arch; \
		BDIR=.build/$$arch-apple-macosx/release; \
		APPDIR=$(DIST_DIR)/$$arch/$(APP_BUNDLE); \
		rm -rf $$APPDIR; \
		mkdir -p $$APPDIR/Contents/MacOS; \
		mkdir -p $$APPDIR/Contents/Resources; \
		cp $$BDIR/$(APP_NAME) $$APPDIR/Contents/MacOS/; \
		strip -x $$APPDIR/Contents/MacOS/$(APP_NAME); \
		cp Info.plist $$APPDIR/Contents/; \
		if ls $$BDIR/*.bundle 1>/dev/null 2>&1; then \
			cp -r $$BDIR/*.bundle $$APPDIR/Contents/Resources/; \
		fi; \
		cp Sources/qmd/Resources/AppIcon.icns $$APPDIR/Contents/Resources/; \
		xattr -rc $$APPDIR 2>/dev/null || true; \
		echo "Done: $$APPDIR"; \
	done
	@echo ""
	@echo "Build complete."

release-pkg: release-build
	@echo ""
	@echo "Packaging qMD $(VERSION)..."
	@for arch in arm64 x86_64; do \
		echo ""; \
		echo "Creating $(DISPLAY_NAME)-$(VERSION)-macos-$$arch.pkg..."; \
		pkgbuild \
			--root $(DIST_DIR)/$$arch \
			--identifier $(PKG_ID) \
			--version $(VERSION) \
			--install-location /Applications \
			$(DIST_DIR)/$(DISPLAY_NAME)-$(VERSION)-macos-$$arch.pkg; \
		echo "Creating $(DISPLAY_NAME)-$(VERSION)-macos-$$arch.zip..."; \
		cd $(DIST_DIR)/$$arch && COPYFILE_DISABLE=1 zip -r ../$(DISPLAY_NAME)-$(VERSION)-macos-$$arch.zip $(APP_BUNDLE) && cd ../..; \
	done
	@echo ""
	@echo "Verifying packages..."
	@CLEAN=true; for arch in arm64 x86_64; do \
		COUNT=$$(pkgutil --payload-files $(DIST_DIR)/$(DISPLAY_NAME)-$(VERSION)-macos-$$arch.pkg | grep '\._' | wc -l | tr -d ' '); \
		if [ "$$COUNT" -gt 0 ]; then \
			echo "Warning: $(DISPLAY_NAME)-$(VERSION)-macos-$$arch.pkg contains $$COUNT AppleDouble entries"; \
			echo "  This is caused by com.apple.provenance xattr (macOS sandbox)."; \
			echo "  Rebuild from a normal terminal to get clean packages."; \
			CLEAN=false; \
		else \
			echo "  $(DISPLAY_NAME)-$(VERSION)-macos-$$arch.pkg: clean"; \
		fi; \
		ZCOUNT=$$(zipinfo -1 $(DIST_DIR)/$(DISPLAY_NAME)-$(VERSION)-macos-$$arch.zip | grep '/\._' | wc -l | tr -d ' '); \
		if [ "$$ZCOUNT" -gt 0 ]; then \
			echo "Warning: $(DISPLAY_NAME)-$(VERSION)-macos-$$arch.zip contains $$ZCOUNT AppleDouble entries"; \
			CLEAN=false; \
		else \
			echo "  $(DISPLAY_NAME)-$(VERSION)-macos-$$arch.zip: clean"; \
		fi; \
	done; \
	if [ "$$CLEAN" = "false" ]; then \
		echo ""; \
		echo "Warning: Some packages contain AppleDouble metadata. Rebuild from a normal terminal."; \
	fi
	@echo ""
	@echo "Packages:"
	@ls -lh $(DIST_DIR)/*.pkg $(DIST_DIR)/*.zip

release-publish:
	@echo ""
	@echo "Publishing qMD $(VERSION) to GitHub..."
	git tag -a "v$(VERSION)" -m "Release v$(VERSION)"
	git push origin main
	git push origin "v$(VERSION)"
	gh release create "v$(VERSION)" \
		--title "qMD v$(VERSION)" \
		--generate-notes \
		$(DIST_DIR)/$(DISPLAY_NAME)-$(VERSION)-macos-arm64.pkg \
		$(DIST_DIR)/$(DISPLAY_NAME)-$(VERSION)-macos-x86_64.pkg \
		$(DIST_DIR)/$(DISPLAY_NAME)-$(VERSION)-macos-arm64.zip \
		$(DIST_DIR)/$(DISPLAY_NAME)-$(VERSION)-macos-x86_64.zip

release: release-pkg
	@echo ""
	@echo "Release artifacts ready in $(DIST_DIR)/."
	@echo "Run 'make release-publish VERSION=$(VERSION)' to push to GitHub."
