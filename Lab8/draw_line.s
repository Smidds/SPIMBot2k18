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
## // Draw a line on canvas from start_pos to end_pos.
## // start_pos will always be smaller than end_pos.
## void draw_line(unsigned int start_pos, unsigned int end_pos,
##                Canvas* canvas) {
##     unsigned int width = canvas->width;
##     unsigned int step_size = 1;
##     // Check if the line is vertical.
##     if (end_pos - start_pos >= width) {
##         step_size = width;
##     }
##     // Update the canvas with the new line.
##     for (int pos = start_pos; pos != end_pos + step_size;
##              pos += step_size) {
##         canvas->canvas[pos / width][pos % width] = canvas->pattern;
##     }
## }

##    QtSpim -file common.s draw_line_main.s draw_line.s lab8_given.s

##
## $a0 = start_pos
## $a1 = end_pos
## $a2 = canvas
##

.globl draw_line
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
