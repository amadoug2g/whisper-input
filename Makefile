.PHONY: dev test lint app dmg install open clean

dev:
	swift run MemoMain

test:
	swift test

lint:
	swiftlint lint

app:
	swift build -c release
	bash scripts/package-app.sh

dmg: app
	bash scripts/package-dmg.sh $(VERSION)

install: app
	cp -r Memo.app /Applications/Memo.app
	@echo "Installed. Open Spotlight and search 'Memo'."

open: app
	open Memo.app

clean:
	rm -rf .build
