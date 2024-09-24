#include "libtest.h"

/****************************************
 * libtest.c
 * 
 * This file contains the implementation of the dynamic 
 * library functions. They will be hot-reloaded during 
 * runtime by the main program.
 ****************************************/

void easC_init() {
    printf("Library initialized successfully.\n");
}

void easC_print() {
    printf("This is the test_print function from the dynamically loaded library.\n");
}

void easC_update() {
    printf("ummm ok\n");
}
