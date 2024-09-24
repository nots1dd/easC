#include <stdio.h>
#include <dlfcn.h>
#include <stdbool.h>
#include <stdlib.h>
#include "../lib/libtest.h"

#define LIBRARY_PATH "../lib/libtest.so"
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
        fprintf(stderr, "Error loading library: %s\n", dlerror());
        return false;
    }

    easC_print = dlsym(*lib_handle, "easC_print");
    easC_init = dlsym(*lib_handle, "easC_init");
    easC_update = dlsym(*lib_handle, "easC_update");

    if (!easC_print || !easC_init || !easC_update) {
        fprintf(stderr, "Error loading symbols: %s\n", dlerror());
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
