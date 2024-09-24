#!/bin/bash

CONFIG_FILE="/home/s1dd/misc/buildtest/test/.config/easC/config.json"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "\033[1;31mConfig file not found.\033[0m"
    exit 1
fi

output_binary=$(jq -r '.output_binary' "$CONFIG_FILE")
library_name=$(jq -r '.library_name' "$CONFIG_FILE")

# Compile library and main program
gcc -fPIC -shared lib/$library_name.c -o lib/$library_name.so
gcc src/main.c -ldl -o build/$output_binary
if [ $? -eq 0 ]; then
    echo -e "\033[1;32mProject compiled successfully.\033[0m"
else
    echo -e "\033[1;31mCompilation failed.\033[0m"
fi
