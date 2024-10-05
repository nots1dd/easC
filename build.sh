#!/bin/bash

# Colors for terminal output
YELLOW='\033[1;33m'
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Dynamic Build Flag
DYNC_FLAG="EASC_DYNC"

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
#include <stdbool.h>
/**********************
 * INSERT HEADERS HERE
 **********************/

/****************************************
 * $library_name.h
 * 
 * This header contains function declarations for 
 * dynamic library functions used by the main program.
 ****************************************/

 /***************************************
  * 
  * @STATE MANAGEMENT
  * 
  * Not everything is meant to be re-run
  * when reloading. Some things must be 
  * accounted for before and after reload.
  *
  * Hence, to ensure that a few aspects of
  * your project gracefully handle state change, 
  * we have a typedef struct easC_State
  * 
  * \$PRE RELOAD: 
  * Before reloading we return the previous state 
  * of the struct to a void pointer.
  * 
  * \$POST RELOAD:
  * After running reload_func in main.c, 
  * we give the easC_post_reload_t typdef 
  * the previous state's struct pointer to 
  * preserve the information that YOU need 
  * to avoid unexpected runtime errors.
  * 
 ****************************************/

typedef struct 
{

} easC_State;

/* Typedef for dynamic function pointers */
typedef void (easC_print_t)(void);
typedef void (easC_init_t)(void);
typedef void* (easC_pre_reload_t)(void);
typedef void (easC_post_reload_t)(void*);
typedef bool (easC_event_loop_condn_true_t)(char s);
typedef void (easC_update_t)(void);

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
  EASC(easC_pre_reload) \
  EASC(easC_post_reload) \
  EASC(easC_event_loop_condn_true) \
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

/********************
 * @State management decl
 ********************/

easC_State *state = NULL;

/* Initializes the library */
void easC_init() {
    printf("Library initialized successfully.\n");
}

/* Prints a simple message for testing */
void easC_print() {
    printf("This is the test_print function from the dynamically loaded library.\n");
}

/* Event loop condition for main.c */ 
bool easC_event_loop_condn_true(char s)
{
  if (s != 'q')
  {
    return true;
  }

  return false;
}

/* Before invoking reload_func, store the state */
easC_State *easC_pre_reload(void)
{ 
  return state;
}

/* After invoking reload_func, give the previous state to the new state */
void easC_post_reload(easC_State *prev)
{
  state = prev;
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
#include <signal.h>
#include <string.h>
#include <setjmp.h>
#include <execinfo.h>
#include <limits.h>
#include <unistd.h>
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

 extern char **environ;

/* ANSI COLOR ESCAPE VALUES */
#define COLOR_RESET      "\033[0m"
#define COLOR_RED        "\033[31m"
#define COLOR_YELLOW     "\033[33m"
#define COLOR_CYAN       "\033[36m"
#define COLOR_BOLD       "\033[1m"
#define COLOR_GREEN      "\033[32m"

#define BOX_WIDTH 50

// Utility function to print a box
void print_box(const char *message, const char* color) {
    int len = strlen(message);
    int padding = (BOX_WIDTH - len) / 2;

    // Print top border
    printf("%s+", COLOR_GREEN);
    for (int i = 0; i < BOX_WIDTH; i++) printf("-");
    printf("+%s\n", COLOR_RESET);

    // Print message with padding
    printf("%s|%s", COLOR_GREEN, COLOR_RESET);
    for (int i = 0; i < padding; i++) printf(" ");
    printf("%s%s%s", message, color, COLOR_RESET);
    for (int i = 0; i < BOX_WIDTH - len - padding; i++) printf(" ");
    printf("%s|\n", COLOR_GREEN);

    // Print bottom border
    printf("%s+", COLOR_GREEN);
    for (int i = 0; i < BOX_WIDTH; i++) printf("-");
    printf("+%s\n", COLOR_RESET);
}

#define LIBEASC "../lib/$library_name.so"
#define RELOAD_SCRIPT "../lib/recompile.sh"  // Script to recompile the library and program

#define HELPER_STRING "Welcome to easC!:\nKEYBINDS:\n\n1. 'r' -- Hot Reload Project\n2. 'c' -- Clear Screen\n3. 'q' -- Quit easC workflow\n\n> "

/* RUNTIME ERROR MESSAGES */ 
#define SEG_FAULT_MESSAGE  "[easC_SEGV] easC has detected segfault in easC_update! Recovering....\n"
#define ABRT_FAULT_MESSAGE "[easC_ABRT] easC has detected abort signal due to unknown reasons!! Recovering....\n"
#define FPE_FAULT_MESSAGE  "[easC_FPE] easC has detected a floating point exception!! Recovering...\n"

/****************************************
 * Global Variables:
 * - lib_name: The name of the shared library file.
 * - libplug: Handle for the dynamically loaded library.
 * - Function pointers: All called and defined using X MACROS.
 ****************************************/
const char *lib_name = LIBEASC;
void *libplug = NULL;

jmp_buf recovery_point;

/* Signal handler function for segfault and other errors */
void easC_SIG_HANDLER(int sig, siginfo_t *si, void *unused) {
    // Print signal-specific message with color
    if (sig == SIGSEGV) {
        printf("\n%s%s%s\n", COLOR_RED, COLOR_BOLD, SEG_FAULT_MESSAGE);
        printf("%sSegmentation fault occurred! Details:%s\n", COLOR_RED, COLOR_RESET);
        printf("%s- Faulting address: %p\n", COLOR_YELLOW, si->si_addr);
        printf("- Attempted to read or write to an invalid memory address.\n"
               "- Dereferencing a NULL or uninitialized pointer.\n"
               "- Buffer overflow or accessing array out of bounds.\n"
               "- Possible location: ");
        
        // Use addr2line to get file and line information (if available)
        if (si->si_addr) {
            printf("- Possible location: ");
            // Use addr2line to get file and line information (if available)
            char cmd[256];
            snprintf(cmd, sizeof(cmd), "addr2line -e /proc/%d/exe %p", getpid(), si->si_addr);
            FILE *fp = popen(cmd, "r");
            if (fp) {
                char output[256];
                if (fgets(output, sizeof(output), fp) != NULL) {
                    printf("%s", output);
                } else {
                    printf("Unable to determine location\n");
                }
                pclose(fp);
            } else {
                printf("Unable to run addr2line\n");
            }
        } else {
            printf("- Unable to determine location (NULL address)\n");
        }
        printf("%s\n", COLOR_RESET);
    } else if (sig == SIGABRT) {
        printf("\n%s%s%s\n", COLOR_RED, COLOR_BOLD, ABRT_FAULT_MESSAGE);
        printf("%sAbort signal received! This could be due to:%s\n", COLOR_YELLOW, COLOR_RESET);
        printf("%s- An assertion failure or explicit call to abort().\n"
               "- Memory corruption detected by the C library.\n"
               "- Unhandled exception in C++ code.%s\n", COLOR_YELLOW, COLOR_RESET);
    } else if (sig == SIGFPE) {
        printf("\n%s%s%s\n", COLOR_RED, COLOR_BOLD, FPE_FAULT_MESSAGE);
        printf("%sFloating-point exception occurred! Details:%s\n", COLOR_YELLOW, COLOR_RESET);
        printf("%s- Type: ", COLOR_YELLOW);
        switch (si->si_code) {
            case FPE_INTDIV: printf("Integer divide by zero\n"); break;
            case FPE_INTOVF: printf("Integer overflow\n"); break;
            case FPE_FLTDIV: printf("Floating-point divide by zero\n"); break;
            case FPE_FLTOVF: printf("Floating-point overflow\n"); break;
            case FPE_FLTUND: printf("Floating-point underflow\n"); break;
            case FPE_FLTRES: printf("Floating-point inexact result\n"); break;
            case FPE_FLTINV: printf("Invalid floating-point operation\n"); break;
            case FPE_FLTSUB: printf("Subscript out of range\n"); break;
            default: printf("Unknown floating-point exception\n");
        }
        printf("%s\n", COLOR_RESET);
    } else {
        printf("%sUnknown signal received: %d. Recovering...\n", COLOR_YELLOW, sig);
    }

    // Print additional process information
    printf("%sProcess Information:%s\n", COLOR_YELLOW, COLOR_RESET);
    
    // Get program name (portable way)
    char program_name[PATH_MAX];
    ssize_t len = readlink("/proc/self/exe", program_name, sizeof(program_name) - 1);
    if (len != -1) {
        program_name[len] = '\0';
        printf("  Program Name: %s\n", program_name);
    } else {
        printf("  Program Name: Unknown\n");
    }
    
    printf("  Process ID: %d\n", getpid());
    printf("  Parent Process ID: %d\n", getppid());
    printf("  Signal: %d\n", sig);
    printf("  Signal origin: %s\n", (si->si_pid == 0) ? "Kernel" : "User process");
    if (si->si_pid != 0) {
        printf("  Sending process ID: %d\n", si->si_pid);
    }

    // Print current working directory
    char cwd[PATH_MAX];
    if (getcwd(cwd, sizeof(cwd)) != NULL) {
        printf("  Current working directory: %s\n", cwd);
    }

    // Print environment variables
    printf("  Relevant environment variables:\n");
    char **env = environ;
    while (*env) {
        if (strncmp(*env, "PATH=", 5) == 0 || strncmp(*env, "LD_LIBRARY_PATH=", 16) == 0) {
            printf("    %s\n", *env);
        }
        env++;
    }

    // Print a stack trace in a box
    void *array[20];
    size_t size;
    char **strings;
    size = backtrace(array, 20);
    strings = backtrace_symbols(array, size);

    print_box("Stack Trace:", COLOR_CYAN);
    for (size_t i = 0; i < size; i++) {
        printf("%s\n", strings[i]);
    }
    free(strings);

    // Jump to the recovery point set earlier
    longjmp(recovery_point, sig);
}

/***********************************
 *
 * @X_MACROS DEF 
 *
 * Defining all the typdefs to NULL
 *
 ***********************************/

#ifdef EASC_DYNC
#define EASC(name) name##_t *name = NULL;
#else 
#define EASC(name) name##_t name;
#endif
EASC_FUNC_LIST
#undef EASC

/****************************************
 * reload_func:
 * Dynamically loads (or reloads) the shared library and retrieves the symbols
 * for the functions to be called dynamically. Uses `dlopen` to open the library
 * and `dlsym` to locate function symbols. If any errors occur, the function
 * prints an error message and returns false.
 ****************************************/
#ifdef EASC_DYNC
bool reload_func() {
    /* Close the previously opened library if it exists */
    if (libplug != NULL) {
        dlclose(libplug);
    }

    /* Load the shared library (libeasc.so) */
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
#else 
#define reload_func() true
#endif

void safe_call(easC_update_t func, const char* func_name) {
    if (func != NULL) {
        int sig = setjmp(recovery_point);
        if (sig == 0) {
            func();
        } else {
            printf("%s%s[ERROR] %s caused an error (signal %d). Rebinding event loop...\n%s",
                   COLOR_RED, COLOR_BOLD, func_name, sig, COLOR_RESET);
        }
    } else {
        printf("%s%s[WARNING] %s is NULL. Skipping...\n%s",
               COLOR_YELLOW, COLOR_BOLD, func_name, COLOR_RESET);
    }
}

void easC_Event_Loop() {
    char s = 0;
    void* state = NULL;

    while (easC_event_loop_condn_true != NULL && easC_event_loop_condn_true(s)) { 

        printf("%s", HELPER_STRING);
        scanf(" %c", &s);

        if (s == 'r') {
            if (easC_pre_reload != NULL) {
                state = easC_pre_reload();
            }
            if (!reload_func()) {
                printf("%s%s[WARNING] Failed to reload library. Continuing with previous version.\n%s",
                       COLOR_YELLOW, COLOR_BOLD, COLOR_RESET);
            } else {
                if (easC_post_reload != NULL) {
                    int sig = setjmp(recovery_point);
                    if (sig == 0) {
                        easC_post_reload(state);
                    } else {
                        printf("%s%s[ERROR] easC_post_reload caused an error (signal %d). Rebinding event loop...\n%s",
                               COLOR_RED, COLOR_BOLD, sig, COLOR_RESET);
                    }
                }
            }
        } else if (s == 'q') {
            printf("\n%sExiting easC with code 0%s\n", COLOR_GREEN, COLOR_RESET);
            return;
        } else if (s == 'c') {
            system("clear");
        }
       
        if (easC_update != NULL && s == 'r') {      
          printf("----------------------------- EASC_UPDATE ----------------------------------\n\n");
          safe_call(easC_update, "easC_update");
          printf("\n---------------------------- EASC_UPDATE ----------------------------------\n");
        }
  }
}

/****************************************
 * main:
 * The main function runs an event loop that waits for user input.
 * If the user presses 'r', the reload script (reload.sh) is executed
 * to recompile the library, and the library is reloaded to apply changes.
 * Press 'q' to quit the program.
 ****************************************/
int main() {
    
    struct sigaction sa;
    sa.sa_sigaction = easC_SIG_HANDLER;
    sa.sa_flags = SA_SIGINFO;
    sigemptyset(&sa.sa_mask);
    sigaction(SIGSEGV, &sa, NULL);
    sigaction(SIGABRT, &sa, NULL);
    sigaction(SIGFPE, &sa, NULL);
    
    /* Load the library and retrieve the function symbols initially */
    if (!reload_func()) {
        printf("%s%sError: Failed to load initial library. You can retry with 'r'.\nExiting with code 5.\n%s", COLOR_RED, COLOR_BOLD, COLOR_RESET);
        return 5;
    }

    /* Initialize the library (call test_init) */
    easC_init();

    /* Event loop: Continue until 'q' is pressed */
    easC_Event_Loop();

    /* Close the library before exiting */
    #ifdef EASC_DYNC
    dlclose(libplug);
    #else 
    printf("Exiting statically...\n");
    #endif
    return 0;
}
EOL

# Creating static compile build file
cat <<EOL > "$project_name/staticompile.sh"
#!/bin/bash

YELLOW='\033[1;33m'
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

CONFIG_FILE="$config_file"

if [ ! -f "\$CONFIG_FILE" ]; then
    echo "\${RED}Config file not found.\${NC}"
    exit 1
fi

output_binary=\$(jq -r '.output_binary' "\$CONFIG_FILE")-static
library_name=\$(jq -r '.library_name' "\$CONFIG_FILE")

# Compile library and main program
gcc -fPIC -shared lib/\$library_name.c -o lib/\$library_name.so
gcc lib/\$library_name.c src/main.c -ldl -o build/\$output_binary
if [ \$? -eq 0 ]; then
    echo -e "\${GREEN}Project compiled successfully.\${NC}"
else
    echo -e "\${RED}Compilation failed.\${NC}"
fi
EOL

chmod +x "$project_name/staticompile.sh"

# Create recompile.sh script
cat <<EOL > "$project_name/lib/recompile.sh"
#!/bin/bash
# Recompile the dynamic library

YELLOW='\033[1;33m'
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

gcc -fPIC -shared ../lib/$library_name.c -o ../lib/$library_name.so
if [ \$? -eq 0 ]; then
    echo -e "\${GREEN}Library recompiled successfully.\${NC}"
else
    echo -e "\${RED}Error recompiling the library.\${NC}"
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

YELLOW='\033[1;33m'
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

CONFIG_FILE="$config_file"

if [ ! -f "\$CONFIG_FILE" ]; then
    echo "\${RED}Config file not found.\${NC}"
    exit 1
fi

output_binary=\$(jq -r '.output_binary' "\$CONFIG_FILE")
library_name=\$(jq -r '.library_name' "\$CONFIG_FILE")

# Compile library and main program
gcc -fPIC -shared lib/\$library_name.c -o lib/\$library_name.so
gcc src/main.c -ldl -o build/\$output_binary -D${DYNC_FLAG}
if [ \$? -eq 0 ]; then
    echo -e "\${GREEN}Project compiled successfully.\${NC}"
else
    echo -e "\${RED}Compilation failed.\${NC}"
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
├── staticompile.sh
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
To compile the project [DYNAMIC BUILD]:
\`\`\`bash
./init.sh
\`\`\`

To compile the project [STATIC BUILD]:
\`\`\`bash 
./staticompile.sh 
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
echo "├── staticompile.sh"
echo "├── Makefile      (optional)"
echo "├── .clang-format (optional)"
echo "└── README.md"

echo -e "${GREEN}To get started:${NC}"
echo -e "1. Navigate to your project folder: ${YELLOW}cd $project_name${NC}"
echo -e "2. Run ${YELLOW}./init.sh${NC} to initially compile the library and binary."
echo -e "3. Run: cd build/; export LD_LIBRARY_PATH=.:\$LD_LIBRARY_PATH"
echo -e "4. Run your program: ${YELLOW}./$output_binary${NC}"
echo -e "5. While the binary $output_binary is running, press 'r' in the running program to reload the library and apply changes."

# Final message
echo -e "${GREEN} easC project $project_name has been initialized successfully!${NC}"
