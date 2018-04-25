.data

# strings for printing
print_msg: .asciiz "#disjoint regions = "

# structs
canvas: .word   0       0       0       canv
canv:   .space  1024

.text
##void test_count_disjoint_regions_step() {
##    Canvas canvas;
##    init_square_canvas(3, &canvas);
##    // Draw lines.
##    for (int i = 0; i < 3; i++) {
##        canvas.canvas[i][1] = canvas.pattern;
##        canvas.canvas[1][i] = canvas.pattern;
##    }
##    // The test square canvas has a vertical line at column 2 and
##    // a horizontal line at row 2, so there are 4 disjoint regions.
##    unsigned int count = count_disjoint_regions_step('A', &canvas);
##    print_canvas(&canvas);
##    cout << "#disjoint regions = " << count << endl;
##}

MAIN_STK_SPC = 28
main:
        sub     $sp, $sp, MAIN_STK_SPC
        sw      $ra, 0($sp)
        sw      $s0, 4($sp)
        sw      $s1, 8($sp)
        sw      $s2, 12($sp)
        sw      $s3, 16($sp)
        sw      $s4, 20($sp)
        sw      $s5, 24($sp)
 
        la      $s0, canvas
        li      $a0, 3
        move    $a1, $s0
        jal     init_square_canvas

        li      $s1, 0
        lbu     $s2, 8($s0)         # s2 = canvas.pattern
        lw      $s3, 12($s0)        # s3 = canvas.canvas
for_loop:
        bge     $s1, 3, end_for
        mul     $s4, $s1, 4
        add     $s4, $s4, $s3       # s4 = &canvas.canvas[i]
        lw      $s5, 0($s4)         # s5 = canvas.canvas[i]
        addi    $s5, $s5, 1         # s5 = &canvas.canvas[i][1]
        sb      $s2, 0($s5)         # canvas.canvas[i][1] = canvas.pattern
        addi    $s4, $s3, 4         # &canvas.canvas[1]
        lw      $s5, 0($s4)         # canvas.canvas[1]
        add     $s5, $s5, $s1       # &canvas.canvas[1][i]
        sb      $s2, 0($s5)         # canvas.canvas[1][i] = canvas.pattern
        addi    $s1, $s1, 1
        j       for_loop

end_for:
        li      $a0, 65
        move    $a1, $s0
        jal     count_disjoint_regions_step
        move    $s4, $v0            # s4 = count
        move    $a0, $s0
        jal     print_canvas
        la      $a0, print_msg
        jal     print_string
        move    $a0, $s4
        jal     print_int_and_space
        jal     print_newline

        lw      $ra, 0($sp)
        lw      $s0, 4($sp)
        lw      $s1, 8($sp)
        lw      $s2, 12($sp)
        lw      $s3, 16($sp)
        lw      $s4, 20($sp)
        lw      $s5, 24($sp)
        add     $sp, $sp, MAIN_STK_SPC
        jr      $ra
