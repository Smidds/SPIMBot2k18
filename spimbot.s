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
		la 		$t0, isFrozen
		lw 		$t0, 0($t0)
		bne 	$t0, 1, else1				# Check if we're frozen

		##############################
		##  Handle being frozen here #
		##############################		

		j 		main
	else1:
		la 		$t0, station_up
		lw 		$t0, 0($t0)
		bne 	$t0, 1, else2				# Check if station is up

		##############################
		##  Chase the station here   #
		##############################

		j		main
	else2:
		la 		$t0, station_down
		lw 		$t0, 0($t0)
		bne 	$t0, 1, else3				# Check if station is down

		##############################
		##  Do whatever we do here   #
		##############################

		j		main
	else3:									
		li 		$t0, LOW_ALT_WARN		
		lw 		$t1, BOT_X
		blt 	$t0, $t1, else4				# Check if our altitude is too low and abort

		##############################
		##  Correct altitutde here   #
		##############################

		j 		main
	else4:
		li 		$t0, LOW_ENERGY_WARN		
		lw 		$t1, GET_ENERGY
		blt 	$t0, $t1, else5				# Check if our energy is too low and abort

		##############################
		##  Handle low energy here   #
		##############################

		j 		main
	else5:
		lw 		$t0, 0(OTHER_BOT_X)
		slt 	$t0, 70
		bne 	$t0, 1, else5				# Check if the other bot is low enough to screw with them.

		move 	$a0, 1
		jal 	solvePuzzle

		j		main


        # note that we infinite loop to avoid stopping the simulation early
        j       main



#################################################
# solvePuzzle: 									#
#   Solves a puzzle in the method specified.	#
#                                               #
# Parameters:                                   #
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
		

#################################################
# count_disjoint_regions:                       #
#   Count the numbe of disjoint regions found   #
#   within a provided canvas and lines struct   #
#                                               #
# Parameters:                                   #
#   $a0 = Lines* lines                          #
#   $a1 = Canvas* canvas                        #
#   $a2 = Solution* solution                    #
#                                               #
#################################################
count_disjoint_regions:
		sub  $sp, $sp, 20
		sw   $ra, 0($sp)
		sw   $s0, 4($sp)				# $a0
		sw   $s1, 8($sp)				# $a1
		sw   $s2, 12($sp)				# $a2
		sw   $s3, 16($sp)				# $t0									// i

		move $s0, $a0
		move $s1, $a1
		move $s2, $a2

        li   $t0, 0						# $t0 = 0 								// i
	cdr_for_loop:
		lw   $t1, 0($a0)				# $t1 = lines->num_lines
		bge  $t0, $t1, cdr_done			# Exit if i >= lines->num_lines

		mul  $t4, $t0, 4				# $t4 = actual "i" index

		lw   $t1, 4($a0)				# $t1 = &lines->coords[0]

		add  $t2, $t4, $t1				# $t2 = &lines->coords[0][i]
		lw   $t2, 0($t2)				# $t2 = lines->coords[0][i]				// start_pos

		lw   $t1, 8($a0)				# $t1 = &lines->coords[1]

		add  $t3, $t4, $t1				# $t3 = &lines->coords[1][i]
		lw   $t3, 0($t3)				# $t3 = lines->coords[1][i]				// end_pos

		move $s0, $a0
		move $s1, $a1
		move $s2, $a2
		move $s3, $t0

		move $a2, $a1
		move $a1, $t3
		move $a0, $t2

		jal  draw_line

		move $t0, $s3

		li   $t1, 65					# $t1 = 'A'
		rem  $t2, $t0, 2				# $t2 = i % 2
		add  $t1, $t1, $t2				# $t1 = 'A' + (i % 2)

		move $a0, $t1
		move $a1, $s1

		jal  count_disjoint_regions_step

		move $a0, $s0
		move $a1, $s1
		move $a2, $s2
		move $t0, $s3

		lw   $t1, 4($a2)				# $t1 = &solution->counts
		mul  $t4, $t0, 4				# $t4 = actual "i" index
		add  $t1, $t1, $t4				# $t1 = &solution->counts[i]
		sw   $v0, 0($t1)				# solution->counts[i] = count;

		add $t0, $t0, 1					# $t0 = i++
		j   cdr_for_loop
	cdr_done:
		lw   $ra, 0($sp)
		lw   $s0, 4($sp)
		lw   $s1, 8($sp)
		lw   $s2, 12($sp)
		lw   $s3, 16($sp)
		add  $sp, $sp, 20
        # Pray for me
        jr   $ra


#################################################
# count_disjoint_regions_step:                  #
#   Count the numbe of disjoint empty areas     #
#   in a given canvas.                          #
#                                               #
# Parameters:                                   #
#   $a0 = char marker                           #
#   $a1 = Canvas* canvas                        #
# Returns:                                      #
#   $v0 = int region_count                      #
#                                               #
#################################################
count_disjoint_regions_step:
        sub  $sp, $sp, 24						# Setup that fresh stack
		sw   $ra, 0($sp)						# Store $ra
		sw   $s0, 4($sp)						# Store all $s registers that we use
		sw   $s1, 8($sp)
		sw   $s2, 12($sp)
		sw   $s3, 16($sp)
		sw   $s4, 20($sp)
		move $s0, $a0							# Store params
		move $s1, $a1

		li   $v0, 0								# $v0 = 0 // region_count

		li   $t0, 0								# $t0 = 0 // row
	cdrs_for_loop_1:
		lw   $t1, 0($a1)						# $t1 = canvas->height
		bge  $t0, $t1, cdrs_done				# row >= canvas->height, exit for loop
	
		li   $t1, 0								# $t1 = 0 // col
	cdrs_for_loop_2:
		lw   $t2, 4($a1)						# $t2 = canvas->width
		bge  $t1, $t2, cdrs_for_loop_2_end		# col >= canvas->width, exit for loop

		lw   $t2, 12($a1)						# $t2 = &(canvas->canvas)
		mul  $t3, $t0, 4						# Get the true "row" index
		add  $t2, $t2, $t3						# $t2 = &canvas->canvas[row]
		lw   $t2, 0($t2)						# $t2 = canvas->canvas[row]
		add  $t2, $t2, $t1						# $t2 = &canvas->canvas[row][col]

		lb   $t3, 0($t2)						# $t3 = canvas->canvas[row][col] // $t3 = curr_char

		## If statement ##
		lb   $t4, 8($a1)						# $t4 = canvas->pattern
		beq  $t3, $t4, cdrs_false				# False if curr_char == canvas->pattern
		beq  $t3, $a0, cdrs_false				# False if curr_char == marker

		add  $v0, $v0, 1						# $v0 = region_count++
		
		move $s2, $t0							# Hide my working variables
		move $s3, $t1
		move $s4, $v0

		move $a3, $a1
		move $a2, $a0
		move $a1, $t1
		move $a0, $t0							# Setup args as expected
		
		jal  flood_fill							# Run flood_fill

		move $a0, $s0							# Restore my variables to working order
		move $a1, $s1
		move $t0, $s2
		move $t1, $s3
		move $v0, $s4
	cdrs_false:
		add  $t1, $t1, 1						# $t1 = col++
		j    cdrs_for_loop_2					# Return to cdrs_for_loop_2
		## End cdrs_for_loop_2
	cdrs_for_loop_2_end:
		add  $t0, $t0, 1						# $t0 = row++
		j    cdrs_for_loop_1					# Return to cdrs_for_loop_1
		## End cdrs_for_loop_1
	cdrs_done:
		lw   $ra, 0($sp)						# Restore what everyone else uses
		lw   $s0, 4($sp)
		lw   $s1, 8($sp)
		lw   $s2, 12($sp)
		lw   $s3, 16($sp)
		lw   $s4, 20($sp)
		add  $sp, $sp, 24
        # Pray for me
        jr   $ra

#################################################
# flood_fill:                                   #
#   Mark an empty region as visited on the      #
#   canvas using a flood fill algorithm.        #
#                                               #
# Parameters:                                   #
#   $a0 = int row                               #
#   $a1 = int col                               #
#   $a2 = char marker                           #
#   $a3 = Canvas* canvas                        #
#                                               #
#################################################
flood_fill:
        # Your code goes here :)
        slt  $t0, $a0, 0                        # $t0 = row < 0 
		beq  $t0, 1, end						# If row < 0 is true, exit
        slt  $t0, $a1, 0                        # $t0 = col < 0
		beq  $t0, 1, end						# If col < 0 is true, exit
		lw   $t0, 0($a3)						# $t0 = canvas->height
		bge  $a0, $t0, end						# If row >= canvas->height is false, exit
		lw   $t0, 4($a3)						# $t0 = canvas->width
		bge  $a1, $t0, end						# If row >= canvas->width is false, exit
	false:
		lw   $t0, 12($a3)						# $t0 = &(canvas->canvas)
		mul  $t1, $a0, 4						# Get the true "row" index
		add  $t0, $t0, $t1						# $t0 = &canvas->canvas[row]
		lw   $t0, 0($t0)						# $t0 = canvas->canvas[row]
		add  $t0, $t0, $a1						# $t0 = &canvas->canvas[row][col]

		lb   $t1, 0($t0)						# $t1 = canvas->canvas[row][col] // $t1 = curr
		lb 	 $t3, 8($a3)						# $t3 = canvas->marker

		beq  $t1, $t3, end						# If curr != canvas->pattern, bail
		beq  $t1, $a2, end						# If curr != marker, bail

		sub  $sp, $sp, 20						# Build that register, SON!
        sw   $ra, 0($sp)                        # ... and store $ra while yer at it

		sb   $a2, 0($t0)						# canvas->canvas[row][col] = marker

		#####  Let's Recurse!  #####
		sw   $s0, 4($sp)						# Store those $s registers
		sw   $s1, 8($sp)
		sw   $s2, 12($sp)
		sw   $s3, 16($sp)
		move $s0, $a0							# Place our function params in the $s registers
		move $s1, $a1
		move $s2, $a2
		move $s3, $a3

		sub  $a0, $a0, 1						# $a0 = row - 1
		jal  flood_fill							# flood_fill(row - 1, col, marker, canvas);

		move $a0, $s0							# Restore the params from $s registers
		move $a1, $s1
		move $a2, $s2
		move $a3, $s3

		add  $a1, $a1, 1						# $a1 = col + 1
		jal  flood_fill							# flood_fill(row, col + 1, marker, canvas);

		move $a0, $s0							# Restore the params from $s registers
		move $a1, $s1
		move $a2, $s2
		move $a3, $s3

		add  $a0, $a0, 1						# $a0 = row + 1
		jal  flood_fill							# flood_fill(row + 1, col, marker, canvas);

		move $a0, $s0							# Restore the params from $s registers
		move $a1, $s1
		move $a2, $s2
		move $a3, $s3

		sub  $a1, $a1, 1						# $a1 = col - 1
		jal  flood_fill							# flood_fill(row, col - 1, marker, canvas);

		lw   $s0, 4($sp)						# Restore those $s registers
		lw   $s1, 8($sp)
		lw   $s2, 12($sp)
		lw   $s3, 16($sp)

		lw   $ra, 0($sp)						# Restore $ra
		add  $sp, $sp, 20						# Tear down the stack!
	end:
        # Pray for me
        jr      $ra


#################################################
# draw_line:                                    #
#   Draw a line on canvas from start_pos to     #
#   end_pos. start_pos will always be smaller   #
#   than end_pos.                               #
#                                               #
# Parameters:                                   #
#   $a0 = int start_pos                         #
#   $a1 = int end_pos                           #
#   $a2 = Canvas* canvas                        #
#                                               #
#################################################
draw_line:
        # Your code goes here :)
      if:
        lw     $t0, 4($a2)                      # $t0 = canvas-width
        li     $t1, 1                           # $t1 = step_size = 1
        sub    $t2, $a1, $a0                    # $t2 = end_pos - start_pos
        blt    $t2, $t0, exit_if                   # if end_pos - start_pos < width then
        move   $t1, $t0                         # step_size = width

      exit_if:
        move   $t2, $a0                         # $t2 = pos = start_pos

      for:
        add    $t3, $a1, $t1                    # $t3 = end_pos + step_size
        beq    $t2, $t3, done                   # if $t2 == $t3, finish

        # We can only replace $t3, as it'll be reset
        # So $t3 - $t6 we can work with

        lb     $t3, 8($a2)                      # $t3 = canvas->pattern
        div    $t5, $t2, $t0                    # $t5 = pos / width
        mul    $t5, $t5, 4                      # $t5 = 4 * $t5 to get actual index
        lw     $t4, 12($a2)                     # $t4 = &(canvas->canvas)
        add    $t4, $t4, $t5                    # $t4 = &(canvas[pos / width])
        lw     $t4, 0($t4)                      # $t4 = (canvas[pos / width])
        rem    $t5, $t2, $t0                    # pos % width
        add    $t4, $t4, $t5                    # $t4 = &(canvas[pos / width][pos % width])
        sb     $t3, 0($t4)                      # store into $t4 canvas-pattern
        add    $t2, $t2, $t1                    # pos += step_size
        j      for                              # jump to the beginning of the for loop

      done:
        # pray for me
        jr      $ra
