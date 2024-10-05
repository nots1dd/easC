#include <stdio.h>
#include <dlfcn.h>
#include <stdbool.h>
#include <stdlib.h>
#include <signal.h>
#include <string.h>
#include <setjmp.h>
#include <execinfo.h>
#include <limits.h>
#include <unistd.h>
#include "../lib/libtestnew.h"

/****************************************
 * main.c
 *
 * This is the main program. It dynamically loads the library (libtestnew.so)
 * at runtime using , retrieves the function symbols using ,
 * and can reload the library during runtime, enabling "hot reloading".
 *
 * Key functions:
 * - reload_func: Loads/reloads the dynamic library and retrieves function symbols.
 * - main: Runs an event loop that listens for user input to either reload
 *   the library or execute the functions dynamically loaded from the library.
 ****************************************/

 extern char **environ;

/* ANSI COLOR ESCAPE VALUES */
#define COLOR_RESET      "\033[0m"
#define COLOR_RED        "\033[31m"
#define COLOR_YELLOW     "\033[33m"
#define COLOR_CYAN       "\033[36m"
#define COLOR_BOLD       "\033[1m"
#define COLOR_GREEN      "\033[32m"

#define BOX_WIDTH 50

// Utility function to print a box
void print_box(const char *message, const char* color) {
    int len = strlen(message);
    int padding = (BOX_WIDTH - len) / 2;

    // Print top border
    printf("%s+", COLOR_GREEN);
    for (int i = 0; i < BOX_WIDTH; i++) printf("-");
    printf("+%s\n", COLOR_RESET);

    // Print message with padding
    printf("%s|%s", COLOR_GREEN, COLOR_RESET);
    for (int i = 0; i < padding; i++) printf(" ");
    printf("%s%s%s", message, color, COLOR_RESET);
    for (int i = 0; i < BOX_WIDTH - len - padding; i++) printf(" ");
    printf("%s|\n", COLOR_GREEN);

    // Print bottom border
    printf("%s+", COLOR_GREEN);
    for (int i = 0; i < BOX_WIDTH; i++) printf("-");
    printf("+%s\n", COLOR_RESET);
}

#define LIBEASC "../lib/libtestnew.so"
#define RELOAD_SCRIPT "../lib/recompile.sh"  // Script to recompile the library and program

#define HELPER_STRING "Welcome to easC!:\nKEYBINDS:\n\n1. 'r' -- Hot Reload Project\n2. 'c' -- Clear Screen\n3. 'q' -- Quit easC workflow\n\n> "

/* RUNTIME ERROR MESSAGES */ 
#define SEG_FAULT_MESSAGE  "[easC_SEGV] easC has detected segfault in easC_update! Recovering....\n"
#define ABRT_FAULT_MESSAGE "[easC_ABRT] easC has detected abort signal due to unknown reasons!! Recovering....\n"
#define FPE_FAULT_MESSAGE  "[easC_FPE] easC has detected a floating point exception!! Recovering...\n"

/****************************************
 * Global Variables:
 * - lib_name: The name of the shared library file.
 * - libplug: Handle for the dynamically loaded library.
 * - Function pointers: All called and defined using X MACROS.
 ****************************************/
const char *lib_name = LIBEASC;
void *libplug = NULL;

jmp_buf recovery_point;

/* Signal handler function for segfault and other errors */
void easC_SIG_HANDLER(int sig, siginfo_t *si, void *unused) {
    // Print signal-specific message with color
    if (sig == SIGSEGV) {
        printf("\n%s%s%s\n", COLOR_RED, COLOR_BOLD, SEG_FAULT_MESSAGE);
        printf("%sSegmentation fault occurred! Details:%s\n", COLOR_RED, COLOR_RESET);
        printf("%s- Faulting address: %p\n", COLOR_YELLOW, si->si_addr);
        printf("- Attempted to read or write to an invalid memory address.\n"
               "- Dereferencing a NULL or uninitialized pointer.\n"
               "- Buffer overflow or accessing array out of bounds.\n"
               "- Possible location: ");
        
        // Use addr2line to get file and line information (if available)
        if (si->si_addr) {
            printf("- Possible location: ");
            // Use addr2line to get file and line information (if available)
            char cmd[256];
            snprintf(cmd, sizeof(cmd), "addr2line -e /proc/%d/exe %p", getpid(), si->si_addr);
            FILE *fp = popen(cmd, "r");
            if (fp) {
                char output[256];
                if (fgets(output, sizeof(output), fp) != NULL) {
                    printf("%s", output);
                } else {
                    printf("Unable to determine location\n");
                }
                pclose(fp);
            } else {
                printf("Unable to run addr2line\n");
            }
        } else {
            printf("- Unable to determine location (NULL address)\n");
        }
        printf("%s\n", COLOR_RESET);
    } else if (sig == SIGABRT) {
        printf("\n%s%s%s\n", COLOR_RED, COLOR_BOLD, ABRT_FAULT_MESSAGE);
        printf("%sAbort signal received! This could be due to:%s\n", COLOR_YELLOW, COLOR_RESET);
        printf("%s- An assertion failure or explicit call to abort().\n"
               "- Memory corruption detected by the C library.\n"
               "- Unhandled exception in C++ code.%s\n", COLOR_YELLOW, COLOR_RESET);
    } else if (sig == SIGFPE) {
        printf("\n%s%s%s\n", COLOR_RED, COLOR_BOLD, FPE_FAULT_MESSAGE);
        printf("%sFloating-point exception occurred! Details:%s\n", COLOR_YELLOW, COLOR_RESET);
        printf("%s- Type: ", COLOR_YELLOW);
        switch (si->si_code) {
            case FPE_INTDIV: printf("Integer divide by zero\n"); break;
            case FPE_INTOVF: printf("Integer overflow\n"); break;
            case FPE_FLTDIV: printf("Floating-point divide by zero\n"); break;
            case FPE_FLTOVF: printf("Floating-point overflow\n"); break;
            case FPE_FLTUND: printf("Floating-point underflow\n"); break;
            case FPE_FLTRES: printf("Floating-point inexact result\n"); break;
            case FPE_FLTINV: printf("Invalid floating-point operation\n"); break;
            case FPE_FLTSUB: printf("Subscript out of range\n"); break;
            default: printf("Unknown floating-point exception\n");
        }
        printf("%s\n", COLOR_RESET);
    } else {
        printf("%sUnknown signal received: %d. Recovering...\n", COLOR_YELLOW, sig);
    }

    // Print additional process information
    printf("%sProcess Information:%s\n", COLOR_YELLOW, COLOR_RESET);
    
    // Get program name (portable way)
    char program_name[PATH_MAX];
    ssize_t len = readlink("/proc/self/exe", program_name, sizeof(program_name) - 1);
    if (len != -1) {
        program_name[len] = '\0';
        printf("  Program Name: %s\n", program_name);
    } else {
        printf("  Program Name: Unknown\n");
    }
    
    printf("  Process ID: %d\n", getpid());
    printf("  Parent Process ID: %d\n", getppid());
    printf("  Signal: %d\n", sig);
    printf("  Signal origin: %s\n", (si->si_pid == 0) ? "Kernel" : "User process");
    if (si->si_pid != 0) {
        printf("  Sending process ID: %d\n", si->si_pid);
    }

    // Print current working directory
    char cwd[PATH_MAX];
    if (getcwd(cwd, sizeof(cwd)) != NULL) {
        printf("  Current working directory: %s\n", cwd);
    }

    // Print environment variables
    printf("  Relevant environment variables:\n");
    char **env = environ;
    while (*env) {
        if (strncmp(*env, "PATH=", 5) == 0 || strncmp(*env, "LD_LIBRARY_PATH=", 16) == 0) {
            printf("    %s\n", *env);
        }
        env++;
    }

    // Print a stack trace in a box
    void *array[20];
    size_t size;
    char **strings;
    size = backtrace(array, 20);
    strings = backtrace_symbols(array, size);

    print_box("Stack Trace:", COLOR_CYAN);
    for (size_t i = 0; i < size; i++) {
        printf("%s\n", strings[i]);
    }
    free(strings);

    // Jump to the recovery point set earlier
    longjmp(recovery_point, sig);
}

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

void safe_call(easC_update_t func, const char* func_name) {
    if (func != NULL) {
        int sig = setjmp(recovery_point);
        if (sig == 0) {
            func();
        } else {
            printf("%s%s[ERROR] %s caused an error (signal %d). Rebinding event loop...\n%s",
                   COLOR_RED, COLOR_BOLD, func_name, sig, COLOR_RESET);
        }
    } else {
        printf("%s%s[WARNING] %s is NULL. Skipping...\n%s",
               COLOR_YELLOW, COLOR_BOLD, func_name, COLOR_RESET);
    }
}

void easC_Event_Loop() {
    char s = 0;
    void* state = NULL;

    while (easC_event_loop_condn_true != NULL && easC_event_loop_condn_true(s)) { 

        printf("%s", HELPER_STRING);
        scanf(" %c", &s);

        if (s == 'r') {
            if (easC_pre_reload != NULL) {
                state = easC_pre_reload();
            }
            if (!reload_func()) {
                printf("%s%s[WARNING] Failed to reload library. Continuing with previous version.\n%s",
                       COLOR_YELLOW, COLOR_BOLD, COLOR_RESET);
            } else {
                if (easC_post_reload != NULL) {
                    int sig = setjmp(recovery_point);
                    if (sig == 0) {
                        easC_post_reload(state);
                    } else {
                        printf("%s%s[ERROR] easC_post_reload caused an error (signal %d). Rebinding event loop...\n%s",
                               COLOR_RED, COLOR_BOLD, sig, COLOR_RESET);
                    }
                }
            }
        } else if (s == 'q') {
            printf("\n%sExiting easC with code 0%s\n", COLOR_GREEN, COLOR_RESET);
            return;
        } else if (s == 'c') {
            system("clear");
        }
       
        if (easC_update != NULL && s == 'r') {      
          printf("----------------------------- EASC_UPDATE ----------------------------------\n\n");
          safe_call(easC_update, "easC_update");
          printf("\n---------------------------- EASC_UPDATE ----------------------------------\n");
        }
  }
}

/****************************************
 * main:
 * The main function runs an event loop that waits for user input.
 * If the user presses 'r', the reload script (reload.sh) is executed
 * to recompile the library, and the library is reloaded to apply changes.
 * Press 'q' to quit the program.
 ****************************************/
int main() {
    
    struct sigaction sa;
    sa.sa_sigaction = easC_SIG_HANDLER;
    sa.sa_flags = SA_SIGINFO;
    sigemptyset(&sa.sa_mask);
    sigaction(SIGSEGV, &sa, NULL);
    sigaction(SIGABRT, &sa, NULL);
    sigaction(SIGFPE, &sa, NULL);
    
    /* Load the library and retrieve the function symbols initially */
    if (!reload_func()) {
        printf("%s%sError: Failed to load initial library. You can retry with 'r'.\nExiting with code 5.\n%s", COLOR_RED, COLOR_BOLD, COLOR_RESET);
        return 5;
    }

    /* Initialize the library (call test_init) */
    easC_init();

    /* Event loop: Continue until 'q' is pressed */
    easC_Event_Loop();

    /* Close the library before exiting */
    #ifdef EASC_DYNC
    dlclose(libplug);
    #else 
    printf("Exiting statically...\n");
    #endif
    return 0;
}
