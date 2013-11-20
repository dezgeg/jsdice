.PHONY: all server watch dev clean

# Force make dev to start both watcher & server
MAKEFLAGS := -j2

all:
	coffee -o build -c jsdice.coffee

serve:
	python -m SimpleHTTPServer

watch:
	coffee -w -o build -c jsdice.coffee

dev: watch serve

clean:
	-rm -rf build/*
