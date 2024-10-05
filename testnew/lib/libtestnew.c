#include "libtestnew.h"

/****************************************
 * libtestnew.c
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
    int n = 10;
    int m = 0;
    int x = n/2;
    printf("\n%d\n",x);
    // int *ptr = NULL;
    // *ptr = 10;
}
