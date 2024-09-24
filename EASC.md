# easC - Easy C Framework with Hot-Reloading Support

## Overview

easC is a lightweight yet powerful framework designed to simplify C-based project initialization and development, specifically optimized for projects that require dynamic library support and hot-reloading capabilities. It streamlines project setup, manages configuration files, and dynamically reloads C libraries without requiring a restart—ideal for fast development cycles and iterative testing.

easC aims to become a comprehensive framework to facilitate modern C development, with features that go beyond hot-reloading, making it an essential tool for developers building modular, large-scale, or performance-sensitive systems.

## Vision & Goals

easC aims to:
- Provide a plug-and-play solution for C developers who want to build complex applications with minimal boilerplate.
- Give **YOU** all the power to make the most out of what C as a language is capable of.
- Reduce development time by providing dynamic, hot-reloadable libraries that allow runtime updates.
- Simplify project management, ensuring consistency in builds, formatting, and configurations.
- Grow into a framework that integrates essential features for the C ecosystem, including unit testing, cross-platform support, and CI/CD tools.

---

## Current Features

### 1. **Dynamic Library Hot-Reloading**
   - The core feature of easC is the ability to dynamically load shared object libraries (`.so`) and reload them at runtime without restarting the entire application. This is especially useful for live system updates, iterative testing, and rapid prototyping.
   - The dynamic library (Ex: `libeasc.so`) exposes functions that the main application (`main.c`) calls. The framework provides typedefs and function pointers to ensure smooth communication between the main program and the reloaded library.

### 2. **Project Initialization Automation**
   - easC simplifies project setup by auto-generating an entire directory structure for your C project. This includes:
     - **src/**: Source files (e.g., `main.c`).
     - **lib/**: Library files for hot-reloading (e.g., `libeasc.c`, `libeasc.h`).
     - **build/**: Compiled binaries.
     - **.config/easC/**: Configuration files (e.g., `config.json`).
     - Optional **.clang-format** file and **Makefile** for managing builds.

### 3. **Dynamic Recompilation via Bash Scripts**
   - The framework generates Bash scripts (`init.sh` and `recompile.sh`) that streamline the compilation process for both the main application and the dynamic library. This ensures seamless recompilation and reloading during runtime by simply pressing a key (`r`).

### 4. **Interactive CLI for Custom Project Setup**
   - easC offers a CLI-based initialization that prompts the user to specify key project parameters such as the project name, the output binary name, and the library name. It also offers options for generating additional tooling like `.clang-format` and a `Makefile`.
   - Input validation ensures that project names and other identifiers only contain valid characters (alphanumeric and underscores).

### 5. **Configuration Management**
   - The framework stores project configuration in a JSON file (`config.json`) that can be easily modified or referenced during future compilations. This makes project management more transparent and efficient.

---

## Project Structure & Flow

### Directory Structure

A typical easC project has the following layout:

```
<project_name>/
├── .config/easC/
│    └── config.json   # Stores project details (output binary name, library name)
├── src/
│   └── main.c         # Main entry point of the application
├── lib/
│   ├── libeasc.c      # Source code for the hot-reloadable library
│   ├── libeasc.h      # Header file for library declarations
│   └── recompile.sh   # Script for recompiling the library and binary
├── build/             # Directory for compiled binaries
├── init.sh            # Script for initial compilation and setup
├── Makefile           # Optional for bigger projects that use easC
├── .clang-format      # Optional files that streamline any easC based project
└── README.md          # General project information
```

### Flow of Execution

1. **Project Setup**: The user initializes a project using easC, specifying the project name, binary, and library names.
2. **Initial Compilation**: `init.sh` compiles both the main application and the dynamic library.
3. **Runtime**: The main application loads the shared library at runtime and calls its functions via `dlsym` and function pointers.
4. **Hot-Reloading**: While the program is running, the user can press `r` to trigger recompilation of the library via `recompile.sh` and dynamically reload it without stopping the main program.
5. **Extensibility**: The user can add new features to the library, and it can be reloaded in real-time, enabling fast iteration.

---

## Advantages of easC

### 1. **Faster Development with Hot-Reloading**
   - Change code, reload at runtime, and avoid the costly overhead of recompiling and restarting your entire program.
   - Ideal for developers who want to test iterative changes quickly without disrupting the application's state.

### 2. **Modular Project Setup**
   - The pre-defined project structure enforces a clean, modular setup from the start. Developers can easily locate source files, build binaries, and manage library code.
   - Easy management of configuration files, making the project scalable for future extensions.

### 3. **Customization**
   - easC allows developers to choose their own project names, binary names, and library names, making it flexible for a variety of use cases.
   - Optional features like `.clang-format` and `Makefile` generation make the framework adaptable for different project requirements.

### 4. **Ease of Use for Beginners and Pros**
   - The framework abstracts away complex boilerplate, making it accessible to new C developers. At the same time, experienced developers can leverage hot-reloading and script-based workflows for rapid iteration.

### 5. **Extensible & Open for Future Growth**
   - easC’s structure can easily accommodate new features, libraries, or third-party tools, making it future-proof for evolving project needs.

---

## Potential Future Additions

1. **Unit Testing Integration**
   - Automatically set up testing frameworks like **CUnit** or **Check**.
   - Provide scaffolding for unit tests that run against both the main application and the dynamically loaded libraries.

2. **Cross-Platform Support**
   - Add Windows and macOS support, ensuring that the framework can be used across multiple platforms with proper adjustments for shared libraries (`.dll` for Windows, `.dylib` for macOS).

3. **Automated CI/CD Pipelines**
   - Integrate GitHub Actions or other CI/CD tools for automated testing, building, and deploying projects initialized with easC.

4. **Advanced Build Tools**
   - Integrate with **CMake** or **Meson** to support more advanced project build systems.
   - Add dependency management tools for including third-party libraries.

5. **Performance Monitoring & Debugging Tools**
   - Include built-in profiling and debugging utilities to help developers track down performance bottlenecks or bugs within dynamically reloaded libraries.

6. **Template Systems**
   - Add predefined templates for different types of C projects (e.g., embedded systems, game development, network applications).

7. **Improved CLI & Config Management**
   - Make the CLI even more interactive, allowing for project extensions, dependency handling, and environment configuration.
   - Enhanced JSON config file schema with better support for custom fields.

---

## Customer Base

easC is designed to serve:
- **C Developers** who work on large or complex applications that require frequent updates or live patching.
- **System Programmers** who need to minimize downtime by leveraging hot-reloading techniques.
- **Game Developers** looking for rapid prototyping and iteration without restarting the engine.
- **Researchers & Academics** using C for scientific computing or algorithm development, allowing quick testing and modification of mathematical models.
- **Beginner C Programmers** who want an easy framework to get started, with less boilerplate and clear project structure.

---

## Conclusion

easC is a powerful and flexible framework aimed at making C development easier, faster, and more iterative. Its dynamic hot-reloading functionality, combined with its easy-to-use project structure and setup, provides developers with a streamlined workflow for building modern, modular C applications.

As easC grows, it aims to offer even more features such as cross-platform support, advanced build tools, unit testing, and performance profiling, making it an indispensable tool for C developers across industries.

Embrace the power of easC, and watch your development time shrink while your productivity grows.
