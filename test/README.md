# test

## Overview
This is a basic C framework built with dynamic library support using `dlopen`, `dlsym`, and `dlclose`. 
It supports hot-reloading, allowing library code to be updated without restarting the program.

## File structure 

\test/
├── .config/easC/
│    └── config.json
├── src/
│   └── main.c
├── lib/
│   ├── libtest.c
│   ├── libtest.h
│   └── recompile.sh
├── build/
├── init.sh
├── Makefile     [OPTIONAL]
├──.clang-format [OPTIONAL]
└── README.md
\
## Features
- Dynamic function loading and reloading.
- Easy recompile script for library changes.
- Optional .clang-format for code styling.
- Makefile for streamlined builds.

## Usage
To compile the project:
```bash
./init.sh
```

To run the project:
```bash
cd build && ./$output_binary
```

To reload the library at runtime, press 'r'. Press 'q' to quit.

## Requirements
- gcc
- make (optional)
- clang-format (optional)

