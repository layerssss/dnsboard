COFFEE=$(shell find . -name '*.coffee')

all: $(COFFEE:.coffee=.js) 

run: all
	node .

%.js: %.coffee
	coffee -c $<
