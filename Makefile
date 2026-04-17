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
	ditto --noextattr --norsrc $(BUILD_DIR)/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
	ditto --noextattr --norsrc Info.plist $(APP_BUNDLE)/Contents/Info.plist
	@if ls $(BUILD_DIR)/*.bundle 1>/dev/null 2>&1; then \
		for b in $(BUILD_DIR)/*.bundle; do \
			ditto --noextattr --norsrc $$b $(APP_BUNDLE)/Contents/Resources/$$(basename $$b); \
		done; \
	fi
	ditto --noextattr --norsrc Sources/qmd/Resources/AppIcon.icns $(APP_BUNDLE)/Contents/Resources/AppIcon.icns
	xattr -rc $(APP_BUNDLE) 2>/dev/null || true

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
		ditto --noextattr --norsrc $$BDIR/$(APP_NAME) $$APPDIR/Contents/MacOS/$(APP_NAME); \
		strip -x $$APPDIR/Contents/MacOS/$(APP_NAME); \
		ditto --noextattr --norsrc Info.plist $$APPDIR/Contents/Info.plist; \
		if ls $$BDIR/*.bundle 1>/dev/null 2>&1; then \
			for b in $$BDIR/*.bundle; do \
				ditto --noextattr --norsrc $$b $$APPDIR/Contents/Resources/$$(basename $$b); \
			done; \
		fi; \
		ditto --noextattr --norsrc Sources/qmd/Resources/AppIcon.icns $$APPDIR/Contents/Resources/AppIcon.icns; \
		xattr -rc $$APPDIR 2>/dev/null || true; \
		find $$APPDIR -name '._*' -delete 2>/dev/null || true; \
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
		COPYFILE_DISABLE=1 pkgbuild \
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
		PKG=$(DIST_DIR)/$(DISPLAY_NAME)-$(VERSION)-macos-$$arch.pkg; \
		COUNT=$$(pkgutil --payload-files $$PKG | grep '\._' | wc -l | tr -d ' '); \
		EXPECTED=$$(find $(DIST_DIR)/$$arch/$(APP_BUNDLE) | wc -l | tr -d ' '); \
		if [ "$$COUNT" -eq 0 ]; then \
			echo "  $$PKG: clean"; \
		elif [ "$$COUNT" -le "$$EXPECTED" ]; then \
			echo "  $$PKG: $$COUNT AppleDouble entries (expected: com.apple.provenance xattr, kernel-protected on macOS Sonoma+)"; \
		else \
			echo "Warning: $$PKG contains $$COUNT AppleDouble entries (more than $$EXPECTED files in bundle — unexpected metadata)"; \
			CLEAN=false; \
		fi; \
		ZIP=$(DIST_DIR)/$(DISPLAY_NAME)-$(VERSION)-macos-$$arch.zip; \
		ZCOUNT=$$(zipinfo -1 $$ZIP | grep '/\._' | wc -l | tr -d ' '); \
		if [ "$$ZCOUNT" -gt 0 ]; then \
			echo "Warning: $$ZIP contains $$ZCOUNT AppleDouble entries"; \
			CLEAN=false; \
		else \
			echo "  $$ZIP: clean"; \
		fi; \
	done; \
	if [ "$$CLEAN" = "false" ]; then \
		echo ""; \
		echo "Warning: Some packages contain unexpected AppleDouble metadata."; \
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
