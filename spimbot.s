# debug constants
PRINT_INT_ADDR              = 0xffff0080
PRINT_FLOAT_ADDR            = 0xffff0084
PRINT_HEX_ADDR              = 0xffff0088

# syscall constants
PRINT_STRING            	= 4
PRINT_CHAR              	= 11
PRINT_INT               	= 1

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
OTHER_BOT_WARN 				= 70
SAFE_ALT					= 90
LOW_ENERGY_WARN				= 250
WAIT_STATION_X		        = 100
WAIT_STATION_Y				= 100
CARRYING_CAPACITY     		= 256
ACCEPTABLE_STATION_DIFF  	= 175
ACCEPTABLE_STATION_X		 = 75
MEGA_REFUEL_NUM_TIMES			= 1

# put your data things here
.data
puzzle_solution:       .word   2       counts
counts:         .space  8
mega_refuel:				.word  4

.align 2
	asteroid_map_address: 		.space 	1024
	puzzle_data:				.space 	1024		## Looks like Puzzle is this big
	thrown_puzzle_data:			.space 	1024		## Looks like Puzzle is this big
	station_up:   				.space 	1
	have_dropped_off:   		.space 	1
	station_down: 				.space 	1
	isFrozen:					.space 	1
	puzzleReady:				.space 	1
	fuel_requested:				.space  1
	check_other_bot:			.space 	1


.text
main:
	# put your code here :)
	sub     $sp, $sp, 16        				# get some space
	sw      $s0, 0($sp)         				#
	sw      $s1, 4($sp)         				#
	sw      $s2, 8($sp)         				#
	sw      $s3, 12($sp)        				#

	sb 		$0, fuel_requested
	li 		$s0, 1
	sb 		$s0, check_other_bot

	li      $s0, STATION_EXIT_INT_MASK
	or      $s0, $s0, STATION_ENTER_INT_MASK
	or 		$s0, $s0, REQUEST_PUZZLE_INT_MASK
	or 		$s0, $s0, BOT_FREEZE_INT_MASK
	or 		$s0, $s0, TIMER_INT_MASK
	or      $s0, $s0, 1
	mtc0    $s0, $12


	else_begin:
		la 		$s0, isFrozen
		lb 		$s0, 0($s0)
		bne 	$s0, 1, else_request_fuel_hold	# Check if we're frozen

		jal 	unfreeze
		sb 		$0, isFrozen						# State that we're not frozen anymore

		j 		else_begin

	else_mega_refuel_start:

			# Skip if below safe altitude
			lw		$s0, BOT_X
			li		$s1, SAFE_ALT
			blt		$s0, $s1, else1


			# if mega_refuel == 0 then skip mega refueling and go to regular
			la 		$s0, mega_refuel
			lw 		$s0, 0($s0)
			beq		$s0, $0, else_request_fuel_hold

			jal   standby			# stay in standby if it is time to mega refuel

			# if puzzle is ready (and mega_refuel != 0) then go to else_mega_refuel_end
			la		$s0, puzzleReady
			lb		$s0, 0($s0)
			beq		$s0, 1, else_mega_refuel_end

			# if puzzle is not ready and mega_refuel is not zero, just keep looping until puzzle is ready
			la		$s0, fuel_requested
			lb		$s0, 0($s0)
			beq		$s0, 1, else_begin

			# if(mega_refuel != 0 && !puzzleReady && !fuel_requested)
			# then request puzzle
			la 		$s0, puzzle_data
			sw		$s0, REQUEST_PUZZLE

			li 		$s0, 1
			sb		$s0, fuel_requested

			j			else_begin


	else_mega_refuel_end:
		la		$s6, mega_refuel		#
		lw		$s6, 0($s6)		#
		add		$s7, $s7, 1		#  =  +

		# solve puzzle
		move 	$a0, $0
		li        	$t0, 0        						# $t0 = 0
        sw        	$t0, ANGLE
        li        	$t0, 1        						# $t0 = 1
        sw        	$t0, ANGLE_CONTROL

        li        	$t0, 2        						# $t0 = 1
        sw        	$t0, VELOCITY
		jal 	solvePuzzle				# solve the puzzle to fuel up
		sb		$0, fuel_requested
		sb		$0, puzzleReady		#

		# only do it once cuz i can't fix code
		#sw		$0, mega_refuel		#

		# this code makes it do it multipile times
		la 		$s0, mega_refuel
		lw 		$s0, 0($s0)
		add		$s0, $s0, 1
		sb		$s0, mega_refuel

		# if (mega_refuel > MEGA_REFUEL_NUM_TIMES) { mega_refuel = 0}
		# else go back to the top
		li		$s1, MEGA_REFUEL_NUM_TIMES
		ble		$s0, $s1, else_begin
		sw		$0, mega_refuel		#

		j			else_begin

	else_request_fuel_hold:
		la		$s0, fuel_requested
		lb		$s0, 0($s0)

		beq		$s0, 1, else_get_fueled
		la 		$s0, puzzle_data
		sw		$s0, REQUEST_PUZZLE

		li 		$s0, 1
		sb		$s0, fuel_requested		#


	else_get_fueled:
		# checks if puzzle is ready and we need to refuel.
		# we move to standby (250, bot.y) and solve puzzle
		la		$s0, puzzleReady
		lb		$s0, 0($s0)

		bne		$s0, 1, else1

		li 		$s0, LOW_ENERGY_WARN
		lw 		$s1, GET_ENERGY


		blt 	$s0, $s1, else1						# Branch if energy is at a fine level
																		# continue if energy is low

		li      $a0, 0xfa0000
		lw 			$s1, BOT_Y									# (250, y)
		or			$a0, $a0, $s1
		jal			standby				# jump to move_bot and save position to $ra

		move 	$a0, $0
		li        	$t0, 0        						# $t0 = 0
        sw        	$t0, ANGLE
        li        	$t0, 1        						# $t0 = 1
        sw        	$t0, ANGLE_CONTROL

        li        	$t0, 2        						# $t0 = 1
        sw        	$t0, VELOCITY
		jal 	solvePuzzle				# solve the puzzle to fuel up
		sb			$0, fuel_requested
		sb			$0, puzzleReady		#



		j 		else1



	else1:
	 	la 		$s0, station_up
		la 		$s1, have_dropped_off
	 	lb 		$s0, 0($s0)
		lb 		$s1, 0($s1)
		not 	$s1, $s1 							# $s1 = !have_dropped_off <-- will be true if we haven't dropped off yet
		and 	$s0, $s0, $s1 						# If station_up AND we haven't dropped off yet, we should take care of that
	 	bne 	$s0, 1, else2							# Check if station is up

		lw      $t0, STATION_LOC        			#
		srl     $t1, $t0, 16            			# $t1 = STATION_LOC.x
		and     $t2, $t0, 0x0000ffff    			# $t2 = STATION_LOC.y
		lw      $t3, BOT_X              			# $t3 = BOT_X
		lw      $t4, BOT_Y              			# $t4 = BOT_Y

		sub		$t5, $t3, $t1
		li		$t6, ACCEPTABLE_STATION_DIFF

		bgt		$t5, $t6, else2							# if botx - stationx > ACCEPTABLE_STATION_DIFF

		li		$s0, ACCEPTABLE_STATION_X				# if stationx < ACCEPTABLE_STATION_X
		blt     $t1, $s0, else2							# then skip chasing

		bne     $t1, $t3, else1_cont          			# if station.x != bot.x then goEW
		bne     $t2, $t4, else1_cont          			# if station.y != bot.y then goSN
		sw      $t0, DROPOFF_ASTEROID   				# now the bot should overlap the station


		li 		$s1, 1
		la		$s0, have_dropped_off					# we are going to drop off asteroid
		sb		$s1, 0($s0)								# raise the flag

		# mega refuel after dropoff
		li		$s1, 1
		sw		$s1, mega_refuel

		j		else1_end								# jump to else1_end

	else1_cont:
		# srl     $t1, $t0, 16            			# $t1 = STATION_LOC.x
		# lw      $t3, BOT_X              			# $t3 = BOT_X
		# li		$t2, 0x								# $t2 = 0x

		# slt		$t1,
		move 	$a0, $t0				# $a0 = $t0
		jal		move_bot				# jump to move and save position to $ra

    else1_end:
	 	j		else_begin

	else2:
		la 		$s0, station_down
		lb 		$s0, 0($s0)
		bne 	$s0, 1, else5						# Check if station is down

		lw      $s0, GET_CARGO       				# $s0 = cargo_amount
		add     $s0, $s0, $v1        				# $s0 = cargo_amount + best_points
		li      $s1, CARRYING_CAPACITY             				# $s1 = carrying capacity
		ble     $s0, $s1, else_done 		# if $s0 >= 256 then enable_int

		li		$a0, 0xfa0032						# $a0 = 0xfa00
		jal		standby					# jump to standby and save position to $ra
		# j 			else_done

		##############################
		##  Do whatever we do here   #
		##############################

		j		else_begin
	else5:
		lw 		$s0, OTHER_BOT_X
		slt 	$s0, OTHER_BOT_WARN
		lb 		$s1, check_other_bot
		lb 		$s2, puzzleReady
		and 	$s1, $s1, $s2 						# Check if puzzleReady AND check_other_bot
		and 	$s0, $s0, $s1						# $s0 = (other_bot_x < other_bot_warn && check_other_bot && puzzleReady)
		bne 	$s0, 1, else_done					# Check if the other bot is low enough and we haven't checked on them already to screw with them.

		lw		$s0, TIMER							# read current time
		add		$s0, $s0, 5000						# add 5000 to current time
		sw		$s0, TIMER							# request timer interrupt in 5000 cycles
		li 		$a0, 1								# Do evil puzzle, MUWAHAHAHAHAAAAA
		li        	$t0, 0        						# $t0 = 0
        sw        	$t0, ANGLE
        li        	$t0, 1        						# $t0 = 1
        sw        	$t0, ANGLE_CONTROL

        li        	$t0, 2        						# $t0 = 1
        sw        	$t0, VELOCITY
		jal 	solvePuzzle
		sb		$0, puzzleReady
		sb		$0, fuel_requested		#
				#

		sb 		$0, check_other_bot 				# Set it check_other_bot to zero, as we have checked and should not check again
													# until interrupted in the future

		j 		else_begin

	else_done:
		jal     findNearest         				# findNearest
		move    $s2, $v0            				# $a0 = $v
		lw      $s0, GET_CARGO       				# $s0 = cargo_amount
		add     $s0, $s0, $v1        				# $s0 = cargo_amount + best_points
		li      $s1, CARRYING_CAPACITY             				# $s1 = carrying capacity
		bge     $s0, $s1, enable_int_station 		# if $s0 >= 256 then enable_int
		# li      $s0, 0               				# $s0 = 0
		# mtc0    $s0, $12             				# disable to global interrupt signal
		move    $a0, $s2             				# $a0 = $s0
		jal     move_bot                  			# chase
    sw      $s0, COLLECT_ASTEROID

    j       end                    				# jump to end

	enable_int_station:


		li		$s0, 0								# station is gone,
		la		$s1, have_dropped_off				# lower the flag
		sb		$s0, 0($s1)							#



	end:
		# note that we infinite loop to avoid stopping the simulation early
		j       else_begin

#--------------------------- END OF MAIN FUNCTION ----------------------------#

move_bot:
		li        $t0, 10        					# $t0 = 10
	    sw        $t0, VELOCITY  					# $a0 should be the address to chase
	    move      $t0, $a0        					# $t0 = $a0

	move_X:
			lw        $t1, BOT_X                    # get the BOT_X
			srl       $t2, $t0, 16                  # $t2 = asteroid.x
			beq       $t1, $t2, move_Y            	# if BOT_X == asteroid.x then getToY
			blt       $t1, $t2, move_R             	# if BOT_X < asteroid.x then right

			li        $t3, 180                      # $t3 = degrees = 180
			sw        $t3, ANGLE                    # set ANGLE
			li        $t3, 1                        # $t3 = ANGLE_CONTROL = 1
			sw 		  $t3, ANGLE_CONTROL            # set ANGLE_CONTROL

			j		  move_Y						# jump to move_end

	move_R:
			li        $t3, 0                        # $t3 = 0
			sw        $t3, ANGLE                    # set ANGLE
			li        $t3, 1                        # $t3 = 1
			sw        $t3, ANGLE_CONTROL            # set ANGLE_CONTROL

			j		  move_end						# jump to move_end

	move_Y:
			lw        $t1, BOT_Y                    # get the BOT_Y
			and       $t2, $t0, 0x0000ffff          # $t2 = asteroid.y
			beq       $t1, $t2, move_end          	# if BOT_Y == asteroid.y then adjust_x
			blt       $t1, $t2, move_D              # if BOT_Y < asteroid.y then down

			li        $t3, 270                      # $t3 = 270
			sw        $t3, ANGLE                    # set ANGLE
			li        $t3, 1                        # $t3 = 1
			sw        $t3, ANGLE_CONTROL            # set ANGLE_CONTROL

			j		  move_end						# jump to move_end

	move_D:
			li        $t3, 90                       # $t3 = 90
			sw        $t3, ANGLE                    # set ANGLE
			li        $t3, 1                        # $t3 = 1
			sw        $t3, ANGLE_CONTROL            # set ANGLE_CONTROL

			j		  move_end						# jump to move_end

	move_end:
			jr			$ra							# return


chase:
    	li        $t0, 10        					# $t0 = 10
    	sw        $t0, VELOCITY  					# $a0 should be the address to chase
    	move      $t0, $a0        					# $t0 = $a0

	c_getToX:
		lw        $t1, BOT_X                    # get the BOT_X
		srl       $t2, $t0, 16                  # $t2 = asteroid.x
		beq       $t1, $t2, c_getToY            # if BOT_X == asteroid.x then getToY
		blt       $t1, $t2, c_right             # if BOT_X < asteroid.x then right

		li        $t3, 180                      # $t3 = degrees = 180
		sw        $t3, ANGLE                    # set ANGLE
		li        $t3, 1                        # $t3 = ANGLE_CONTROL = 1
		sw        $t3, ANGLE_CONTROL            # set ANGLE_CONTROL

		#j         c_getToX                      # jump to getToX
		jr				$ra

	c_right:
		li        $t3, 0                        # $t3 = 0
		sw        $t3, ANGLE                    # set ANGLE
		li        $t3, 1                        # $t3 = 1
		sw        $t3, ANGLE_CONTROL            # set ANGLE_CONTROL

		#j         c_getToX                      # jump to getToX
		jr				$ra					# jump to ra


	c_getToY:
		lw        $t1, BOT_Y                    # get the BOT_Y
		and       $t2, $t0, 0x0000ffff          # $t2 = asteroid.y
		beq       $t1, $t2, c_adjust_x          # if BOT_Y == asteroid.y then adjust_x
		blt       $t1, $t2, c_down              # if BOT_Y < asteroid.y then down

		li        $t3, 270                      # $t3 = 270
		sw        $t3, ANGLE                    # set ANGLE
		li        $t3, 1                        # $t3 = 1
		sw        $t3, ANGLE_CONTROL            # set ANGLE_CONTROL

		#j         c_getToX                      # jump to getToY
		jr				$ra					# jump to $ra

	c_down:
		li        $t3, 90                       # $t3 = 90
		sw        $t3, ANGLE                    # set ANGLE
		li        $t3, 1                        # $t3 = 1
		sw        $t3, ANGLE_CONTROL            # set ANGLE_CONTROL

		#j         c_getToX                      # jump to getToY
		jr				$ra					# jump to $ra

	c_adjust_x:
		lw        $t1, BOT_X                    # get the BOT_X
		srl       $t2, $t0, 16                  # $t2 = asteroid.x
		beq       $t1, $t2, c_end               # if BOT_X == asteroid.x then getToY
		blt       $t1, $t2, c_adjust_x_right    # if BOT_X < asteroid.x then right

		li        $t3, 180                      # $t3 = degrees = 180
		sw        $t3, ANGLE                    # set ANGLE
		li        $t3, 1                        # $t3 = ANGLE_CONTROL = 1
		sw        $t3, ANGLE_CONTROL            # set ANGLE_CONTROL

		#j         c_adjust_x                    # jump to adjust_x
		jr				$ra					# jump to $ra

	c_adjust_x_right:
		li        $t3, 0                        # $t3 = 0
		sw        $t3, ANGLE                    # set ANGLE
		li        $t3, 1                        # $t3 = 1
		sw        $t3, ANGLE_CONTROL            # set ANGLE_CONTROL

		#j         c_adjust_x                    # jump to adjust_x
		jr				$ra					# jump to 		$ra

	c_end:
		jr        $ra                          	# return



## finding the largest ones; we're probably not using this
findFav:                						# after this call $v0 should contain the (x, y), other $t is free to use
		li        $t0, 0                         	# $t0 = (x, y) = 0
		li        $t4, 0                         	# $t4 = best_points = 0

		li        $t5, 0                         	# $t5 = i = 0

	for_loop:
		la        $t2, asteroid_map_address      	# $t2 = asteroid_map_address
		sw        $t2, ASTEROID_MAP              	# $t2 should be the address of current asteroid map
		lw        $t3, 0($t2)                    	# $t3 = length
		add       $t6, $t2, 4                    	# $t6 should be the start of asteroid array
		bge       $t5, $t3, end_findFav        		# if i >= length then getToX, because we should have the best
													# target now stored in $v0

		mul       $t7, $t5, 8                    	# $t7 = i * 8
		add       $t7, $t7, $t6                  	# $t7 = &asteroid[i]
		lw        $t8, 4($t7)                    	# $t8 = asteroid[i].points

		ble       $t8, $t4, looping              	# if asteroid[i].points <= best_points then looping

		lw        $t9, 0($t7)                    	# $t9 = asteroid[i].(x, y)
		srl       $t9, $t9, 8                    	# $t9 = asteroid[i].x
		li        $t1, 40                        	# $t1 = 40
		ble       $t9, $t1, looping              	# if asteroid[i].x <= 40 then looping
		# else set the current asteroid as the fav
		lw        $t4, 4($t7)                    	# $t4 = best_points = asteroid[i].points
		lw        $t0, 0($t7)                    	# $t0 = asteroid[i].(x, y)
		move      $v0, $t0                       	# $v0 = $t0 = (x, y) of fav asteroid
		move      $v1, $t4                       	# $v1 = $t4 = best_points

	looping:
		add       $t5, $t5, 1                    	# i++
		j         for_loop     						# loop

	end_findFav:
		jr        $ra                           	# return


## we're finding nearest
findNearest:
		# li        $t0, 0        					# $t0 = 0
		# mtc0      $t0, $12        					# disable interrupt for now

		la        $t0, asteroid_map_address       	# $t0 contains the asteroidMap
		sw        $t0, ASTEROID_MAP               	#
		lw        $t1, 0($t0)                     	# $t1 = length
		add       $t2, $t0, 4                     	# $t2 = &asteroid[]

		li        $t3, 0                          	# $t3 = currentBest = (0, 0)
		li        $t4, 99999                      	# $t4 = currentBestDist = 99999
		li        $t5, 0                          	# $t5 = i = 0
		li        $t6, 0                          	# $t6 = distance = 0
		li        $v1, 0                          	# $v1 = best_points = 0

	FN_loop:
		bge       $t5, $t1, FN_end                	# if i >= length then FN_end
		mul       $t7, $t5, 8                     	# $t7 = i * 8
		add       $t7, $t7, $t2                   	# $t7 = &asteroid[i]
		lw        $t8, 0($t7)                     	# $t8 = asteroid[i].(x, y)
		srl       $t6, $t8, 16                    	# distance = asteroid[i].x
		lw        $t0, BOT_X                      	# $t0 = BOT_X
		sub       $t6, $t6, $t0                   	# distance = asteroid[i].x - BOT_X
		mul       $t6, $t6, $t6                   	# distance = (asteroid[i].x - BOT_X)^2
		and       $t9, $t8, 0x0000ffff            	# $t9 = asteroid[i].y
		lw        $t0, BOT_Y                      	# $t0 = BOT_Y
		sub       $t9, $t9, $t0                   	# $t9 = asteroid[i].y - BOT_Y
		mul       $t9, $t9, $t9                   	# $t9 = (asteroid[i].y - BOT_Y)^2
		add       $t6, $t6, $t9                   	# $t6 = distance = (asteroid[i].x - BOT_X)^2 + (asteroid[i].y - BOT_Y)^2

		bge       $t6, $t4, after_if              	# if distance >= currentBestDist then after_if
		srl       $t9, $t8, 16                    	# $t9 = asteroid[i].x
		ble       $t9, 40, after_if               	# if asteroid[i].x <= 40 then after_if

		move      $t4, $t6                        	# currentBestDist = distance
		move      $t3, $t8                        	# currentBest = asteroid[i].(x, y)
		lw        $v1, 4($t7)                     	# $v1 = best_points

	after_if:
		add       $t5, $t5, 1						# i++
		j         FN_loop    						# jump to FN_loop

	FN_end:
		move      $v0, $t3							# $v0 = $t3

		jr        $ra 								# return

unfreeze:
		sub		$sp, $sp, 8						# Sub off our stack
		sw 		$ra, 0($sp) 					# Protect the $ra
		sw 		$t0, 4($sp) 					# Protect the $t0

		la 		$t0, thrown_puzzle_data

		move 	$a1, $t0
        add 	$a0, $t0, 16
        la      $a2, puzzle_solution           	# s2 = solution
		li        	$t0, 0        						# $t0 = 0
        sw        	$t0, ANGLE
        li        	$t0, 1        						# $t0 = 1
        sw        	$t0, ANGLE_CONTROL

        li        	$t0, 2        						# $t0 = 1
        sw        	$t0, VELOCITY
        jal     count_disjoint_regions

		la 		$t0, puzzle_solution
		lw 		$t0, 4($t0)
		sw 		$t0, SUBMIT_SOLUTION
		sw 		$0, puzzle_solution				# Zero out our puzzle_solution struct

		lw 		$ra, 0($sp) 					# Restore the $ra
		lw 		$t0, 4($sp) 					# Restore the $t0
		add		$sp, $sp, 8						# Close off our stack
		jr 		$ra

#################################################
# solvePuzzle: 									#
#   Solves a puzzle in the method specified.	#
#                                               #
# Parameters:                                   #
#   $a0 = 0 -> energize | 1 -> evil             #
#                                               #
#################################################

# Struct Puzzle{
# 	// Canvas
# 	Canvas canvas;																		<--- 16B
# 	// Lines (at offset 16)
# 	Lines lines;																		<--- 16B
# 	// The rest of the struct stores the actual data for canvas and lines.
# 	// You should not need to know the exact format of this field.
# 	// You should access data following the pointers in canvas and coords.
# 	unsigned char[300] data;															<--- 332 ish-B
# }

solvePuzzle:
    	sub		$sp, $sp, 12					# Sub off our stack
		sw 		$ra, 0($sp) 					# Protect the $ra
		sw 		$t0, 4($sp) 					# Protect the $t0
		sw 		$a0, 8($sp)						# Protect the $a0

		la 		$t0, puzzle_data

        add 	$a0, $t0, 16					# s0 = Lines
		move 	$a1, $t0						# s1 = Canvas
        la      $a2, puzzle_solution           	# s2 = solution

        jal     count_disjoint_regions
		lb 		$t0, isFrozen
		beq		$t0, $0, puzzle_skip_frozen
		jr 		$ra
	puzzle_skip_frozen:
		lw 		$a0, 8($sp)						# Restore the $a0
		beq 	$a0, $0, puzzle_continue		# If $a0 == 0 skip setting the throw bit
		sw 		$a0, THROW_PUZZLE
	puzzle_continue:
		la 		$t0, puzzle_solution
		lw 		$t0, 4($t0)
		sw 		$t0, SUBMIT_SOLUTION
		sw 		$0, puzzle_solution				# Zero out our puzzle_solution struct
		# sb 		$0, puzzleReady

		lw 		$ra, 0($sp) 					# Restore the $ra
		lw 		$t0, 4($sp) 					# Restore the $t0
		add		$sp, $sp, 12					# Close off our stack
		jr 		$ra

count_disjoint_regions:
        sub     $sp, $sp, 36
        sw      $ra, 0($sp)
        sw      $s0, 4($sp)
        sw      $s1, 8($sp)
        sw      $s2, 12($sp)
        sw      $s3, 16($sp)
        sw      $s4, 20($sp)
        sw      $s5, 24($sp)
        sw      $s6, 28($sp)
        sw      $s7, 32($sp)
        move    $s0, $a0        # s0 = lines
        move    $s1, $a1        # s1 = canvas
        move    $s2, $a2        # s2 = solution

        lw      $s4, 0($s0)     # s4 = lines->num_lines
        li      $s5, 0          # s5 = i
        lw      $s6, 4($s0)     # s6 = lines->coords[0]
        lw      $s7, 8($s0)     # s7 = lines->coords[1]
	for_loop_cdr:
        bgeu    $s5, $s4, end_for_cdr
        mul     $t2, $s5, 4     # t2 = i*4
        add     $t3, $s6, $t2   # t3 = &lines->coords[0][i]
        lw      $a0, 0($t3)     # a0 = start_pos = lines->coords[0][i]
        add     $t4, $s7, $t2   # t4 = &lines->coords[1][i]
        lw      $a1, 0($t4)     # a1 = end_pos = lines->coords[1][i]
        move    $a2, $s1
        jal     draw_line

        li      $t9, 2
        div     $s5, $t9
        mfhi    $t6             # t6 = i % 2
        addi    $a0, $t6, 65    # a0 = 'A' + (i % 2)
        move    $a1, $s1        # count_disjoint_regions_step('A' + (i % 2), canvas)
        jal     count_disjoint_regions_step                # v0 = count
        lw      $t6, 4($s2)     # t6 = solution->counts
        mul     $t7, $s5, 4
        add     $t7, $t7, $t6   # t7 = &solution->counts[i]
        sw      $v0, 0($t7)     # solution->counts[i] = count
        addi    $s5, $s5, 1     # i++
        j       for_loop_cdr

end_for_cdr:
        lw      $ra, 0($sp)
        lw      $s0, 4($sp)
        lw      $s1, 8($sp)
        lw      $s2, 12($sp)
        lw      $s3, 16($sp)
        lw      $s4, 20($sp)
        lw      $s5, 24($sp)
        lw      $s6, 28($sp)
        lw      $s7, 32($sp)
        add     $sp, $sp, 36
        jr      $ra

	count_disjoint_regions_step:
	        sub     $sp, $sp, 36
	        sw      $ra, 0($sp)
	        sw      $s0, 4($sp)
	        sw      $s1, 8($sp)
	        sw      $s2, 12($sp)
	        sw      $s3, 16($sp)
	        sw      $s4, 20($sp)
	        sw      $s5, 24($sp)
	        sw      $s6, 28($sp)
	        sw      $s7, 32($sp)

	        move    $s0, $a0
	        move    $s1, $a1

	        li      $s2, 0                  # $s2 = region_count
	        li      $s3, 0                  # $s3 = row
	        lw      $s4, 0($s1)             # $s4 = canvas->height
	        lw      $s6, 4($s1)             # $s6 = canvas->width
	        lw      $s7, 8($s1)             # canvas->pattern

	cdrs_outer_for_loop:
	        bge     $s3, $s4, cdrs_outer_end
	        li      $s5, 0                  # $s5 = col

	cdrs_inner_for_loop:
	        bge     $s5, $s6, cdrs_inner_end
	        lw      $t0, 12($s1)            # canvas->canvas
	        mul     $t5, $s3, 4             # row * 4
	        add     $t5, $t0, $t5           # &canvas->canvas[row]
	        lw      $t0, 0($t5)             # canvas->canvas[row]
	        add     $t0, $t0, $s5           # &canvas->canvas[row][col]
	        lbu     $t0, 0($t0)             # $t0 = canvas->canvas[row][col]
	        beq     $t0, $s7, cdrs_skip_if  # curr_char != canvas->pattern
	        beq     $t0, $s0, cdrs_skip_if  # curr_char != canvas->marker
	        add     $s2, $s2, 1             # region_count++
	        move    $a0, $s3
	        move    $a1, $s5
	        move    $a2, $s0
	        move    $a3, $s1
	        jal     flood_fill

	cdrs_skip_if:
	        add     $s5, $s5, 1             # col++
	        j       cdrs_inner_for_loop

	cdrs_inner_end:
	        add     $s3, $s3, 1             # row++
	        j       cdrs_outer_for_loop

	cdrs_outer_end:
	        move    $v0, $s2
	        lw      $ra, 0($sp)
	        lw      $s0, 4($sp)
	        lw      $s1, 8($sp)
	        lw      $s2, 12($sp)
	        lw      $s3, 16($sp)
	        lw      $s4, 20($sp)
	        lw      $s5, 24($sp)
	        lw      $s6, 28($sp)
	        lw      $s7, 32($sp)
	        add     $sp, $sp, 36
	        jr      $ra

	flood_fill:
	        sub     $sp, $sp, 20
	        sw      $ra, 0($sp)
	        sw      $s0, 4($sp)
	        sw      $s1, 8($sp)
	        sw      $s2, 12($sp)
	        sw      $s3, 16($sp)
	        move    $s0, $a0                # $s0 = row
	        move    $s1, $a1                # $s1 = col
	        move    $s2, $a2                # $s2 = marker
	        move    $s3, $a3                # $s3 = canvas
	        blt     $s0, $0, ff_return      # row < 0
	        blt     $s1, $0, ff_return      # col < 0
	        lw      $t0, 0($s3)             # $t0 = canvas->height
	        bge     $s0, $t0, ff_return     # row >= canvas->height
	        lw      $t0, 4($s3)             # $t0 = canvas->width
	        bge     $s1, $t0, ff_return     # col >= canvas->width

	        lw      $t0, 12($s3)            # canvas->canvas
	        mul     $t1, $s0, 4
	        add     $t0, $t1, $t0           # $t0 = &canvas->canvas[row]
	        lw      $t0, 0($t0)             # canvas->canvas[row]
	        add     $t1, $s1, $t0           # $t1 = &canvas->canvas[row][col]
	        lbu     $t0, 0($t1)             # $t0 = curr = canvas->canvas[row][col]
	        lbu     $t2, 8($s3)             # $t2 = canvas->pattern
	        beq     $t0, $t2, ff_return     # curr == canvas->pattern
	        beq     $t0, $s2, ff_return     # curr == marker

	        sb      $s2, 0($t1)             # canvas->canvas[row][col] = marker
	        sub     $a0, $s0, 1             # $a0 = row - 1
	        jal     flood_fill              # flood_fill(row - 1, col, marker, canvas);
	        move    $a0, $s0
	        add     $a1, $s1, 1
	        move    $a2, $s2
	        move    $a3, $s3
	        jal     flood_fill              # flood_fill(row, col + 1, marker, canvas);
	        add     $a0, $s0, 1
	        move    $a1, $s1
	        move    $a2, $s2
	        move    $a3, $s3
	        jal     flood_fill              # flood_fill(row + 1, col, marker, canvas);
	        move    $a0, $s0
	        sub     $a1, $s1, 1
	        move    $a2, $s2
	        move    $a3, $s3
	        jal     flood_fill              # flood_fill(row, col - 1, marker, canvas);

	ff_return:
	        lw      $ra, 0($sp)
	        lw      $s0, 4($sp)
	        lw      $s1, 8($sp)
	        lw      $s2, 12($sp)
	        lw      $s3, 16($sp)
	        add     $sp, $sp, 20
	        jr      $ra


	draw_line:
	        lw      $t0, 4($a2)     # t0 = width = canvas->width
	        li      $t1, 1          # t1 = step_size = 1
	        sub     $t2, $a1, $a0   # t2 = end_pos - start_pos
	        blt     $t2, $t0, cont_dl
	        move    $t1, $t0        # step_size = width;
	cont_dl:
	        move    $t3, $a0        # t3 = pos = start_pos
	        add     $t4, $a1, $t1   # t4 = end_pos + step_size
	        lw      $t5, 12($a2)    # t5 = &canvas->canvas
	        lbu     $t6, 8($a2)     # t6 = canvas->pattern
	for_loop_dl:
	        beq     $t3, $t4, end_for_dl
	        div     $t3, $t0        #
	        mfhi    $t7             # t7 = pos % width
	        mflo    $t8             # t8 = pos / width
	        mul     $t9, $t8, 4		# t9 = pos/width*4
	        add     $t9, $t9, $t5   # t9 = &canvas->canvas[pos / width]
	        lw      $t9, 0($t9)     # t9 = canvas->canvas[pos / width]
	        add     $t9, $t9, $t7
	        sb      $t6, 0($t9)     # canvas->canvas[pos / width][pos % width] = canvas->pattern
	        add     $t3, $t3, $t1   # pos += step_size
	        j       for_loop_dl

	end_for_dl:
	        jr      $ra


## chase station
chase_station_extract:
        li          $t0, 10               				# $t0 = 10
        sw          $t0, VELOCITY         				#

        lw          $t0, STATION_LOC        			#
        srl         $t1, $t0, 16            			# $t1 = STATION_LOC.x
        and         $t2, $t0, 0x0000ffff    			# $t2 = STATION_LOC.y
        lw          $t3, BOT_X              			# $t3 = BOT_X
        lw          $t4, BOT_Y              			# $t4 = BOT_Y


        bne         $t1, $t3, goEW          			# if station.x != bot.x then goEW
        bne         $t2, $t4, goSN          			# if station.y != bot.y then goSN
        sw          $t0, DROPOFF_ASTEROID   			# now the bot should overlap the station

        j           cs_end                  			# jump to cs_end

	goEW:
        bgt        $t1, $t3, goEast        				# if station.x > bot.x then goEast
        # otherwise goWest
        li        $t0, 180                 				# $t0 = 180
        sw        $t0, ANGLE               				#
        li        $t0, 1                   				# $t0 = 1
        sw        $t0, ANGLE_CONTROL       				#
        j         cs_loop                  				# jump to cs_loop

	goEast:
        li        $t0, 0                 				# $t0 = 180
        sw        $t0, ANGLE               				#
        li        $t0, 1                   				# $t0 = 1
        sw        $t0, ANGLE_CONTROL       				#
        j         cs_loop                  				# jump to cs_loop

	goSN:
        bgt        $t2, $t4, goSouth      				# if station.y > bot.y then goSouth
        # otherwise goNorth
        li        $t0, 270                 				# $t0 = 180
        sw        $t0, ANGLE               				#
        li        $t0, 1                   				# $t0 = 1
        sw        $t0, ANGLE_CONTROL       				#
        j         cs_loop                  				# jump to cs_loop

	goSouth:
        li        $t0, 90                 				# $t0 = 180
        sw        $t0, ANGLE               				#
        li        $t0, 1                   				# $t0 = 1
        sw        $t0, ANGLE_CONTROL       				#
        j         cs_loop                  				# jump to cs_loop

	cs_loop:
        j         chase_station_extract             			# jump to chase_station
	cs_end:

		jr 	  	$ra

standby:
		# Modified so that it takes $a0
        li        	$t0, 2               				# $t0 = 10
        sw        	$t0, VELOCITY         				#

        # li          $t0, 0xfa0032           			# (150, 50)
		move 		$t0, $a0							# $t0 = $a0
        srl         $t1, $t0, 16            			# $t1 = STATION_LOC.x
        and         $t2, $t0, 0x0000ffff    			# $t2 = STATION_LOC.y
        lw          $t3, BOT_X              			# $t3 = BOT_X
        lw          $t4, BOT_Y              			# $t4 = BOT_Y
        li          $t5, 290                			# $t5 = 290
        # bgt         $t1, $t5, sb_end        			# if station.x > 290 then

        bne         $t1, $t3, sb_goEW          			# if station.x != bot.x then goEW
        bne         $t2, $t4, sb_goSN          			# if station.y != bot.y then goSN
        j           sb_end                  			# jump to cs_end

	sb_goEW:
        bgt        	$t1, $t3, sb_goEast        			# if station.x > bot.x then goEast
        # otherwise goWest
        li        	$t0, 180                 				# $t0 = 180
        sw        	$t0, ANGLE               				#
        li        	$t0, 1                   				# $t0 = 1
        sw        	$t0, ANGLE_CONTROL       				#
        j         	sb_loop                  				# jump to cs_loop

	sb_goEast:
        li        	$t0, 0                 				# $t0 = 180
        sw        	$t0, ANGLE               				#
        li        	$t0, 1                   				# $t0 = 1
        sw        	$t0, ANGLE_CONTROL       				#
        j         	sb_loop                  				# jump to cs_loop

	sb_goSN:
        bgt        	$t2, $t4, sb_goSouth      			# if station.y > bot.y then goSouth
        # otherwise goNorth
        li        	$t0, 270                 				# $t0 = 180
        sw        	$t0, ANGLE               				#
        li        	$t0, 1                   				# $t0 = 1
        sw        	$t0, ANGLE_CONTROL       				#
        j         	sb_loop                  				# jump to cs_loop

	sb_goSouth:
        li        	$t0, 90                 				# $t0 = 180
        sw        	$t0, ANGLE               				#
        li        	$t0, 1                   				# $t0 = 1
        sw        	$t0, ANGLE_CONTROL       				#
        j         	sb_loop                  				# jump to cs_loop

	sb_loop:
        j         	sb_end             					# jump to chase_station
	sb_end:
        li        	$t0, 0        						# $t0 = 0
        sw        	$t0, ANGLE
        li        	$t0, 1        						# $t0 = 1
        sw        	$t0, ANGLE_CONTROL

        li        	$t0, 2        						# $t0 = 1
        sw        	$t0, VELOCITY

		jr 			$ra


#--------------------------- interrupt handler data ---------------------------#
.kdata
someSpace:          .space 8    # some space for 2 registers
non_intrpt_str:	.asciiz "Non-interrupt exception\n"
unhandled_str:	.asciiz "Unhandled interrupt type\n"

.ktext  0x80000180
interrupt_handler:
.set noat
        move        $k1, $at             				# save $at
.set at
        la          $k0, someSpace       				#
        sw          $a0, 0($k0)          				# save $a0
        sw          $a1, 4($k0)          				# save $a1

        mfc0        $k0, $13             				# get cause register
        srl	        $a0, $k0, 2
      	and	        $a0, $a0, 0xf		 				# ExcCode field
      	bne	        $a0, 0, non_intrpt

interrupt_dispatch:                      				# interrupt dispatch center
        mfc0        $k0, $13             				# $k0 = cause register
        beq         $k0, $zero, done     				# if cause register == 0 then done

        and         $a0, $k0, STATION_EXIT_INT_MASK     # is there an exit interrupt?
        bne         $a0, $zero, exit_int                # if $a0 != $zero then exit_int

        and         $a0, $k0, STATION_ENTER_INT_MASK    # is there an enter interrupt?
        bne         $a0, $zero, enter_int               # if $a0 != $zero then enter_int

		and         $a0, $k0, BOT_FREEZE_INT_MASK	    # is there a freeze interrupt?
        bne         $a0, $zero, frozen_int 		       	# if $a0 != $zero then frozen_int

		and         $a0, $k0, REQUEST_PUZZLE_INT_MASK	# is the puzzle ready?
        bne         $a0, $zero, puzzle_ready_int 		# if $a0 != $zero then puzzle_ready_int

		and         $a0, $k0, TIMER_INT_MASK
        bne         $a0, $zero, timer_interrupt         # if $a0 != $zero then timer_interrupt

        and         $a0, $k0, BONK_INT_MASK
        bne         $a0, $zero, bonk_interrupt          # if $a0 != $zero then bonk_interrupt

        li	        $v0, PRINT_STRING	         		# Unhandled interrupt types
    	la	        $a0, unhandled_str
    	syscall
        j           done                 				# jump to done

exit_int:
        sw          $a1, STATION_EXIT_ACK        		# Ack it
		li 			$a1, 1
		sb 			$a1, station_down					# set station_down to true
		li 			$a1, 0
		sb 			$a1, station_up						# set station_up to false
        j           interrupt_dispatch           		# jump to interrupt_dispatch

enter_int:
        sw          $a1, STATION_ENTER_ACK        		# Ack it
		li 			$a1, 0
		sb 			$a1, station_down					# set station_down to false
		li 			$a1, 1
		sb 			$a1, station_up						# set station_up to true
        j           interrupt_dispatch           		# jump to interrupt_dispatch

chase_station:
		li	    	$a1, 1
		sb	    	$a1, station_up						# Set station_up to true
		li	    	$a1, 0
		sb	    	$a1, station_down					# set station_down to false
  		j           interrupt_dispatch            		# jump to interrupt_dispatch

frozen_int:
		la 			$a1, thrown_puzzle_data
		sw 			$a1, BOT_FREEZE_ACK					# Ack it, yo
		li 			$a1, 1
		sb 			$a1, isFrozen						# Set isFrozen to true
		j 			interrupt_dispatch					# jump to interrupt_dispatch

puzzle_ready_int:
		sw 			$a1, REQUEST_PUZZLE_ACK
		li 			$a1, 1
		sb 			$a1, puzzleReady

		j 			interrupt_dispatch

timer_interrupt:
		sw 			$a1, TIMER_ACK
		li 			$a1, 1
		sb 			$a1, check_other_bot

		j 			interrupt_dispatch

bonk_interrupt:
		sw          $a1, BONK_ACK               		# acknowledge interrupt
		j           interrupt_dispatch              	# see if other interrupts are waiting


non_intrpt:												# was some non-interrupt
	   li	        $v0, PRINT_STRING
	   la	        $a0, non_intrpt_str
	   syscall											# print out an error message
														# fall through to done

done:
	   la	        $k0, someSpace
	   lw 			$a0, 0($k0)							# Restore saved registers
	   lw	        $a1, 4($k0)
.set noat
	   move	       	$at, $k1							# Restore $at
.set at
	   eret
