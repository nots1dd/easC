#include <stdio.h>
#include <dlfcn.h>
#include <stdbool.h>
#include <stdlib.h>
#include "../lib/libtest.h"

/****************************************
 * main.c
 *
 * This is the main program. It dynamically loads the library (libtest.so)
 * at runtime using , retrieves the function symbols using ,
 * and can reload the library during runtime, enabling "hot reloading".
 *
 * Key functions:
 * - reload_func: Loads/reloads the dynamic library and retrieves function symbols.
 * - main: Runs an event loop that listens for user input to either reload
 *   the library or execute the functions dynamically loaded from the library.
 ****************************************/

#define LIBEASC "../lib/libtest.so"
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
 * for the functions to be called dynamically. Uses  to open the library
 * and  to locate function symbols. If any errors occur, the function
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
    
    #define EASC(name)         name = dlsym(libplug, #name);         if (name == NULL) {           fprintf(stderr, "Couldn't find %s symbol: %s\n",             #name, dlerror());           return false;         }
    EASC_FUNC_LIST 
    #undef EASC 

    /* Successfully loaded the library and retrieved all symbols */
    return true;
}
#else 
#define reload_func() true
#endif

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
    #ifdef EASC_DYNC
    dlclose(libplug);
    #else 
    printf("Exiting statically...\n");
    #endif
    return 0;
}
