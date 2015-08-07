VERSION?=$(shell git rev-parse --short HEAD)
PROJECT_NAME=vistarhtml5-player
GULP=./node_modules/.bin/gulp


.PHONY: package
package: clean build $(PROJECT_NAME)-$(VERSION).zip

.PHONY: dist
dist: clean deps
	$(GULP) dist

.PHONY: build
build: deps
	$(GULP) build

.PHONY: clean
clean:
	@find . -maxdepth 1 -iname '$(PROJECT_NAME)-*.zip' -print0 | xargs -0 rm -f
	@rm -rf lib/*

.PHONY: deps
deps:
	@npm install

.PHONY: publish
publish: dist
	@npm publish

$(PROJECT_NAME)-$(VERSION).zip:
	@cd build && zip -9 -r ../$(PROJECT_NAME)-$(VERSION).zip * && cd ..


.PHONY: build deps
