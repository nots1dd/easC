# testlib

## Project Structure
Your easC project is ready with the following structure:

```
testlib/
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
└── README.md
```

## Instructions
1. Navigate to your project folder: `cd testlib`
2. Run `./init.sh` to initially compile the library and binary.
3. Run `cd build/; export LD_LIBRARY_PATH=.:$LD_LIBRARY_PATH`
4. Run your program: `./test`
5. While the binary  is still running, press 'r' in the running program to reload the library and apply changes.

Hope you had an easC time!
