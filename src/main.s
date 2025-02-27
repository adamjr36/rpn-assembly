# main.s - Main program entry point
# Author: Adam Rubinstein
# Date: 02/27/2025

.include "src/constants.s"

.section __TEXT,__text
.globl _main

# Function: _main
# Entry point of the program
# Register usage:
#   r12: Base address of our stack (preserved across function calls)
#   r13: Stack size counter (preserved across function calls)
# Invariants:
#   r12 always points to the base of our stack
#   r13 always contains the current number of elements in the stack
_main:
    # Set up the stack frame
    pushq   %rbp
    movq    %rsp, %rbp
    
    # Initialize our stack pointer to the base of our stack
    leaq    stack(%rip), %r12
    movq    $0, %r13            # Stack size counter (number of elements)
    
    # Print welcome message
    leaq    welcome_msg(%rip), %rsi
    movq    $welcome_msg_len, %rdx
    call    _print_string
    
    # Call the main program loop
    call    _program_loop
    
    # Call print_stack function to show final state
    call    _print_stack
    
    # Exit program
    movl    $SYS_EXIT, %eax
    xorl    %edi, %edi          # Exit code 0
    syscall
    
    # We won't reach here, but for completeness
    popq    %rbp
    ret

.section __DATA,__data
welcome_msg:
    .asciz "Stack Calculator\n\nOperations:\n  p - print stack\n  q - quit\n  + - add top two elements\n  - - subtract top two elements\n  * - multiply top two elements\n  / - divide top two elements (second by top)\n\nEnter formula:\n"
welcome_msg_len = . - welcome_msg 