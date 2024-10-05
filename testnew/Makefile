CC=gcc
CFLAGS=-Wall -g
LDFLAGS=-ldl

# Default target
all: lib/libtestnew.so build/testnew

lib/libtestnew.so: lib/libtestnew.c
	$(CC) -fPIC -shared lib/libtestnew.c -o lib/libtestnew.so

build/testnew: src/main.c lib/libtestnew.so
	$(CC) src/main.c $(LDFLAGS) -o build/testnew

clean:
	rm -rf build/* lib/*.so

.PHONY: clean
