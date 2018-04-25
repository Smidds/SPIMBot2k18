.data

# strings for printing
struct_msg:     .asciiz "Solution struct: "
len_msg:        .asciiz "  length = "
counts_msg:     .asciiz "  counts = {"
comma_msg:      .asciiz ", "
brkt_msg:       .asciiz "}"

# structs
lines:          .word   2       start_pos       end_pos
start_pos:      .word   2       10
end_pos:        .word   22      12

canvas:         .word   0       0       0       canv
canv:           .space  1024

solution:       .word   2       counts
counts:         .space  8

.text

## void test_count_disjoint_regions() {
##     Lines lines;
##     lines.num_lines = 2;
##     unsigned int start_pos[2] = {2, 10};
##     unsigned int end_pos[2] = {22, 14};
##     lines.coords[0] = start_pos;
##     lines.coords[1] = end_pos;
##     // Initialize Canvas.
##     Canvas canvas;
##     init_square_canvas(5, &canvas);
##     // Initialize Solution.
##     Solution solution;
##     solution.length = lines.num_lines;
##     solution.counts = new int [lines.num_lines];
##     count_disjoint_regions(&lines, &canvas, &solution);
##     print_canvas(&canvas);
##     cout << "Solution struct:" << endl;
##     cout << "  length = " << solution.length << endl;
##     cout << "  counts = {";
##     for (int i = 0; i < solution.length - 1; i++) {
##         cout << solution.counts[i] << ", ";
##     }
##     cout << solution.counts[solution.length - 1] << "}" << endl;
## }

MAIN_STK_SPC = 32
main:
        sub     $sp, $sp, MAIN_STK_SPC
        sw      $ra, 0($sp)
        sw      $s0, 4($sp)
        sw      $s1, 8($sp)
        sw      $s2, 12($sp)
        sw      $s3, 16($sp)
        sw      $s4, 20($sp)
        sw      $s5, 24($sp)
        sw      $s6, 28($sp)

        la      $s0, lines              # s0 = lines
        la      $s1, canvas             # s1 = canvas
        la      $s2, solution           # s2 = solution
        
        # lines is initialized above in the data segment
        
        li      $a0, 5
        move    $a1, $s1
        jal     init_square_canvas
        
        # solution is initialized above in the data segment
        
        move    $a0, $s0
        move    $a1, $s1
        move    $a2, $s2
        jal     count_disjoint_regions
        move    $a0, $s1
        jal     print_canvas

        la      $a0, struct_msg
        jal     print_string
        jal     print_newline
        la      $a0, len_msg
        jal     print_string
        lw      $a0, 0($s2)
        jal     print_int_and_space
        la      $a0, counts_msg
        jal     print_string

        li      $s3, 0
        lw      $s4, 0($s2)             # s4 = solution.length
        sub     $s4, $s4, 1
        lw      $s5, 4($s2)             # s5 = solution.counts
for_loop:
        bge     $s3, $s4, end_loop
        mul     $s6, $s3, 4
        add     $s6, $s6, $s5           # s6 = &solution.counts[i]
        lw      $a0, 0($s6)             # a0 = solution.counts[i]
        jal     print_int_and_space
        la      $a0, comma_msg
        jal     print_string
        addi    $s3, $s3, 1
        j       for_loop

end_loop:
        mul     $s6, $s3, 4
        add     $s6, $s6, $s5           # s6 = &solution.counts[solution.length-1]
        lw      $a0, 0($s6)             # a0 = solution.counts[solution.length-1]
        jal     print_int_and_space
        la      $a0, brkt_msg
        jal     print_string
        jal     print_newline
        
        lw      $ra, 0($sp)
        lw      $s0, 4($sp)
        lw      $s1, 8($sp)
        lw      $s2, 12($sp)
        lw      $s3, 16($sp)
        lw      $s4, 20($sp)
        lw      $s5, 24($sp)
        lw      $s6, 28($sp)
        add     $sp, $sp, MAIN_STK_SPC
        jr      $ra
