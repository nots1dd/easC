CC=gcc
CFLAGS=-Wall -g
LDFLAGS=-ldl

# Default target
all: lib/libtest.so build/test

lib/libtest.so: lib/libtest.c
	$(CC) -fPIC -shared lib/libtest.c -o lib/libtest.so

build/test: src/main.c lib/libtest.so
	$(CC) src/main.c $(LDFLAGS) -o build/test

clean:
	rm -rf build/* lib/*.so

.PHONY: clean
