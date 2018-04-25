# Various helper functions for printing things
.data
digit_lookup: .ascii "0123456789abcdef"
hex_start_str: .asciiz "0x"

# Stores the address for the next node to allocate
new_str_address: .word str_memory
# Don't put anything below this just in case they malloc more than 4096
str_memory: .space 4096

# Syscall constants
PRINT_INT = 1
PRINT_STRING = 4
PRINT_CHAR = 11

.text
# print int and space ##################################################
#
# argument $a0: number to print
# returns       nothing

.globl print_int_and_space
print_int_and_space:
	li	$v0, PRINT_INT	# load the syscall option for printing ints
	syscall			# print the number

	li   	$a0, ' '       	# print a black space
	li	$v0, PRINT_CHAR	# load the syscall option for printing chars
	syscall			# print the char
	
	jr	$ra		# return to the calling procedure

# print int in hexadecimal and space ###################################
#
# argument $a0: number to print
# returns       nothing

DIGIT_MASK = 0xf0000000

# Allocates "memory" for new chars using the space in str_memory.
# Arguments: $a0: bytes of memory to be malloc'ed
# Returns: address to new chars
.globl malloc
malloc:
    lw  $v0, new_str_address
    add $t0, $v0, $a0
    sw  $t0, new_str_address
    jr  $ra

.globl print_int_hex_and_space
print_int_hex_and_space:
	move	$t0, $a0		# $t0 = number

	la	$a0, hex_start_str	# Always print out "0x"
	li	$v0, PRINT_STRING
	syscall

	bnez	$t0, pihas_not_zero	# if (number == 0x0)
	li	$a0, '0'		# print "0"
	li	$v0, PRINT_CHAR
	syscall
	j	pihas_print_space

pihas_not_zero:
	li	$t1, 8			# $t1 = digits_remain = 8

pihas_lead_zero_loop:
	and	$t2, $t0, DIGIT_MASK	# mask out everything except first digit
	bnez	$t2, pihas_print_loop	# while (!(number & digit_mask))
	sll	$t0, $t0, 4		# number <<= 4
	sub	$t1, $t1, 1		# --digits_remain
	j	pihas_lead_zero_loop

pihas_print_loop:
	blez	$t1, pihas_print_space	# while (digits_remain > 0)

	srl	$a0, $t0, 28		# print digit_lookup[number >> 28]
	lb	$a0, digit_lookup($a0)
	li	$v0, PRINT_CHAR
	syscall

	sub	$t1, $t1, 1		# --digits_remain
	sll	$t0, $t0, 4		# number <<= 4
	j	pihas_print_loop

pihas_print_space:
	li   	$a0, ' '
	li	$v0, PRINT_CHAR
	syscall

	jr	$ra

# print char and space #################################################
#
# argument $a0: character to print
# returns       nothing

.globl print_char_and_space
print_char_and_space:
	li	$v0, PRINT_CHAR	# load the syscall option for printing chars
	syscall			# print the number

	li   	$a0, ' '       	# print a black space
	li	$v0, PRINT_CHAR	# load the syscall option for printing chars
	syscall			# print the char
	
	jr	$ra		# return to the calling procedure

# print string #########################################################
#
# argument $a0: string to print
# returns       nothing

.globl print_string
print_string:
	li	$v0, PRINT_STRING	# print string command
	syscall	     			# string is in $a0
	jr	$ra

# print newline ########################################################
#
# no arguments
# returns       nothing

.globl print_newline
print_newline:
	li   	$a0, '\n'      	# print a newline
	li	$v0, PRINT_CHAR	# load the syscall option for printing chars
	syscall			# print the char
	jr	$ra
