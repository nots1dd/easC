#!/bin/bash
# Recompile the dynamic library

gcc -fPIC -shared ../lib/libtest.c -o ../lib/libtest.so
if [ $? -eq 0 ]; then
    echo -e "\033[1;32mLibrary recompiled successfully.\033[0m"
else
    echo -e "\033[1;31mError recompiling the library.\033[0m"
    exit 1
fi
