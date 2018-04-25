.text

## struct Canvas {
##     // Height and width of the canvas.
##     unsigned int height;
##     unsigned int width;
##     // The pattern to draw on the canvas.
##     unsigned char pattern;
##     // Each char* is null-terminated and has same length.
##     char** canvas;
## };
## 
## // Count the number of disjoint empty area in a given canvas.
## unsigned int count_disjoint_regions_step(unsigned char marker,
##                                          Canvas* canvas) {
##     unsigned int region_count = 0;
##     for (unsigned int row = 0; row < canvas->height; row++) {
##         for (unsigned int col = 0; col < canvas->width; col++) {
##             unsigned char curr_char = canvas->canvas[row][col];
##             if (curr_char != canvas->pattern && curr_char != marker) {
##                 region_count ++;
##                 flood_fill(row, col, marker, canvas);
##             }
##         }
##     }
##     return region_count;
## }

## $a0 = char marker
## $a1 = Canvas* canvas
## $v0 = int
## QtSpim -file common.s count_disjoint_regions_step_main.s count_disjoint_regions_step.s flood_fill.s lab8_given.s
.globl count_disjoint_regions_step
count_disjoint_regions_step:
        # Your code goes here :)
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
	for_loop_1:
		lw   $t1, 0($a1)						# $t1 = canvas->height
		bge  $t0, $t1, done						# row >= canvas->height, exit for loop
	
		li   $t1, 0								# $t1 = 0 // col
	for_loop_2:
		lw   $t2, 4($a1)						# $t2 = canvas->width
		bge  $t1, $t2, for_loop_2_end			# col >= canvas->width, exit for loop

		lw   $t2, 12($a1)						# $t2 = &(canvas->canvas)
		mul  $t3, $t0, 4						# Get the true "row" index
		add  $t2, $t2, $t3						# $t2 = &canvas->canvas[row]
		lw   $t2, 0($t2)						# $t2 = canvas->canvas[row]
		add  $t2, $t2, $t1						# $t2 = &canvas->canvas[row][col]

		lb   $t3, 0($t2)						# $t3 = canvas->canvas[row][col] // $t3 = curr_char

		## If statement ##
		lb   $t4, 8($a1)						# $t4 = canvas->pattern
		beq  $t3, $t4, false					# False if curr_char == canvas->pattern
		beq  $t3, $a0, false					# False if curr_char == marker

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
	false:
		add  $t1, $t1, 1						# $t1 = col++
		j    for_loop_2							# Return to for_loop_2
		## End for_loop_2
	for_loop_2_end:
		add  $t0, $t0, 1						# $t0 = row++
		j    for_loop_1							# Return to for_loop_1
		## End for_loop_1
	done:
		lw   $ra, 0($sp)						# Restore what everyone else uses
		lw   $s0, 4($sp)
		lw   $s1, 8($sp)
		lw   $s2, 12($sp)
		lw   $s3, 16($sp)
		lw   $s4, 20($sp)
		add  $sp, $sp, 24
        # Pray for me
        jr   $ra