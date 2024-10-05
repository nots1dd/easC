#!/bin/bash
# Recompile the dynamic library

YELLOW='\033[1;33m'
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

gcc -fPIC -shared ../lib/libtestnew.c -o ../lib/libtestnew.so
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Library recompiled successfully.${NC}"
else
    echo -e "${RED}Error recompiling the library.${NC}"
    exit 1
fi
