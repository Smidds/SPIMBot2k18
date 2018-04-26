# debug constants
PRINT_INT_ADDR              = 0xffff0080
PRINT_FLOAT_ADDR            = 0xffff0084
PRINT_HEX_ADDR              = 0xffff0088

# spimbot memory-mapped I/O
VELOCITY                    = 0xffff0010
ANGLE                       = 0xffff0014
ANGLE_CONTROL               = 0xffff0018
BOT_X                       = 0xffff0020
BOT_Y                       = 0xffff0024
OTHER_BOT_X                 = 0xffff00a0
OTHER_BOT_Y                 = 0xffff00a4
TIMER                       = 0xffff001c
SCORES_REQUEST              = 0xffff1018

ASTEROID_MAP                = 0xffff0050
COLLECT_ASTEROID            = 0xffff00c8

STATION_LOC                 = 0xffff0054
DROPOFF_ASTEROID            = 0xffff005c

GET_ENERGY                  = 0xffff00c0
GET_CARGO                   = 0xffff00c4

REQUEST_PUZZLE              = 0xffff00d0
SUBMIT_SOLUTION             = 0xffff00d4

THROW_PUZZLE                = 0xffff00e0
UNFREEZE_BOT                = 0xffff00e8
CHECK_OTHER_FROZEN          = 0xffff101c

# interrupt constants
BONK_INT_MASK               = 0x1000
BONK_ACK                    = 0xffff0060

TIMER_INT_MASK              = 0x8000
TIMER_ACK                   = 0xffff006c

REQUEST_PUZZLE_INT_MASK     = 0x800
REQUEST_PUZZLE_ACK          = 0xffff00d8

STATION_ENTER_INT_MASK      = 0x400
STATION_ENTER_ACK           = 0xffff0058

STATION_EXIT_INT_MASK       = 0x2000
STATION_EXIT_ACK            = 0xffff0064

BOT_FREEZE_INT_MASK         = 0x4000
BOT_FREEZE_ACK              = 0xffff00e4

## Global Constants
LOW_ALT_WARN				= 50
SAFE_ALT					= 90
LOW_ENERGY_WARN				= 200
WAIT_STATION_X				= 100
WAIT_STATION_Y				= 100

# put your data things here
.data
.align 2
	asteroid_map: 		.space 	1024
	puzzle_data:		.space 	336			## Looks like Puzzle is this big
	puzzle_solution:	.space	8
	station_up:   		.space 	1
	station_down: 		.space 	1
	station_down: 		.space 	1
	isFrozen:			.space 	1
	puzzleReady:		.space 	1

.text
main:
        # put your code here :)

        # note that we infinite loop to avoid stopping the simulation early
        j       main



#################################################
# Solve_Puzzle:									#
#   Solves a puzzle in the method specified.	#
#                                               #
#   $a0 = 0 -> energize | 1 -> evil             #
#                                               #
#################################################
solvePuzzle:
        sub		$sp, $sp, 8					# Sub off our stack here as we handle stuff
		sw 		$ra, 0($sp) 				# Protect the $ra
		sw 		$t0, 4($sp) 				# Protect the $t0

		#############################
		##  Solve the puzzle here   #
		#############################

		beq 	$a0, $0, puzzle_continue	# If $a0 = 0 skip setting the throw bit
		sw 		$a1, THROW_PUZZLE
	puzzle_continue:
		la 		$t0, puzzle_solution
		lw 		$t0, 4($t0)
		sw 		$t0, SUBMIT_SOLUTION
		sw 		$0, puzzle_solution			# Zero out our puzzle_solution struct

		lw 		$ra, 0($sp) 				# Restore the $ra
		lw 		$t0, 4($sp) 				# Restore the $t0
		add		$sp, $sp, 8					# Sub off our stack here as we handle stuff
		jr 		$ra
		