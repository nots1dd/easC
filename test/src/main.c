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
 * for the functions to be called dynamically. Uses  to open the library
 * and  to locate function symbols. If any errors occur, the function
 * prints an error message and returns false.
 ****************************************/
bool reload_func() {
    /* Close the previously opened library if it exists */
    if (libplug != NULL) {
        dlclose(libplug);
    }

    /* Load the shared library (libtest.so) */
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
        printf("Welcome to easC!:\nKEYBINDS:\n\n1. 'r' -- Hot Reload Project\n2. 'c' -- Clear Screen\n3. 'q' -- Quit easC workflow\n");
        
        /* Wait for user input */
        scanf(" %c", &s);  // Add space to ignore any previous newline

        /* If 'r' is pressed, reload the library */
        if (s == 'r') {
            system(RELOAD_SCRIPT);  // Execute the reload script
            if (!reload_func()) return 1;  // Reload the library and symbols
        }

        /* Call the test_update function (if 'q' is not pressed) */
        if (s != 'q' && s != 'c') {
            easC_update();
        }
        if (s == 'c') {
          system("clear");
          printf("[EASC] Clear screen successfully!\n");
        }
    }

    /* Close the library before exiting */
    dlclose(libplug);
    return 0;
}
