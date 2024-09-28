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
/**********************
 * INSERT HEADERS HERE
 **********************/

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

/**************************************
 *
 * @X_MACROS
 *
 * Used to generate list like structs of code
 *
 * \$Source: Wikipedia
 *
 * They are most useful when at least some of the lists cannot be composed by indexing, such as compile time. 
 * They provide reliable maintenance of parallel lists whose corresponding 
 * items must be declared or executed in the same order.
 *
 **************************************/

#define EASC_FUNC_LIST \
  EASC(easC_init) \
  EASC(easC_print) \
  EASC(easC_update) \

#endif
EOL

cat <<EOL > "$project_name/lib/$library_name.c"
#include "$library_name.h"

/****************************************
 * $library_name.c
 *
 * This is the implementation of the dynamic library. The functions
 * defined here will be dynamically loaded at runtime by the main
 * program (main.c). These functions can be updated and reloaded 
 * during runtime, enabling "hot reloading."
 *
 * Functions:
 * - easC_init: Initializes the library and prints a message.
 * - easC_print: Prints a message for testing purposes.
 * - easC_update: Updates logic and demonstrates hot reloading.
 ****************************************/

/* Initializes the library */
void easC_init() {
    printf("Library initialized successfully.\n");
}

/* Prints a simple message for testing */
void easC_print() {
    printf("This is the test_print function from the dynamically loaded library.\n");
}

/* Updates the logic and prints a message */
void easC_update() {
    printf("Updated function call. Hot reloading works!\nHello world??\n");
}
EOL

# Create the main C program
cat <<EOL > "$project_name/src/main.c"
#include <stdio.h>
#include <dlfcn.h>
#include <stdbool.h>
#include <stdlib.h>
#include "../lib/$library_name.h"

/****************************************
 * main.c
 *
 * This is the main program. It dynamically loads the library ($library_name.so)
 * at runtime using `dlopen`, retrieves the function symbols using `dlsym`,
 * and can reload the library during runtime, enabling "hot reloading".
 *
 * Key functions:
 * - reload_func: Loads/reloads the dynamic library and retrieves function symbols.
 * - main: Runs an event loop that listens for user input to either reload
 *   the library or execute the functions dynamically loaded from the library.
 ****************************************/

#define LIBEASC "../lib/$library_name.so"
#define RELOAD_SCRIPT "../lib/recompile.sh"  // Script to recompile the library and program

#define HELPER_STRING "Welcome to easC!:\nKEYBINDS:\n\n1. 'r' -- Hot Reload Project\n2. 'c' -- Clear Screen\n3. 'q' -- Quit easC workflow\n\n> "

/****************************************
 * Global Variables:
 * - lib_name: The name of the shared library file.
 * - libplug: Handle for the dynamically loaded library.
 * - Function pointers: All called and defined using X MACROS.
 ****************************************/
const char *lib_name = LIBEASC;
void *libplug = NULL;

/***********************************
 *
 * @X_MACROS DEF 
 *
 * Defining all the typdefs to NULL
 *
 ***********************************/

#define EASC(name) name##_t name = NULL;
EASC_FUNC_LIST
#undef EASC

/****************************************
 * reload_func:
 * Dynamically loads (or reloads) the shared library and retrieves the symbols
 * for the functions to be called dynamically. Uses `dlopen` to open the library
 * and `dlsym` to locate function symbols. If any errors occur, the function
 * prints an error message and returns false.
 ****************************************/
bool reload_func() {
    /* Close the previously opened library if it exists */
    if (libplug != NULL) {
        dlclose(libplug);
    }

    /* Load the shared library ($library_name.so) */
    libplug = dlopen(lib_name, RTLD_NOW);
    if (libplug == NULL) {
        fprintf(stderr, "Couldn't load %s: %s\n", lib_name, dlerror());
        return false;
    }
    
    #define EASC(name) \
        name = dlsym(libplug, #name); \
        if (name == NULL) { \
          fprintf(stderr, "Couldn't find %s symbol: %s\n", \
            #name, dlerror()); \
          return false; \
        }
    EASC_FUNC_LIST 
    #undef EASC 

    /* Successfully loaded the library and retrieved all symbols */
    return true;
}

/****************************************
 * main:
 * The main function runs an event loop that waits for user input.
 * If the user presses 'r', the reload script (reload.sh) is executed
 * to recompile the library, and the library is reloaded to apply changes.
 * Press 'q' to quit the program.
 ****************************************/
int main() {
    /* Load the library and retrieve the function symbols initially */
    if (!reload_func()) {
        return 1;
    }

    /* Initialize the library (call test_init) */
    easC_init();

    char s;  // Variable to store user input

    /* Event loop: Continue until 'q' is pressed */
    while (s != 'q') {
        printf("%s", HELPER_STRING);   

        /* Wait for user input */
        scanf(" %c", &s);  // Add space to ignore any previous newline

        /* If 'r' is pressed, reload the library */
        if (s == 'r') {
            system(RELOAD_SCRIPT);  // Execute the reload script
            if (!reload_func()) return 1;  // Reload the library and symbols
        }

        /* Call the update function (if 'q' is not pressed) */
        if (s != 'q' && s != 'c') {
            printf("--------------------------------\n\n");
            easC_update();
            printf("\n--------------------------------\n");
        }
        /* Simple clear the screen */
        if (s == 'c') {
          system("clear");
        }
    }

    /* Close the library before exiting */
    dlclose(libplug);
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


\`\`\`bash
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
├── Makefile      [OPTIONAL]
├── .clang-format [OPTIONAL]
└── README.md
\`\`\`

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
