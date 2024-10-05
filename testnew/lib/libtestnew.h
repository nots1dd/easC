#ifndef LIBTESTNEW_H
#define LIBTESTNEW_H

#include <stdio.h>
#include <stdbool.h>
/**********************
 * INSERT HEADERS HERE
 **********************/

/****************************************
 * libtestnew.h
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
  * $PRE RELOAD: 
  * Before reloading we return the previous state 
  * of the struct to a void pointer.
  * 
  * $POST RELOAD:
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
 * $Source: Wikipedia
 *
 * They are most useful when at least some of the lists cannot be composed by indexing, such as compile time. 
 * They provide reliable maintenance of parallel lists whose corresponding 
 * items must be declared or executed in the same order.
 *
 **************************************/

#define EASC_FUNC_LIST   EASC(easC_init)   EASC(easC_print)   EASC(easC_pre_reload)   EASC(easC_post_reload)   EASC(easC_event_loop_condn_true)   EASC(easC_update) 
#endif
