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
## // Mark an empty region as visited on the canvas using flood fill algorithm.
## void flood_fill(int row, int col, unsigned char marker, Canvas* canvas) {
##     // Check the current position is valid.
##     if (row < 0 || col < 0 ||
##         row >= canvas->height || col >= canvas->width) {
##         return;
##     }
##     unsigned char curr = canvas->canvas[row][col];
##     if (curr != canvas->pattern && curr != marker) {
##         // Mark the current pos as visited.
##         canvas->canvas[row][col] = marker;
##         // Flood fill four neighbors.
##         flood_fill(row - 1, col, marker, canvas);
##         flood_fill(row, col + 1, marker, canvas);
##         flood_fill(row + 1, col, marker, canvas);
##         flood_fill(row, col - 1, marker, canvas);
##     }
## }

## struct Canvas {
##     unsigned int height;
##     unsigned int width;
##     unsigned char pattern;
##     char** canvas;
## };

## $a0 = int row
## $a1 = int col
## $a2 = char marker
## $a3 = Canvas* canvas

# QtSpim -file common.s flood_fill_main.s flood_fill.s lab8_given.s
.globl flood_fill
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
