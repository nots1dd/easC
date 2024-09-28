#ifndef LIBTEST_H
#define LIBTEST_H

#include <stdio.h>
/**********************
 * INSERT HEADERS HERE
 **********************/

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

/**************************************
 *
 * @X_MACROS
 *
 * Used to generate list like structs of code
 *
 * $Source: Wikipedia
 *
 * They are most useful when at least some of the lists cannot be composed by indexing, such as compile time. 
 * They provide reliable maintenance of parallel lists whose corresponding 
 * items must be declared or executed in the same order.
 *
 **************************************/

#define EASC_FUNC_LIST   EASC(easC_init)   EASC(easC_print)   EASC(easC_update) 
#endif
