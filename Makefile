PROJECT = mongo-prd-backup 
PROJECT_DIR = $(shell pwd)
VERSION=$(shell perl -wnl -e '/"version"\s*:\s*"([^"]+)"/ and print $$1' package.json)
TARNAME=$(PROJECT)-$(VERSION)
TARBALL=$(TARNAME).tar.gz
BUILDTYPE ?= Release

TESTTIMEOUT = 5000
REPORTER 	= spec
TEST_UNIT_SPEC = $(shell find test -name \*-uspec.coffee -or -name \*-unit.coffee)

COFFEE_BIN=node_modules/coffee-script/bin/coffee 

install:
	@npm install
	$(MAKE) build

version:
	@echo $(VERSION)

watch:
	@$(COFFEE_BIN) -wc --bare -o lib src

build:
	@mkdir -p .hashgo/logs
	@mkdir -p .hashgo/tmp
	@mkdir -p lib && coffee -c -o lib src
	@find src -name "*.coffee" -print0 | xargs -0 ./node_modules/coffeelint/bin/coffeelint -f coffeelint.json

test-unit: build
	@NODE_ENV=test ./node_modules/mocha/bin/mocha \
		-c -b --compilers coffee:coffee-script --reporter $(REPORTER) --timeout $(TESTTIMEOUT) $(TEST_UNIT_SPEC)

lint-tests:
	@find test -name "*.coffee" -print0 | xargs -0 ./node_modules/coffeelint/bin/coffeelint -f coffeelint.json


test: lint-tests test-unit

lib-cov:
	rm -rf ./$@
	jscoverage --encoding=utf-8 ./lib ./$@

test-cov: build lib-cov
	@PROJECT_COV=1 $(MAKE) test REPORTER=markdown > Test_Coverage.md

clean:
	@rm -rf lib 
	@find src -name \*.js  | xargs rm
	@find test -name \*.js | xargs rm

dist: clean test version
	@if [ "$(shell git status --porcelain | egrep -v '^\?\? ')" = "" ]; then \
		exit 0 ; \
	else \
	  echo "" >&2 ; \
		echo "The git repository is not clean." >&2 ; \
		echo "Please commit changes before building release tarball." >&2 ; \
		echo "" >&2 ; \
		git status --porcelain | egrep -v '^\?\?' >&2 ; \
		echo "" >&2 ; \
		exit 1 ; \
	fi

	@test -d ./$(TARNAME) || rm -rf ./$(TARNAME)
	@mkdir ./$(TARNAME)
	@cp -r History.md Readme.md lib package.json bin index.js ./$(TARNAME)
	@tar cvfz ./$(TARBALL) ./$(TARNAME)
	@mkdir -p dist
	@mv $(TARBALL) ./dist
	@rm -rf $(TARNAME)

	@git add ./dist/$(TARBALL)
	@git commit -m "Release $(VERSION)"
	@git tag -a "$(VERSION)" -m "$(VERSION): $(TARBALL)" # TODO use a crypto-signature
	@git push
	@git push --tags

upstall_fab:
	sudo easy_install --upgrade fabric
	sudo easy_install --upgrade dogapi

all: install

.PHONY: all 
