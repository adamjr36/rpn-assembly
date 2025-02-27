.section __TEXT,__text
.globl _main

# Constants
.equ STACK_SIZE, 1000
.equ INT_SIZE, 4
.equ STDIN, 0
.equ STDOUT, 1
.equ SYS_READ, 0x2000003
.equ SYS_WRITE, 0x2000004
.equ SYS_EXIT, 0x2000001

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
    
    # Call read_input function
    call    _read_input
    
    # Call print_stack function
    call    _print_stack
    
    # Exit program
    movl    $SYS_EXIT, %eax
    xorl    %edi, %edi          # Exit code 0
    syscall
    
    # We won't reach here, but for completeness
    popq    %rbp
    ret

# Function: _read_input
# Reads input from stdin until EOF and processes it
# Register usage:
#   r14: Buffer address (volatile, not preserved)
#   r12: Base address of our stack (preserved)
#   r13: Stack size counter (preserved and may be modified)
# Invariants:
#   Allocates 1KB buffer on the stack for reading input
#   Calls _process_buffer to handle the input data
_read_input:
    pushq   %rbp
    movq    %rsp, %rbp
    
    # Allocate buffer for input
    subq    $1024, %rsp         # 1KB buffer for input
    movq    %rsp, %r14          # Store buffer address in r14
    
_read_loop:
    # Read from stdin
    movl    $SYS_READ, %eax
    movl    $STDIN, %edi
    movq    %r14, %rsi          # Buffer address
    movl    $1024, %edx         # Buffer size
    syscall
    
    # Check for EOF (return value <= 0)
    cmpq    $0, %rax
    jle     _read_done
    
    # Process the input buffer
    movq    %r14, %rdi          # Buffer address
    movq    %rax, %rsi          # Bytes read
    call    _process_buffer
    
    jmp     _read_loop
    
_read_done:
    addq    $1024, %rsp         # Clean up buffer
    popq    %rbp
    ret

# Function: _process_buffer
# Processes a buffer of characters, parsing numbers and pushing them to the stack
# Parameters:
#   rdi: Buffer address
#   rsi: Buffer length
# Register usage:
#   r12: Base address of our stack (preserved)
#   r13: Stack size counter (preserved and may be modified)
#   r14: Buffer address (preserved within this function)
#   r15: Buffer length (preserved within this function)
#   rcx: Current position in buffer (volatile)
#   rax: Current number being parsed (volatile)
#   rbx: Flag indicating if we're parsing a number (volatile)
#   rdx: Current character/temporary value (volatile)
#   r10: Flag for negative number (volatile)
# Invariants:
#   Processes each character in the buffer
#   Parses consecutive digits as a single number
#   Calls _push when a complete number is found
_process_buffer:
    pushq   %rbp
    movq    %rsp, %rbp
    
    # Save registers we'll be using (except r13 which holds our stack size)
    pushq   %r12
    # Don't save r13 as it's our stack counter
    pushq   %r14
    pushq   %r15
    
    movq    %rdi, %r14          # Buffer address
    movq    %rsi, %r15          # Buffer length
    movq    $0, %rcx            # Current position in buffer
    movq    $0, %rax            # Current number being parsed
    movq    $0, %rbx            # Flag to indicate if we're parsing a number
    movq    $0, %r10            # Flag for negative number
    
_process_loop:
    # Check if we've reached the end of the buffer
    cmpq    %r15, %rcx
    jge     _process_done
    
    # Get current character
    movb    (%r14, %rcx), %dl
    incq    %rcx
    
    # Check if it's a minus sign
    cmpb    $'-', %dl
    jne     _check_digit
    
    # Only treat minus as negative if we're not already parsing a number
    cmpq    $0, %rbx
    jne     _not_digit
    
    # It's a minus sign at the start of a number
    movq    $1, %rbx            # Set flag that we're parsing a number
    movq    $1, %r10            # Set flag for negative number
    jmp     _process_loop
    
_check_digit:
    # Check if it's a digit (0-9)
    cmpb    $'0', %dl
    jl      _not_digit
    cmpb    $'9', %dl
    jg      _not_digit
    
    # It's a digit, add to current number
    movq    $1, %rbx            # Set flag that we're parsing a number
    imulq   $10, %rax           # Multiply current value by 10
    subb    $'0', %dl           # Convert ASCII to number
    movzbq  %dl, %rdx           # Zero-extend to 64 bits
    addq    %rdx, %rax          # Add to current value
    jmp     _process_loop
    
_not_digit:
    # Check if we were parsing a number
    cmpq    $0, %rbx
    je      _check_next
    
    # Apply negative sign if needed
    cmpq    $1, %r10
    jne     _push_number
    negq    %rax                # Negate the number
    
_push_number:
    # We have a number, push it to our stack
    call    _push
    movq    $0, %rax            # Reset current number
    movq    $0, %rbx            # Reset flag
    movq    $0, %r10            # Reset negative flag
    
_check_next:
    # Check if it's whitespace (space, tab, newline)
    cmpb    $' ', %dl
    je      _process_loop
    cmpb    $'\t', %dl
    je      _process_loop
    cmpb    $'\n', %dl
    je      _process_loop
    
    jmp     _process_loop
    
_process_done:
    # Check if we have a final number to push
    cmpq    $0, %rbx
    je      _process_exit
    
    # Apply negative sign if needed for the final number
    cmpq    $1, %r10
    jne     _push_final
    negq    %rax                # Negate the number
    
_push_final:
    # Push the final number
    call    _push
    
_process_exit:
    # Restore registers (except r13)
    popq    %r15
    popq    %r14
    popq    %r12
    
    popq    %rbp
    ret

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

# Function: _print_string
# Prints a string to stdout
# Parameters:
#   rsi: String address
#   rdx: String length
# Register usage:
#   rax: System call number (volatile)
#   rdi: File descriptor (volatile)
# Invariants:
#   Preserves all callee-saved registers
_print_string:
    pushq   %rbp
    movq    %rsp, %rbp
    
    movl    $SYS_WRITE, %eax
    movl    $STDOUT, %edi
    syscall
    
    popq    %rbp
    ret

# Function: _print_int
# Prints an integer to stdout
# Parameters:
#   edi: Integer to print
# Register usage:
#   rax: Working copy of the integer/quotient in division (volatile)
#   rsi: Buffer address (volatile)
#   rdx: Remainder in division/buffer length (volatile)
#   r8: Start of buffer pointer (volatile)
#   r9: End of buffer pointer (volatile)
#   rcx: Divisor (10) (volatile)
#   dl, cl: Temporary storage for character swapping (volatile)
# Invariants:
#   Handles negative numbers
#   Special case for zero
#   Converts number to string and reverses it for correct display
_print_int:
    pushq   %rbp
    movq    %rsp, %rbp
    
    # Allocate buffer for string representation (20 bytes is enough for 64-bit int)
    subq    $32, %rsp
    movq    %rsp, %rsi          # Buffer address
    
    # Check if number is negative
    movl    %edi, %eax
    cmpl    $0, %eax
    jge     _convert_positive
    
    # Handle negative number
    negl    %eax                # Make positive
    movb    $'-', (%rsi)        # Add minus sign
    incq    %rsi                # Move buffer pointer
    
_convert_positive:
    # Convert number to string (backwards)
    movq    %rsi, %r8           # Save start of buffer
    
    # Special case for 0
    cmpl    $0, %eax
    jne     _convert_loop
    
    movb    $'0', (%rsi)
    incq    %rsi
    jmp     _convert_done
    
_convert_loop:
    # Check if we're done
    cmpl    $0, %eax
    je      _convert_done
    
    # Get next digit
    movl    $0, %edx            # Clear high bits for division
    movl    $10, %ecx
    divl    %ecx                # Divide by 10, remainder in edx
    
    # Convert to ASCII and store
    addb    $'0', %dl
    movb    %dl, (%rsi)
    incq    %rsi
    
    jmp     _convert_loop
    
_convert_done:
    # Now reverse the string
    movq    %rsi, %r9           # End of buffer
    decq    %r9                 # Adjust to last character
    
    # Check if we need to reverse (length > 1)
    cmpq    %r8, %r9
    jle     _print_number
    
_reverse_loop:
    # Swap characters
    movb    (%r8), %dl
    movb    (%r9), %cl
    movb    %cl, (%r8)
    movb    %dl, (%r9)
    
    # Move pointers
    incq    %r8
    decq    %r9
    
    # Check if we're done
    cmpq    %r8, %r9
    jle     _print_number
    
    jmp     _reverse_loop
    
_print_number:
    # Calculate string length correctly
    movq    %rsp, %r8           # Start of buffer
    movq    %rsi, %rdx          # End of string (after last character)
    subq    %r8, %rdx           # Calculate length
    
    # Print the number
    movq    %r8, %rsi           # String address
    
    call    _print_string
    
    # Clean up
    addq    $32, %rsp
    
    popq    %rbp
    ret

.section __DATA,__data
# Stack data structure
.align 4
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