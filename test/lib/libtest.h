#ifndef LIBTEST_H
#define LIBTEST_H

#include <stdio.h>

/****************************************
 * libtest.h
 * 
 * This header contains function declarations for 
 * dynamic library functions used by the main program.
 ****************************************/

/* Typedef for dynamic function pointers */
typedef void (*easC_print_t)(void);
typedef void (*easC_init_t)(void);
typedef void (*easC_update_t)(void);

#endif // LIBTEST_H
