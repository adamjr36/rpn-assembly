# io.s - Input/output operations
# Author: Adam Rubinstein
# Date: 02/27/2025

.include "src/constants.s"

.section __TEXT,__text

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
.globl _print_string
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
.globl _print_int
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