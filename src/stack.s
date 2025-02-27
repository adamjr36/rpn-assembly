# stack.s - Stack data structure and operations
# Author: Adam Rubinstein
# Date: 02/27/2025

.include "src/constants.s"

.section __TEXT,__text

# Function: _push
# Pushes a value onto the stack
# Parameters:
#   rax: Value to push
# Register usage:
#   r12: Base address of our stack (preserved)
#   r13: Stack size counter (preserved and may be modified)
#   rdx: Temporary for calculating offset (volatile)
# Invariants:
#   Checks if stack is full before pushing
#   Increments stack size counter after successful push
.globl _push
_push:
    # Check if stack is full
    cmpq    $STACK_SIZE, %r13
    jge     _stack_full
    
    # Calculate position to store value
    movq    %r13, %rdx
    imulq   $INT_SIZE, %rdx
    
    # Store value in stack
    movl    %eax, (%r12, %rdx)
    
    # Increment stack size
    incq    %r13
    
    ret
    
_stack_full:
    # Stack is full, just return
    ret

# Function: _print_stack
# Prints all elements in the stack from top to bottom
# Register usage:
#   r12: Base address of our stack (preserved)
#   r13: Stack size counter (preserved)
#   rcx: Current stack index (volatile)
#   rdx: Temporary for calculating offset (volatile)
# Invariants:
#   Prints stack header before elements
#   Prints elements from top (last) to bottom (first)
.globl _print_stack
_print_stack:
    pushq   %rbp
    movq    %rsp, %rbp
    
    # Check if stack is empty
    cmpq    $0, %r13
    je      _print_empty
    
    # Print stack header
    leaq    stack_header(%rip), %rsi
    movq    $stack_header_len, %rdx
    call    _print_string
    
    # Start from the top of the stack (last element)
    movq    %r13, %rcx
    decq    %rcx                # Adjust to 0-based index
    
# Section: _print_loop
# Loop that prints each stack element
# Register usage:
#   rcx: Current stack index (decremented each iteration)
#   rdx: Used to calculate element offset
#   r12: Base address of stack (preserved)
#   edi: Current stack value for printing
# Invariants:
#   Processes elements from top to bottom (highest index to lowest)
_print_loop:
    # Save rcx before any function calls
    pushq   %rcx
    
    # Calculate position of current element
    movq    %rcx, %rdx
    imulq   $INT_SIZE, %rdx
    
    # Get value from stack
    movl    (%r12, %rdx), %edi
    
    # Print the value
    call    _print_int
    
    # Print newline
    leaq    newline(%rip), %rsi
    movq    $1, %rdx
    call    _print_string
    
    # Restore rcx and decrement
    popq    %rcx
    decq    %rcx
    
    # Check if we've printed all elements
    cmpq    $0, %rcx
    jl      _print_done
    
    jmp     _print_loop
    
_print_empty:
    # Print empty stack message
    leaq    empty_stack(%rip), %rsi
    movq    $empty_stack_len, %rdx
    call    _print_string
    
_print_done:
    popq    %rbp
    ret

.section __DATA,__data
# Stack data structure
.align 4
.globl stack
stack:
    .space STACK_SIZE * INT_SIZE, 0   # 1000 integers (4 bytes each)

# Messages
stack_header:
    .asciz "Stack contents (top to bottom):\n"
stack_header_len = . - stack_header

empty_stack:
    .asciz "Stack is empty\n"
empty_stack_len = . - empty_stack

newline:
    .asciz "\n" 