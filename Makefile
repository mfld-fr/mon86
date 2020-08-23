# Makefile for MON86 project

.PHONY: all clean

all: host.all target.all

clean: host.clean target.clean

%.all:
	$(MAKE) -C $* all

%.clean:
	$(MAKE) -C $* clean
