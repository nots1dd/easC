#!/bin/bash

# Colors for terminal output
YELLOW='\033[1;33m'
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Function to validate input
validate_input() {
    if [[ ! "$1" =~ ^[a-zA-Z0-9_]+$ ]]; then
        echo -e "${RED}Error: Input can only contain alphanumeric characters and underscores.${NC}"
        return 1
    fi
    return 0
}

# Welcome message
echo -e "${BLUE}Welcome to easC (Easy-to-configure C framework with dynamic lib support!) initializer!${NC}"

# Prompt for project name
while true; do
    echo -e "${YELLOW}Enter your project name:${NC}"
    read project_name
    if validate_input "$project_name"; then
        break
    fi
done

# Prompt for output binary name
while true; do
    echo -e "${YELLOW}Enter the name of your output binary (default: ${GREEN}main${NC}):${NC}"
    read output_binary
    output_binary=${output_binary:-main}
    if validate_input "$output_binary"; then
        break
    fi
done

# Prompt for the library name
while true; do
    echo -e "${YELLOW}Enter the name of the hot-reloadable library (default: ${GREEN}libeasc${NC}):${NC}"
    read library_name
    library_name=${library_name:-libeasc}
    if validate_input "$library_name"; then
        break
    fi
done

# Function to validate yes/no input
validate_yes_no() {
    if [[ "$1" != "y" && "$1" != "n" ]]; then
        echo -e "${RED}Error: Please enter 'y' for yes or 'n' for no.${NC}"
        return 1
    fi
    return 0
}

# Ask user if they want to add a .clang-format configuration
while true; do
    echo -e "${YELLOW}Would you like to add a .clang-format configuration? (y/n)${NC}"
    read add_clang_format
    if validate_yes_no "$add_clang_format"; then
        break
    fi
done

# Ask user if they want to generate a Makefile
while true; do
    echo -e "${YELLOW}Would you like to generate a Makefile? (y/n)${NC}"
    read generate_makefile
    if validate_yes_no "$generate_makefile"; then
        break
    fi
done

# Define project directory
project_dir="$(pwd)/$project_name/.config/easC"
config_file="$project_dir/config.json"

# Create project directory and config directory if not exists
mkdir -p "$project_dir"

# Write project information to the config file
echo -e "${BLUE}Generating project configuration...${NC}"

# Create or update config.json
jq -n \
--arg project_name "$project_name" \
--arg output_binary "$output_binary" \
--arg library_name "$library_name" \
'{
    "project_name": $project_name,
    "output_binary": $output_binary,
    "library_name": $library_name
}' > "$config_file"

echo -e "${GREEN}Configuration stored at $config_file${NC}"

# Directory structure for the new project
echo -e "${BLUE}Setting up your project structure...${NC}"

mkdir -p "$project_name/src"
mkdir -p "$project_name/lib"
mkdir -p "$project_name/build"
mkdir -p "$project_name/include"

# Create C library header and source files
cat <<EOL > "$project_name/lib/$library_name.h"
#ifndef ${library_name^^}_H
#define ${library_name^^}_H

#include <stdio.h>

/****************************************
 * $library_name.h
 * 
 * This header contains function declarations for 
 * dynamic library functions used by the main program.
 ****************************************/

/* Typedef for dynamic function pointers */
typedef void (*easC_print_t)(void);
typedef void (*easC_init_t)(void);
typedef void (*easC_update_t)(void);

#endif // ${library_name^^}_H
EOL

cat <<EOL > "$project_name/lib/$library_name.c"
#include "$library_name.h"

/****************************************
 * $library_name.c
 * 
 * This file contains the implementation of the dynamic 
 * library functions. They will be hot-reloaded during 
 * runtime by the main program.
 ****************************************/

void easC_init() {
    printf("Library initialized successfully.\\n");
}

void easC_print() {
    printf("This is the test_print function from the dynamically loaded library.\\n");
}

void easC_update() {
    printf("Updated function call. Hot reloading works!\\n");
}
EOL

# Create the main C program
cat <<EOL > "$project_name/src/main.c"
#include <stdio.h>
#include <dlfcn.h>
#include <stdbool.h>
#include <stdlib.h>
#include "../lib/$library_name.h"

#define LIBRARY_PATH "../lib/$library_name.so"
#define RELOAD_SCRIPT "../lib/recompile.sh"

/* Global function pointers */
easC_print_t easC_print = NULL;
easC_init_t easC_init = NULL;
easC_update_t easC_update = NULL;

/* Function to load/reload dynamic library */
bool reload_library(void **lib_handle) {
    if (*lib_handle != NULL) {
        dlclose(*lib_handle);
    }
    *lib_handle = dlopen(LIBRARY_PATH, RTLD_NOW);
    if (!*lib_handle) {
        fprintf(stderr, "Error loading library: %s\\n", dlerror());
        return false;
    }

    easC_print = dlsym(*lib_handle, "easC_print");
    easC_init = dlsym(*lib_handle, "easC_init");
    easC_update = dlsym(*lib_handle, "easC_update");

    if (!easC_print || !easC_init || !easC_update) {
        fprintf(stderr, "Error loading symbols: %s\\n", dlerror());
        return false;
    }
    return true;
}

int main() {
    void *lib_handle = NULL;

    if (!reload_library(&lib_handle)) return 1;

    easC_init();

    char input;
    while (true) {
        printf("Press 'r' to reload library, 'q' to quit: ");
        scanf(" %c", &input);

        if (input == 'r') {
            system(RELOAD_SCRIPT);
            if (!reload_library(&lib_handle)) return 1;
        } else if (input == 'q') {
            break;
        }

        easC_update();
    }

    dlclose(lib_handle);
    return 0;
}
EOL

# Create recompile.sh script
cat <<EOL > "$project_name/lib/recompile.sh"
#!/bin/bash
# Recompile the dynamic library

gcc -fPIC -shared ../lib/$library_name.c -o ../lib/$library_name.so
if [ \$? -eq 0 ]; then
    echo -e "${GREEN}Library recompiled successfully.${NC}"
else
    echo -e "${RED}Error recompiling the library.${NC}"
    exit 1
fi
EOL
chmod +x "$project_name/lib/recompile.sh"

# Optional: Generate a Makefile
if [ "$generate_makefile" == "y" ]; then
    echo -e "${BLUE}Generating Makefile...${NC}"
    cat <<EOL > "$project_name/Makefile"
CC=gcc
CFLAGS=-Wall -g
LDFLAGS=-ldl

# Default target
all: lib/$library_name.so build/$output_binary

lib/$library_name.so: lib/$library_name.c
	\$(CC) -fPIC -shared lib/$library_name.c -o lib/$library_name.so

build/$output_binary: src/main.c lib/$library_name.so
	\$(CC) src/main.c \$(LDFLAGS) -o build/$output_binary

clean:
	rm -rf build/* lib/*.so

.PHONY: clean
EOL
    echo -e "${GREEN}Makefile generated.${NC}"
fi

# Optional: Add a .clang-format file
if [ "$add_clang_format" == "y" ]; then
    echo -e "${BLUE}Adding .clang-format...${NC}"
    cat <<EOL > "$project_name/.clang-format"
BasedOnStyle: Google
IndentWidth: 4
ColumnLimit: 80
SortIncludes: true
EOL
    echo -e "${GREEN}.clang-format added.${NC}"
fi

# Create init.sh to compile the project
cat <<EOL > "$project_name/init.sh"
#!/bin/bash

CONFIG_FILE="$config_file"

if [ ! -f "\$CONFIG_FILE" ]; then
    echo "${RED}Config file not found.${NC}"
    exit 1
fi

output_binary=\$(jq -r '.output_binary' "\$CONFIG_FILE")
library_name=\$(jq -r '.library_name' "\$CONFIG_FILE")

# Compile library and main program
gcc -fPIC -shared lib/\$library_name.c -o lib/\$library_name.so
gcc src/main.c -ldl -o build/\$output_binary
if [ \$? -eq 0 ]; then
    echo -e "${GREEN}Project compiled successfully.${NC}"
else
    echo -e "${RED}Compilation failed.${NC}"
fi
EOL
chmod +x "$project_name/init.sh"

# Update README with project scope and usage instructions
cat <<EOL > "$project_name/README.md"
# $project_name

## Overview
This is a basic C framework built with dynamic library support using \`dlopen\`, \`dlsym\`, and \`dlclose\`. 
It supports hot-reloading, allowing library code to be updated without restarting the program.

## File structure 

\\\
$project_name/
├── .config/easC/
│    └── config.json
├── src/
│   └── main.c
├── lib/
│   ├── $library_name.c
│   ├── $library_name.h
│   └── recompile.sh
├── build/
├── init.sh
├── Makefile     [OPTIONAL]
├──.clang-format [OPTIONAL]
└── README.md
\\\

## Features
- Dynamic function loading and reloading.
- Easy recompile script for library changes.
- Optional .clang-format for code styling.
- Makefile for streamlined builds.

## Usage
To compile the project:
\`\`\`bash
./init.sh
\`\`\`

To run the project:
\`\`\`bash
cd build && ./\$output_binary
\`\`\`

To reload the library at runtime, press 'r'. Press 'q' to quit.

## Requirements
- gcc
- make (optional)
- clang-format (optional)

EOL

echo -e "${GREEN}Your easC project is ready with the following structure:${NC}"
echo -e "${YELLOW}$project_name${NC}/"
echo "├── .config/easC/"
echo "│    └── config.json"
echo "├── src/"
echo "│   └── main.c"
echo "├── lib/"
echo "│   ├── $library_name.c"
echo "│   ├── $library_name.h"
echo "│   └── recompile.sh"
echo "├── build/"
echo "├── init.sh"
echo "├── Makefile (optional)"
echo "├── .clang-format (optional)"
echo "└── README.md"

echo -e "${GREEN}To get started:${NC}"
echo -e "1. Navigate to your project folder: ${YELLOW}cd $project_name${NC}"
echo -e "2. Run ${YELLOW}./init.sh${NC} to initially compile the library and binary."
echo -e "3. Run: cd build/; export LD_LIBRARY_PATH=.:\$LD_LIBRARY_PATH"
echo -e "4. Run your program: ${YELLOW}./$output_binary${NC}"
echo -e "5. While the binary $output_binary is running, press 'r' in the running program to reload the library and apply changes."

# Final message
echo -e "${GREEN}Project $project_name has been initialized successfully!${NC}"
