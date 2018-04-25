.data
canvas: .word   0       0       0      canv
canv: .space    1024

.text

##void test_draw_line() {
##    Canvas canvas;
##    init_square_canvas(5, &canvas);
##    // Draw a horizontal line.
##    draw_line(10, 14, &canvas);
##    // Draw a vertical line.
##    draw_line(2, 22, &canvas);
##    print_canvas(&canvas);
##}

MAIN_STK_SPC = 4
main:
        sub     $sp, $sp, MAIN_STK_SPC
        sw      $ra, 0($sp)
        la      $a1, canvas
        li      $a0, 5
        jal     init_square_canvas
        
        li      $a0, 10
        li      $a1, 14
        la      $a2, canvas
        jal     draw_line
        
        li      $a0, 2
        li      $a1, 22
        la      $a2, canvas
        jal     draw_line
        
        la      $a0, canvas
        jal     print_canvas

        lw      $ra, 0($sp)
        add     $sp, $sp, MAIN_STK_SPC
        jr      $ra
