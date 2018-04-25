.data
pound:                  .ascii "#"
CANVAS_STRUCT:          .asciiz "Canvas struct:\n"
HEIGHT:                 .asciiz "  height = "
WIDTH:                  .asciiz "  width = "
PATTERN:                .asciiz "  pattern = "
CANVAS:                 .asciiz "  canvas = "
CANVAS_LINE_OFFSET:     .asciiz "  " 


.text

###########################################################
# Initialize Canvas struct of given size.
# arguments $a0: size of the canvas
#           $a1: Canvas*
#
## void init_square_canvas(unsigned int size, Canvas* canvas) {
##     canvas->width = size;
##     canvas->height = size;
##     canvas->pattern = '#';
##     canvas->canvas = new char* [size];
##     for (int i = 0; i < canvas->height; i++) {
##         canvas->canvas[i] = new char [size + 1];
##         for (int j = 0; j < size; j++) {
##             canvas->canvas[i][j] = '.';
##         }
##         canvas->canvas[i][size] = '\0';
##     }
## }

.globl init_square_canvas
init_square_canvas:
        sub     $sp, $sp, 32
        sw      $ra, 0($sp)
        sw      $s0, 4($sp)
        sw      $s1, 8($sp)
        sw      $s2, 12($sp)
        sw      $s3, 16($sp)
        sw      $s4, 20($sp)
        sw      $s5, 24($sp)
        sw      $s6, 28($sp)

        move    $s0, $a0
        move    $s1, $a1

        sw      $s0, 0($s1)             # canvas->height = size
        sw      $s0, 4($s1)             # canvas->width = size
        li      $t0, 35                 # 35 is ascii code for "#"
        sb      $t0, 8($s1)             # canvas->pattern = '#'

        add     $s3, $s0, 1             # $s3 = size + 1

        mul     $a0, $s0, 4             # allocate space for <size> char*'s
        jal     malloc
        sw      $v0, 12($s1)            # canvas->canvas = newly allocated mem
        lw      $s2, 12($s1)            # $s2 = canvas->canvas
#       move    $s2, $v0                # functionally equivalent but um...

        li      $s4, 0                  # $s4 = i
isc_outer_for_loop:
        bge     $s4, $s0, isc_outer_end
        mul     $s6, $s4, 4
        add     $s6, $s6, $s2           # &canvas->canvas[i]
        move    $a0, $s3                # malloc size + 1 bytes
        jal     malloc
        sw      $v0, 0($s6)             # canvas->canvas[i] = new char [size+1]

        li      $s5, 0                  # $s5 = j
isc_inner_for_loop:
        bge     $s5, $s0, isc_inner_end
        lw      $t0, 0($s6)             # canvas->canvas[i]
        add     $t0, $t0, $s5           # &canvas->canvas[i][j]
        li      $t1, 46                 # 46 is ascii code for "."
        sb      $t1, 0($t0)             # canvas->canvas[i][j] = '.'

        add     $s5, $s5, 1
        j       isc_inner_for_loop
isc_inner_end:
        lw      $t0, 0($s6)             # canvas->canvas[i]
        add     $t0, $t0, $s0           # &canvas->canvas[i][size]
        sb      $0, 0($t0)              # canvas->canvas[i][size] = 0

        add     $s4, $s4, 1
        j       isc_outer_for_loop
isc_outer_end:
        lw      $ra, 0($sp)
        lw      $s0, 4($sp)
        lw      $s1, 8($sp)
        lw      $s2, 12($sp)
        lw      $s3, 16($sp)
        lw      $s4, 20($sp)
        lw      $s5, 24($sp)
        lw      $s6, 28($sp)
        add     $sp, $sp, 32

        jr      $ra


###########################################################
#  Print Canvas Struct.
#  argument $a0: Canvas*
#  returns:  void

.globl print_canvas
print_canvas:
        sub     $sp, $sp, 20
        sw      $ra, 0($sp)
        sw      $s0, 4($sp)
        sw      $s1, 8($sp)
        sw      $s2, 12($sp)
        sw      $s3, 16($sp)

        move    $s0, $a0

        la      $a0, CANVAS_STRUCT
        jal     print_string    

        la      $a0, HEIGHT
        jal     print_string    
        lw      $a0, 0($s0)             # canvas->height
        jal     print_int_and_space
        jal     print_newline

        la      $a0, WIDTH
        jal     print_string    
        lw      $a0, 4($s0)             # canvas->width
        jal     print_int_and_space
        jal     print_newline

        la      $a0, PATTERN 
        jal     print_string    
        lbu     $a0, 8($s0)             # canvas->pattern
        jal     print_char_and_space
        jal     print_newline

        la      $a0, CANVAS 
        jal     print_string
        jal     print_newline

        li      $s1, 0
        lw      $s2, 0($s0)             # canvas->height
        lw      $s3, 12($s0)            # canvas->canvas
pc_for_loop:
        bge     $s1, $s2, pc_end
        la      $a0, CANVAS_LINE_OFFSET
        jal     print_string    
        mul     $t0, $s1, 4
        add     $t0, $s3, $t0           # &canvas->canvas[i]
        lw      $a0, 0($t0)             # canvas->canvas[i]
        jal     print_string
        add     $s1, $s1, 1
        jal     print_newline
        j       pc_for_loop
pc_end:
        lw      $ra, 0($sp)
        lw      $s0, 4($sp)
        lw      $s1, 8($sp)
        lw      $s2, 12($sp)
        lw      $s3, 16($sp)
        add     $sp, $sp, 20

        jr      $ra
