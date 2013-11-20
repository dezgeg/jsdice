.PHONY: all watch clean
all:
	coffee -o build -c jsdice.coffee
watch:
	coffee -w -o build -c jsdice.coffee
clean:
	-rm -rf build/*
