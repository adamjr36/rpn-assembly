# Stack Calculator

A simple commandline RPN calculator implemented in x86-64 assembly language.

## Build and Run

```sh
sh build.sh
```

```sh
./build/calculator
```

## Usage

1. Enter numbers to push them onto the stack
2. Use operation commands to perform calculations
3. Use 'p' to print the current stack contents
4. Use 'q' to quit the program

## Commands

- `p` - Print the current stack contents (from top to bottom)
- `q` - Quit the program
- `+` - Add the top two elements on the stack
- `-` - Subtract the top element from the second element
- `*` - Multiply the top two elements on the stack
- `/` - Divide the second element by the top element (checks for division by zero)

## Input Handling

- Any non-digit character is either a command above or treated as whitespace (except '-' for negative numbers)
- This means "2.5" is treated the same as "2 5" (pushes 2 and 5 separately)
- Negative numbers are supported with the '-' prefix
