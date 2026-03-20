.PHONY: dev test app install open clean

# Quick iteration — runs in debug mode directly from terminal
dev:
	swift run WhisperInputMain

# Run the test suite
test:
	swift test

# Build a self-contained .app in release mode
app:
	swift build -c release
	bash scripts/package-app.sh

# Build + copy to /Applications (makes it launchable from Spotlight, Dock, etc.)
install: app
	cp -r WhisperInput.app /Applications/WhisperInput.app
	@echo "✓ Installed — open Spotlight and search 'WhisperInput'"

# Open the packaged .app without installing
open: app
	open WhisperInput.app

# Remove build artifacts
clean:
	rm -rf .build
