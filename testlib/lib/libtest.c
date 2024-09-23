#include "libtest.h"

/****************************************
 * libtest.c
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
