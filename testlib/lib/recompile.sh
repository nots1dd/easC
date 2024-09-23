#!/bin/bash

# Colors for cool terminal output
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[1;31m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Configuration file location
CONFIG_FILE="/home/s1dd/misc/buildtest/testlib/.config/easC/config.json"

# Check if the configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Config file not found at $CONFIG_FILE"
    exit 1
fi

# Read values from config.json using jq
library_name=$(jq -r '.library_name' "$CONFIG_FILE")
output_binary=$(jq -r '.output_binary' "$CONFIG_FILE")

# Validate that the values were successfully read
if [ -z "libtest" ] || [ -z "test" ]; then
    echo "${RED}Error reading library_name or output_binary from config.json${RED}"
    exit 1
fi

# Get the absolute path of the script directory
DIR=$(dirname "$(realpath "./build.sh")")

# Compile the dynamic library using absolute paths
gcc -fPIC -shared "$DIR/../lib/libtest.c" -o "$DIR/../lib/libtest.so"
if [ $? -ne 0 ]; then
    echo "${RED}Failed to compile the dynamic library.${NC}"
    exit 1
fi

# Compile the main program using absolute paths
gcc "$DIR/../src/main.c" -ldl -o "$DIR/test"
if [ $? -ne 0 ]; then
    echo "${RED}Failed to compile the main program.${NC}"
    exit 1
fi

echo "${GREEN}Library and program recompiled successfully.${NC}"
