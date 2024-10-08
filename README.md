# easC Framework

## Overview

**easC** (Easy to configure C framework with dynamic library support) is designed to simplify the process of developing C applications that utilize hot-reloadable dynamic libraries. With easC, you can create modular applications that allow changes to libraries to be reflected in the running program without needing to restart it. This is particularly useful in development environments where rapid iteration is essential.

## Usage

Simply clone this repo and run the build script 

```sh 
git clone https://github.com/nots1dd/easc.git 
cd easC/
./build.sh
```

> [!NOTE]
> 
> For a more detailed look at how 
> the framework looks like, 
> 
> Check out [testlib](https;//github.com/nots1dd/easc/blob/main/testlib/README,md)
> 

## Key Concepts

For an in-depth on the **WHAT**, **HOW**, **WHY** regarding *easC*, check out [easC](https://github.com/nots1dd/easc/blob/main/EASC.md)

### Hot Reloading

Hot reloading is a technique that allows a program to load or reload parts of its code at runtime. This is accomplished through dynamic linking and loading of shared libraries (commonly `.so` files on Unix-like systems). Instead of stopping the application and recompiling the entire codebase, hot reloading enables developers to make changes in real-time, which can significantly enhance productivity and streamline the debugging process.

**How Hot Reloading Works in easC:**
1. **Dynamic Library Loading**: The main application uses functions like `dlopen()` to load a shared library and `dlsym()` to retrieve function pointers to the symbols (functions) defined in that library.
2. **Recompilation**: When changes are made to the library code, a simple script (`recompile.sh`) can be executed to recompile the library and the main application.
3. **Reloading Functions**: After recompiling, the main application can reload the library using the `reload_func()` function, allowing it to use the new code without restarting.

### easC Framework Structure

The easC framework consists of several components that make it easy to set up a project, compile code, and implement hot reloading. The main components include:

- **Project Initialization**: The Bash script prompts the user for project details and sets up a structured project directory.
- **Configuration Management**: Configuration details are stored in a JSON file, making it easy to access and modify project settings.
- **Dynamic Library Support**: The framework allows developers to create and use shared libraries, defining function pointers to dynamically load and call library functions.
- **Build Automation**: The framework includes a recompile script to automate the compilation of both the library and the main application.

## Detailed Breakdown of the Script

### Input Validation

The `validate_input()` function ensures that project names and output binary names consist only of alphanumeric characters and underscores. This prevents errors during project creation.

### User Prompts

The script prompts users to enter:
- **Project Name**: The name of the new project.
- **Output Binary Name**: The name of the compiled executable (defaulting to `main`).
- **Library Name**: The name of the hot-reloadable library (defaulting to `libeasc`).

### Directory Structure Setup

Once the user inputs are validated, the script creates a well-defined directory structure for the project:
```
$project_name/
├── .config/easC/
│   └── config.json
├── src/
│   └── main.c
├── lib/
│   ├── $library_name.c
│   ├── $library_name.h
│   ├── $library_name.so
│   └── recompile.sh
├── build/
│   ├── $output_binary
│   └── $output_binary-static
├── init.sh
├── staticompile.sh
├── .clang-format   [OPTIONAL]
├── Makefile        [OPTIONAL]
└── README.md
```

### Configuration File

A configuration file (`config.json`) is created to store project settings such as the project name, output binary name, and library name. This JSON format makes it easy to read and modify the configuration later.

### Source Code Generation

The script automatically generates the following files:
- **Header File (`lib/$library_name.h`)**: Contains function pointer typedefs for the dynamic library functions.
- **Source File (`lib/$library_name.c`)**: Implements the functions that will be dynamically loaded.
- **Main Program (`src/main.c`)**: Contains the main application logic, which loads the dynamic library, retrieves function pointers, and allows for interaction via user input.
- **Compilation Scripts**: 
  - `init.sh`: Initial compilation script for the library and main program.
  - `recompile.sh`: Script to recompile the library and main program, called from within the main application.

### Instructions for Use

The README provides detailed instructions for the user to:
1. Navigate to the project folder.
2. Run the `init.sh` script to compile the initial version of the library and the main program.
3. Set the `LD_LIBRARY_PATH` to include the build directory for dynamic linking.
4. Run the compiled binary.
5. Use the interactive prompt to reload the library and apply changes without restarting the program.

Below code snipper would be the ideal streamlined flow of using easC for your project: 

```sh
# To build a project DYNAMICALLY (MACRO: EASC_DYNC) 
cd $project_name/
./init.sh                                 # To initialize easC (output_binary: $output_binary)

cd build/ 
export LD_LIBRARY_PATH=.:$LD_LIBRARY_PATH # Adding our shared object library to LD_LIBRARY_PATH for GNU linker to link to binary
./$output_binary

# To hot reload 
# <MAKE CHANGES TO $library_name.c>

# In the currently running $output_binary: 
# Type 'r' while in the event loop!

############ STATIC BUILD #############

# To build a project STATICALLY
cd $project_name/
./staticompile.sh                         # To initialize easC (output_binary: $output_binary-static)

cd build/
./$output_binary-static
```

> [!IMPORTANT]
> 
> In order for hot reloading to work,
> 
> Ensure that all libraries used in the project 
> have a **shared object (.so)** file and ARE NOT 
> *STATICALLY LINKED* to main.c 
> 
> Failing to adhering to the above will cause the framework to not behave as expected.

## Future 

Not to sure where to do with this to be honest, I just wanted to build a framework that I feel like would be very useful for me, as a person who builds and maintains TUI based projects written in NCurses

Expected changes for the immediate future will be out soon.

## Conclusion

The easC framework is meant to be for C developers who specialize in TUI/Game development, or any application building process that requires constant **building** and **reconfiguring** just to check for UI/UX changes that becomes cumbersome over time. 

This framework only supports POSIX based systems (we only use `dlfcn.h` for this)
