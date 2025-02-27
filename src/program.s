# program.s - Main program loop and command processing
# Author: Adam Rubinstein
# Date: 02/27/2025

.include "src/constants.s"

.section __TEXT,__text

# Function: _program_loop
# Main program loop that reads and processes input
# Register usage:
#   r14: Buffer address (volatile, not preserved)
#   r12: Base address of our stack (preserved)
#   r13: Stack size counter (preserved and may be modified)
# Invariants:
#   Allocates 1KB buffer for reading input
#   Processes each character immediately
.globl _program_loop
_program_loop:
    pushq   %rbp
    movq    %rsp, %rbp
    
    # Allocate buffer for input
    subq    $BUFFER_SIZE, %rsp  # 1KB buffer for input
    movq    %rsp, %r14          # Store buffer address in r14
    
_read_loop:
    # Read from stdin
    movl    $SYS_READ, %eax
    movl    $STDIN, %edi
    movq    %r14, %rsi          # Buffer address
    movl    $BUFFER_SIZE, %edx  # Buffer size
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
    addq    $BUFFER_SIZE, %rsp  # Clean up buffer
    popq    %rbp
    ret

# Function: _process_buffer
# Processes a buffer of characters, parsing numbers and commands
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
#   Handles commands immediately
.globl _process_buffer
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
    
    # If we're already parsing a number, this can't be a negative sign
    cmpq    $0, %rbx
    jne     _not_digit
    
    # Check if the next character is a digit (to determine if it's a negative sign)
    # Save current position
    movq    %rcx, %r8           # Use r8 to save position temporarily
    
    # Check if we've reached the end of the buffer
    cmpq    %r15, %r8
    jge     _minus_as_command
    
    # Get next character
    movb    (%r14, %r8), %r11b
    
    # Check if next character is a digit
    cmpb    $'0', %r11b
    jl      _minus_as_command
    cmpb    $'9', %r11b
    jg      _minus_as_command
    
    # Next character is a digit, so this is a negative sign
    movq    $1, %rbx            # Set flag that we're parsing a number
    movq    $1, %r10            # Set flag for negative number
    movq    $0, %rax            # Reset current number
    jmp     _process_loop
    
_minus_as_command:
    # It's a minus command, not a negative sign
    jmp     _not_digit          # Process as a command
    
_check_digit:
    # Check if it's a digit (0-9)
    cmpb    $'0', %dl
    jl      _not_digit
    cmpb    $'9', %dl
    jg      _not_digit
    
    # It's a digit, add to current number
    # If we're not already parsing a number, set the flag and set rax to 0
    cmpq    $0, %rbx
    jne     _already_parsing
    movq    $1, %rbx            # Set flag that we're parsing a number
    movq    $0, %rax            # Reset current number
_already_parsing:
    imulq   $10, %rax           # Multiply current value by 10
    subb    $'0', %dl           # Convert ASCII to number
    movzbq  %dl, %rdx           # Zero-extend to 64 bits
    addq    %rdx, %rax          # Add to current value
    jmp     _process_loop
    
_not_digit:
    # Check if we were parsing a number
    cmpq    $0, %rbx
    je      _check_command
    
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
    
_check_command:
    # Check if it's whitespace (space, tab, newline)
    cmpb    $' ', %dl
    je      _process_loop
    cmpb    $'\t', %dl
    je      _process_loop
    cmpb    $'\n', %dl
    je      _process_loop
    
    # Check for command 'p' - print stack
    cmpb    $'p', %dl
    jne     _check_add
    
    # Save current position before calling function
    pushq   %rcx
    call    _print_stack
    popq    %rcx
    
    movq    $0, %r10            # Reset negative flag
    
    jmp     _process_loop
    
_check_add:
    # Check for command '+' - add top two elements
    cmpb    $'+', %dl
    jne     _check_subtract
    
    # Save current position before calling function
    pushq   %rcx
    call    _add_operation
    popq    %rcx
    
    movq    $0, %r10            # Reset negative flag
    
    jmp     _process_loop

_check_subtract:
    # Check for command '-' - subtract top two elements
    cmpb    $'-', %dl
    jne     _check_multiply
    
    # Save current position before calling function
    pushq   %rcx
    call    _subtract_operation
    popq    %rcx
    
    movq    $0, %r10            # Reset negative flag
    
    jmp     _process_loop

_check_multiply:
    # Check for command '*' - multiply top two elements
    cmpb    $'*', %dl
    jne     _check_divide
    
    # Save current position before calling function
    pushq   %rcx
    call    _multiply_operation
    popq    %rcx

    movq    $0, %r10            # Reset negative flag
    
    jmp     _process_loop

_check_divide:
    # Check for command '/' - divide top two elements
    cmpb    $'/', %dl
    jne     _check_quit
    
    # Save current position before calling function
    pushq   %rcx
    call    _divide_operation
    popq    %rcx

    movq    $0, %r10            # Reset negative flag
    
    jmp     _process_loop

_check_quit:
    # Check for command 'q' - quit program
    cmpb    $'q', %dl
    jne     _process_loop
    
    # Exit program
    movl    $SYS_EXIT, %eax
    xorl    %edi, %edi          # Exit code 0
    syscall
    
    # We won't reach here, but for completeness
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