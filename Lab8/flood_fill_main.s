.data
canvas: .word   0       0       0      canv
canv:   .space	1024

.text

##void test_flood_fill() {
##    Canvas canvas;
##    init_square_canvas(5, &canvas);
##    // Draw lines.
##    for (int i = 0; i < 5; i++) {
##        canvas.canvas[i][2] = canvas.pattern;
##        canvas.canvas[2][i] = canvas.pattern;
##    }
##    // This call should not modify the canvas as canvas[2][2] is '#'.
##    flood_fill(2, 2, 'A', &canvas);
##    print_canvas(&canvas);
##    // This call should mark the upper left region as 'A's.
##    flood_fill(0, 0, 'A', &canvas);
##    print_canvas(&canvas);
##}

MAIN_STK_SPC = 8
main:
        sub     $sp, $sp, MAIN_STK_SPC
        sw      $ra, 0($sp)
        sw      $s0, 4($sp)
        
        la      $s0, canvas     # s0 = canvas
        move	$a1, $s0
        li      $a0, 5
        jal     init_square_canvas
        
        li      $t0, 0          # t0 = i = 0
        lw      $t1, 12($s0)    # t1 = &canvas.canvas[0]
        lbu     $t2, 8($s0)     # t2 = canvas.pattern
for_loop:
        bge     $t0, 5, end_for
        mul     $t3, $t0, 4
        add     $t3, $t3, $t1   # t3 = &canvas.canvas[i]
        lw      $t3, 0($t3)     # t3 = canvas.canvas[i]
        add     $t3, $t3, 2     # t3 = &canvas.canvas[i][2]
        sb      $t2, 0($t3)     # canvas.canvas[i][2] = canvas.pattern;
        add     $t3, $t1, 8     # t3 = &canvas.canvas[2]
        lw      $t3, 0($t3)     # t3 = canvas.canvas[2]
        add     $t4, $t3, $t0   # t4 = &canvas.canvas[2][i]
        sb      $t2, 0($t4)     # canvas.canvas[2][i] = canvas.pattern;
        addi    $t0, $t0, 1     # i++
        j       for_loop
        
end_for:        
        li      $a0, 2
        li      $a1, 2
        li      $a2, 65
        move    $a3, $s0
        jal     flood_fill
        
        la      $a0, canvas
        jal     print_canvas
        
        li      $a0, 0
        li      $a1, 0
        li      $a2, 65
        move    $a3, $s0
        jal     flood_fill
        
        la      $a0, canvas
        jal     print_canvas
        
        li      $a0, 0
        li      $a1, 3
        li      $a2, 65
        move    $a3, $s0
        jal     flood_fill
        
        la      $a0, canvas
        jal     print_canvas

        li      $a0, 4
        li      $a1, 4
        li      $a2, 65
        move    $a3, $s0
        jal     flood_fill
        
        la      $a0, canvas
        jal     print_canvas

        li      $a0, 4
        li      $a1, 0
        li      $a2, 65
        move    $a3, $s0
        jal     flood_fill
        
        la      $a0, canvas
        jal     print_canvas

        li      $a0, 5
        li      $a1, 5
        li      $a2, 65
        move    $a3, $s0
        jal     flood_fill
        
        la      $a0, canvas
        jal     print_canvas

        lw      $ra, 0($sp)
        lw      $s0, 4($sp)
        add     $sp, $sp, MAIN_STK_SPC
        jr      $ra
