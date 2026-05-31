RES ?= 256
CFLAGS ?= $(shell pkg-config --cflags raylib 2>/dev/null)
LIBS ?= $(shell pkg-config --libs raylib 2>/dev/null)

ifeq ($(strip $(LIBS)),)
LIBS = -lraylib
endif

UNAME := $(shell uname)
ifeq ($(UNAME),Darwin)
LIBS += -framework OpenGL -framework Cocoa -framework IOKit -framework CoreVideo
endif

starter: main.c shader.fs
	cc $(CFLAGS) -o starter main.c $(LIBS)

run: starter
	./starter

render: starter
	./starter render $(RES) frame.ppm

test: render
	python3 ../tools/assert_frame.py frame.ppm

clean:
	rm -f starter frame.ppm

.PHONY: run render test clean
