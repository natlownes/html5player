VERSION?=$(shell git rev-parse --short HEAD)
PROJECT_NAME=vistarhtml5-player
GULP=./node_modules/.bin/gulp

package: clean build copy_manifest $(PROJECT_NAME)-$(VERSION).zip

dist: clean deps
	$(GULP) dist

build: deps
	$(GULP) build

clean:
	@find . -maxdepth 1 -iname '$(PROJECT_NAME)-*.zip' -print0 | xargs -0 rm -f
	@rm -rf lib/*

copy_manifest:
	@cp manifest.json build/manifest.json

deps:
	@npm install

publish: dist
	@npm publish

$(PROJECT_NAME)-$(VERSION).zip:
	@cd build && zip -9 -r ../$(PROJECT_NAME)-$(VERSION).zip * && cd ..


.PHONY: build deps
