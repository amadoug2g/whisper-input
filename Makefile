.PHONY: dev test app install open clean

dev:
	swift run MemoMain

test:
	swift test

app:
	swift build -c release
	bash scripts/package-app.sh

install: app
	cp -r Memo.app /Applications/Memo.app
	@echo "Installed. Open Spotlight and search 'Memo'."

open: app
	open Memo.app

clean:
	rm -rf .build
