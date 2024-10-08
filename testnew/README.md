# testnew

## Overview
This is a basic C framework built with dynamic library support using `dlopen`, `dlsym`, and `dlclose`. 
It supports hot-reloading, allowing library code to be updated without restarting the program.

## File structure 


```bash
testnew/
├── .config/easC/
│    └── config.json
├── src/
│   └── main.c
├── lib/
│   ├── libtestnew.c
│   ├── libtestnew.h
│   └── recompile.sh
├── build/
├── init.sh
├── staticompile.sh
├── Makefile      [OPTIONAL]
├── .clang-format [OPTIONAL]
└── README.md
```

## Features
- Dynamic function loading and reloading.
- Easy recompile script for library changes.
- Optional .clang-format for code styling.
- Makefile for streamlined builds.

## Usage
To compile the project [DYNAMIC BUILD]:
```bash
./init.sh
```

To compile the project [STATIC BUILD]:
```bash 
./staticompile.sh 
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

