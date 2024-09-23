#ifndef libtest
#define libtest

#include <stdio.h>

/****************************************
 * libtest.h
 *
 * This header file contains function declarations and typedefs
 * for function pointers used in the dynamic library. These functions
 * are declared here and defined in the dynamic library (libtest.c).
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
