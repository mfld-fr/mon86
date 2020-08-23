# Makefile for MON86 project

.PHONY: all clean test

all: host.all target.all

clean: host.clean target.clean

test: host.test target.test

%.all:
	$(MAKE) -C $* all

%.clean:
	$(MAKE) -C $* clean

%.test:
	$(MAKE) -C $* test
