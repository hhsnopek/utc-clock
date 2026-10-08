PREFIX ?= /Applications
APP := UTC Clock.app

.PHONY: build install clean

build:
	rm -rf "build/$(APP)"
	mkdir -p "build/$(APP)/Contents/MacOS"
	cp Info.plist "build/$(APP)/Contents/"
	swiftc -O -o "build/$(APP)/Contents/MacOS/UTCClock" main.swift

install: build
	pkill -x UTCClock || true
	rm -rf "$(PREFIX)/$(APP)"
	ditto "build/$(APP)" "$(PREFIX)/$(APP)"
	open -g "$(PREFIX)/$(APP)"

clean:
	rm -rf build
