#!/bin/bash

# Colors for cool terminal output
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

echo -e "${BLUE}Welcome to easC (Easy to configure C framework with dynamic lib support!) initializer!${NC}"

# Prompting for project name
while true; do
    echo -e "${YELLOW}Enter your project name:${NC}"
    read project_name
    if validate_input "$project_name"; then
        break
    fi
done

# Prompting for output binary name
while true; do
    echo -e "${YELLOW}Enter the name of your output binary (default: ${GREEN}main${NC}):${NC}"
    read output_binary
    output_binary=${output_binary:-main}
    if validate_input "$output_binary"; then
        break
    fi
done

# Prompting for the library name
while true; do
    echo -e "${YELLOW}Enter the name of the hot-reloadable library (default: ${GREEN}libeasc${NC}):${NC}"
    read library_name
    library_name=${library_name:-libeasc}
    if validate_input "$library_name"; then
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

# libeasc.h (header file)
cat <<EOL > "$project_name/lib/$library_name.h"
#ifndef $library_name
#define $library_name

#include <stdio.h>

/****************************************
 * $library_name.h
 *
 * This header file contains function declarations and typedefs
 * for function pointers used in the dynamic library. These functions
 * are declared here and defined in the dynamic library ($library_name.c).
 *
 * The typedefs allow us to reference the functions dynamically when
 * loading them from the shared object (.so) file in the main program.
 ****************************************/

/* Typedef for easC_print function pointer */
typedef void (*easC_print_t)(void);

/* Typedef for easC_init function pointer */
typedef void (*easC_init_t)(void);

/* Typedef for easC_update function pointer */
typedef void (*easC_update_t)(void);

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

# main.c (main program)
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

#define EASC_SYM_PRINT "easC_print"
#define EASC_SYM_INIT  "easC_init"
#define EASC_SYM_UPD   "easC_update"

/****************************************
 * Global Variables:
 * - lib_name: The name of the shared library file.
 * - libplug: Handle for the dynamically loaded library.
 * - Function pointers: test_print, test_init, test_update (retrieved using dlsym).
 ****************************************/
const char *lib_name = LIBEASC;
void *libplug = NULL;

easC_print_t easC_print = NULL;
easC_init_t easC_init = NULL;
easC_update_t easC_update = NULL;

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

    /* Retrieve the test_print function symbol */
    easC_print = dlsym(libplug, EASC_SYM_PRINT);
    if (easC_print == NULL) {
        fprintf(stderr, "Couldn't find symbol test_print: %s\n", dlerror());
        return false;
    }

    /* Retrieve the test_init function symbol */
    easC_init = dlsym(libplug, EASC_SYM_INIT);
    if (easC_init == NULL) {
        fprintf(stderr, "Couldn't find symbol test_init: %s\n", dlerror());
        return false;
    }

    /* Retrieve the test_update function symbol */
    easC_update = dlsym(libplug, EASC_SYM_UPD);
    if (easC_update == NULL) {
        fprintf(stderr, "Couldn't find symbol test_update: %s\n", dlerror());
        return false;
    }

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
        printf("Press 'r' to reload or 'q' to quit: ");
        
        /* Wait for user input */
        scanf(" %c", &s);  // Add space to ignore any previous newline

        /* If 'r' is pressed, reload the library */
        if (s == 'r') {
            system(RELOAD_SCRIPT);  // Execute the reload script
            if (!reload_func()) return 1;  // Reload the library and symbols
        }

        /* Call the test_update function (if 'q' is not pressed) */
        if (s != 'q') {
            easC_update();
        }
    }

    /* Close the library before exiting */
    dlclose(libplug);
    return 0;
}
EOL

# reload.sh (script to recompile the library and main program)
cat <<EOL > "$project_name/init.sh"
#!/bin/bash

# Configuration file location
CONFIG_FILE="$project_dir/config.json"

# Check if the configuration file exists
if [ ! -f "\$CONFIG_FILE" ]; then
    echo "Config file not found at \$CONFIG_FILE"
    exit 1
fi

# Read values from config.json using jq
library_name=\$(jq -r '.library_name' "\$CONFIG_FILE")
output_binary=\$(jq -r '.output_binary' "\$CONFIG_FILE")

# Validate that the values were successfully read
if [ -z "$library_name" ] || [ -z "$output_binary" ]; then
    echo "Error reading library_name or output_binary from config.json"
    exit 1
fi

# Get the absolute path of the script directory
DIR=\$(dirname "\$(realpath "$0")")

# Compile the dynamic library using absolute paths
gcc -fPIC -shared "\$DIR/lib/$library_name.c" -o "\$DIR/lib/$library_name.so"
if [ \$? -ne 0 ]; then
    echo "Failed to compile the dynamic library."
    exit 1
fi

# Compile the main program using absolute paths
gcc "\$DIR/src/main.c" -ldl -o "\$DIR/build/$output_binary"
if [ \$? -ne 0 ]; then
    echo "Failed to compile the main program."
    exit 1
fi

echo "Library and program recompiled successfully."
EOL

chmod +x "$project_name/init.sh"

cat <<EOL > "$project_name/lib/recompile.sh"
#!/bin/bash

# Colors for cool terminal output
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[1;31m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Configuration file location
CONFIG_FILE="$project_dir/config.json"

# Check if the configuration file exists
if [ ! -f "\$CONFIG_FILE" ]; then
    echo "Config file not found at \$CONFIG_FILE"
    exit 1
fi

# Read values from config.json using jq
library_name=\$(jq -r '.library_name' "\$CONFIG_FILE")
output_binary=\$(jq -r '.output_binary' "\$CONFIG_FILE")

# Validate that the values were successfully read
if [ -z "$library_name" ] || [ -z "$output_binary" ]; then
    echo "\${RED}Error reading library_name or output_binary from config.json\${RED}"
    exit 1
fi

# Get the absolute path of the script directory
DIR=\$(dirname "\$(realpath "./build.sh")")

# Compile the dynamic library using absolute paths
gcc -fPIC -shared "\$DIR/../lib/$library_name.c" -o "\$DIR/../lib/$library_name.so"
if [ \$? -ne 0 ]; then
    echo "\${RED}Failed to compile the dynamic library.\${NC}"
    exit 1
fi

# Compile the main program using absolute paths
gcc "\$DIR/../src/main.c" -ldl -o "\$DIR/$output_binary"
if [ \$? -ne 0 ]; then
    echo "\${RED}Failed to compile the main program.\${NC}"
    exit 1
fi

echo "\${GREEN}Library and program recompiled successfully.\${NC}"
EOL

chmod +x "$project_name/lib/recompile.sh"

# Create README.md with project structure and instructions
cat <<EOL > "$project_name/README.md"
# $project_name

## Project Structure
Your easC project is ready with the following structure:

\`\`\`
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
└── README.md
\`\`\`

## Instructions
1. Navigate to your project folder: \`cd $project_name\`
2. Run \`./init.sh\` to initially compile the library and binary.
3. Run \`cd build/; export LD_LIBRARY_PATH=.:\$LD_LIBRARY_PATH\`
4. Run your program: \`./$output_binary\`
5. While the binary `$output_binary` is still running, press 'r' in the running program to reload the library and apply changes.

Hope you had an easC time!
EOL

# Display project structure
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
echo "└── README.md"

# Instructions
echo -e "${GREEN}To get started:${NC}"
echo -e "1. Navigate to your project folder: ${YELLOW}cd $project_name${NC}"
echo -e "2. Run ${YELLOW}./init.sh${NC} to initially compile the library and binary."
echo -e "3. Run: cd build/; export LD_LIBRARY_PATH=.:\$LD_LIBRARY_PATH"
echo -e "4. Run your program: ${YELLOW}./$output_binary${NC}"
echo -e "5. While the binary $output_binary is running, press 'r' in the running program to reload the library and apply changes."

echo -e "${BLUE}Hope you had an easC time!${NC}"
