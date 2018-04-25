.text

## struct Lines {
##     unsigned int num_lines;
##     // An int* array of size 2, where first element is an array of start pos
##     // and second element is an array of end pos for each line.
##     // start pos always has a smaller value than end pos.
##     unsigned int* coords[2];
## };
## 
## struct Solution {
##     unsigned int length;
##     int* counts;
## };
## 
## // Count the number of disjoint empty area after adding each line.
## // Store the count values into the Solution struct. 
## void count_disjoint_regions(const Lines* lines, Canvas* canvas,
##                             Solution* solution) {
##     // Iterate through each step.
##     for (unsigned int i = 0; i < lines->num_lines; i++) {
##         unsigned int start_pos = lines->coords[0][i];
##         unsigned int end_pos = lines->coords[1][i];
##         // Draw line on canvas.
##         draw_line(start_pos, end_pos, canvas);
##         // Run flood fill algorithm on the updated canvas.
##         // In each even iteration, fill with marker 'A', otherwise use 'B'.
##         unsigned int count =
##                 count_disjoint_regions_step('A' + (i % 2), canvas);
##         // Update the solution struct. Memory for counts is preallocated.
##         solution->counts[i] = count;
##     }
## }
###

# QtSpim -file common.s count_disjoint_regions_main.s count_disjoint_regions.s draw_line.s count_disjoint_regions_step.s flood_fill.s lab8_given.s

## $a0 = Lines* lines
## $a1 = Canvas* canvas
## $a2 = Solution* solution

.globl count_disjoint_regions
count_disjoint_regions:
        # Your code goes here :)
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
	for_loop:
		lw   $t1, 0($a0)				# $t1 = lines->num_lines
		bge  $t0, $t1, done				# Exit if i >= lines->num_lines

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
		j   for_loop
	done:
		lw   $ra, 0($sp)
		lw   $s0, 4($sp)
		lw   $s1, 8($sp)
		lw   $s2, 12($sp)
		lw   $s3, 16($sp)
		add  $sp, $sp, 20
        # Pray for me
        jr   $ra
