# syscall constants
PRINT_STRING            = 4
PRINT_CHAR              = 11
PRINT_INT               = 1

# memory-mapped I/O
VELOCITY                = 0xffff0010
ANGLE                   = 0xffff0014
ANGLE_CONTROL           = 0xffff0018

BOT_X                   = 0xffff0020
BOT_Y                   = 0xffff0024

TIMER                   = 0xffff001c

PRINT_INT_ADDR          = 0xffff0080
PRINT_FLOAT_ADDR        = 0xffff0084
PRINT_HEX_ADDR          = 0xffff0088

ASTEROID_MAP            = 0xffff0050
COLLECT_ASTEROID        = 0xffff00c8

STATION_LOC             = 0xffff0054
DROPOFF_ASTEROIDS       = 0xffff005c

GET_CARGO               = 0xffff00c4

# interrupt constants
BONK_INT_MASK           = 0x1000
BONK_ACK                = 0xffff0060

TIMER_INT_MASK          = 0x8000
TIMER_ACK               = 0xffff006c

STATION_ENTER_INT_MASK  = 0x400
STATION_ENTER_ACK       = 0xffff0058

STATION_EXIT_INT_MASK   = 0x2000
STATION_EXIT_ACK        = 0xffff0064


.data
# put your data things here

.align 2
asteroid_map_address: .space 1024

.text
main:
        # put your code here :)
        sub        $sp, $sp, 20        # get some space
        sw         $s0, 0($sp)         #
        sw         $s1, 4($sp)         #
        sw         $s2, 8($sp)         #
        sw         $s3, 12($sp)        #
        sw         $ra, 16($sp)        #

        jal        findNearest         # findNearest
        move       $s2, $v0            # $a0 = $v0

        lw         $s0, GET_CARGO       # $s0 = cargo_amount
        add        $s0, $s0, $v1        # $s0 = cargo_amount + best_points
        li         $s1, 126             # $s1 = 126
        bge        $s0, $s1, enable_int # if $s0 >= $s1 then enable_int
        li         $s0, 0               # $s0 = 0
        mtc0       $s0, $12             # disable to global interrupt signals

        move       $a0, $s2             # $a0 = $s0
        jal        chase                  # chase
        sw         $s0, COLLECT_ASTEROID  #


        j          end                    # jump to end

enable_int:
        li        $s0, STATION_EXIT_INT_MASK        # $s0 = STATION_EXIT_INT_MASK
        or        $s0, $s0, STATION_ENTER_INT_MASK  # $s0 += STATION_ENTER_INT_MASK
        or        $s0, $s0, BONK_INT_MASK
        or        $s0, $s0, 1
        mtc0      $s0, $12

end:
        add        $sp, $sp, 20        # restore
        lw         $s0, 0($sp)         #
        lw         $s1, 4($sp)         #
        lw         $s2, 8($sp)         #
        lw         $s3, 12($sp)        #
        lw         $ra, 16($sp)        #
        # note that we infinite loop to avoid stopping the simulation early
        j       main


#-------------------- chase function and standby function --------------------#

chase:
        li        $t0, 10        # $t0 = 10
        sw        $t0, VELOCITY  # $a0 should be the address to chase
        move            $t0, $a0        # $t0 = $a0

c_getToX:
        lw         $t1, BOT_X                     # get the BOT_X
        srl        $t2, $t0, 16                   # $t2 = asteroid.x
        beq        $t1, $t2, c_getToY               # if BOT_X == asteroid.x then getToY
        blt        $t1, $t2, c_right                # if BOT_X < asteroid.x then right

        li         $t3, 180                       # $t3 = degrees = 180
        sw         $t3, ANGLE                     # set ANGLE
        li         $t3, 1                         # $t3 = ANGLE_CONTROL = 1
        sw         $t3, ANGLE_CONTROL             # set ANGLE_CONTROL

        j          c_getToX                         # jump to getToX

c_right:
        li         $t3, 0                         # $t3 = 0
        sw         $t3, ANGLE                     # set ANGLE
        li         $t3, 1                         # $t3 = 1
        sw         $t3, ANGLE_CONTROL             # set ANGLE_CONTROL

        j          c_getToX                         # jump to getToX

c_getToY:
        lw         $t1, BOT_Y                     # get the BOT_Y
        and        $t2, $t0, 0x0000ffff           # $t2 = asteroid.y
        beq        $t1, $t2, c_adjust_x             # if BOT_Y == asteroid.y then adjust_x
        blt        $t1, $t2, c_down                 # if BOT_Y < asteroid.y then down

        li         $t3, 270                       # $t3 = 270
        sw         $t3, ANGLE                     # set ANGLE
        li         $t3, 1                         # $t3 = 1
        sw         $t3, ANGLE_CONTROL             # set ANGLE_CONTROL

        j          c_getToX                         # jump to getToY

c_down:
        li         $t3, 90                        # $t3 = 90
        sw         $t3, ANGLE                     # set ANGLE
        li         $t3, 1                         # $t3 = 1
        sw         $t3, ANGLE_CONTROL             # set ANGLE_CONTROL

        j          c_getToX                         # jump to getToY

c_adjust_x:
        lw         $t1, BOT_X                     # get the BOT_X
        srl        $t2, $t0, 16                   # $t2 = asteroid.x
        beq        $t1, $t2, c_end                  # if BOT_X == asteroid.x then getToY
        blt        $t1, $t2, c_adjust_x_right       # if BOT_X < asteroid.x then right

        li         $t3, 180                       # $t3 = degrees = 180
        sw         $t3, ANGLE                     # set ANGLE
        li         $t3, 1                         # $t3 = ANGLE_CONTROL = 1
        sw         $t3, ANGLE_CONTROL             # set ANGLE_CONTROL

        j          c_adjust_x                       # jump to adjust_x

c_adjust_x_right:
        li         $t3, 0                         # $t3 = 0
        sw         $t3, ANGLE                     # set ANGLE
        li         $t3, 1                         # $t3 = 1
        sw         $t3, ANGLE_CONTROL             # set ANGLE_CONTROL

        j          c_adjust_x                       # jump to adjust_x

c_end:
        jr          $ra                           # return




findFav:                # after this call $v0 should contain the (x, y), other $t is free to use
        li         $t0, 0                         # $t0 = (x, y) = 0
        li         $t4, 0                         # $t4 = best_points = 0

        li         $t5, 0                         # $t5 = i = 0

for_loop:
        la         $t2, asteroid_map_address      # $t2 = asteroid_map_address
        sw         $t2, ASTEROID_MAP              # $t2 should be the address of current asteroid map
        lw         $t3, 0($t2)                    # $t3 = length
        add        $t6, $t2, 4                    # $t6 should be the start of asteroid array
        bge        $t5, $t3, end_findFav        # if i >= length then getToX, because we should have the best
                                                # target now stored in $v0

        mul        $t7, $t5, 8                    # $t7 = i * 8
        add        $t7, $t7, $t6                  # $t7 = &asteroid[i]
        lw         $t8, 4($t7)                    # $t8 = asteroid[i].points

        ble        $t8, $t4, looping              # if asteroid[i].points <= best_points then looping

        lw         $t9, 0($t7)                    # $t9 = asteroid[i].(x, y)
        srl        $t9, $t9, 8                    # $t9 = asteroid[i].x
        li         $t1, 40                        # $t1 = 40
        ble        $t9, $t1, looping              # if asteroid[i].x <= 40 then looping
        # else set the current asteroid as the fav
        lw         $t4, 4($t7)                    # $t4 = best_points = asteroid[i].points
        lw         $t0, 0($t7)                    # $t0 = asteroid[i].(x, y)
        move       $v0, $t0                       # $v0 = $t0 = (x, y) of fav asteroid
        move       $v1, $t4                       # $v1 = $t4 = best_points

looping:
        add        $t5, $t5, 1                    # i++
        j          for_loop                       # loop

end_findFav:
        jr         $ra                            # return


findNearest:
        li          $t0, 0        # $t0 = 0
        mtc0        $t0, $12        # disable interrupt for now

        la          $t0, asteroid_map_address       # $t0 contains the asteroidMap
        sw          $t0, ASTEROID_MAP               #
        lw          $t1, 0($t0)                     # $t1 = length
        add         $t2, $t0, 4                     # $t2 = &asteroid[]

        li          $t3, 0                          # $t3 = currentBest = (0, 0)
        li          $t4, 99999                      # $t4 = currentBestDist = 99999
        li          $t5, 0                          # $t5 = i = 0
        li          $t6, 0                          # $t6 = distance = 0
        li          $v1, 0                          # $v1 = best_points = 0

FN_loop:
        bge         $t5, $t1, FN_end                # if i >= length then FN_end
        mul         $t7, $t5, 8                     # $t7 = i * 8
        add         $t7, $t7, $t2                   # $t7 = &asteroid[i]
        lw          $t8, 0($t7)                     # $t8 = asteroid[i].(x, y)
        srl         $t6, $t8, 16                    # distance = asteroid[i].x
        lw          $t0, BOT_X                      # $t0 = BOT_X
        sub         $t6, $t6, $t0                   # distance = asteroid[i].x - BOT_X
        mul         $t6, $t6, $t6                   # distance = (asteroid[i].x - BOT_X)^2
        and         $t9, $t8, 0x0000ffff            # $t9 = asteroid[i].y
        lw          $t0, BOT_Y                      # $t0 = BOT_Y
        sub         $t9, $t9, $t0                   # $t9 = asteroid[i].y - BOT_Y
        mul         $t9, $t9, $t9                   # $t9 = (asteroid[i].y - BOT_Y)^2
        add         $t6, $t6, $t9                   # $t6 = distance = (asteroid[i].x - BOT_X)^2 + (asteroid[i].y - BOT_Y)^2

        bge         $t6, $t4, after_if              # if distance >= currentBestDist then after_if
        srl         $t9, $t8, 16                    # $t9 = asteroid[i].x
        ble         $t9, 40, after_if               # if asteroid[i].x <= 40 then after_if

        move        $t4, $t6                        # currentBestDist = distance
        move        $t3, $t8                        # currentBest = asteroid[i].(x, y)
        lw          $v1, 4($t7)                     # $v1 = best_points

after_if:
        add         $t5, $t5, 1                     # i++
        j           FN_loop                         # jump to FN_loop

FN_end:
        move        $v0, $t3                        # $v0 = $t3
        #
        # li          $t0, STATION_EXIT_INT_MASK        # $s0 = STATION_EXIT_INT_MASK
        # or          $t0, $t0, BONK_INT_MASK
        # or          $t0, $t0, 1
        # mtc0        $t0, $12

        jr          $ra                             # return


#--------------------------- interrupt handler data ---------------------------#
.kdata
someSpace:          .space 8    # some space for 2 registers
non_intrpt_str:	.asciiz "Non-interrupt exception\n"
unhandled_str:	.asciiz "Unhandled interrupt type\n"

.ktext  0x80000180
interrupt_handler:
.set noat
        move        $k1, $at             # save $at
.set at
        la          $k0, someSpace       #
        sw          $a0, 0($k0)          # save $a0
        sw          $a1, 4($k0)          # save $a1

        mfc0        $k0, $13             # get cause register
        srl	        $a0, $k0, 2
    	and	        $a0, $a0, 0xf		 # ExcCode field
    	bne	        $a0, 0, non_intrpt

interrupt_dispatch:                      # interrupt dispatch center
        mfc0        $k0, $13             # $k0 = cause register
        beq         $k0, $zero, done     # if cause register == 0 then done

        and         $a0, $k0, STATION_EXIT_INT_MASK     # is there an exit interrupt?
        bne         $a0, $zero, exit_int                # if $a0 != $zero then exit_int

        and         $a0, $k0, STATION_ENTER_INT_MASK    # is there an enter interrupt?
        bne         $a0, $zero, enter_int               # if $a0 != $zero then enter_int

        and         $a0, $k0, BONK_INT_MASK
        bne         $a0, $zero, bonk_interrupt          # if $a0 != $zero then bonk_interrupt

        li	$v0, PRINT_STRING	         # Unhandled interrupt types
    	la	$a0, unhandled_str
    	syscall
        j           done                 # jump to done

exit_int:
        sw          $a1, STATION_EXIT_ACK        # Ack it
        # jal         standby                      # go to (200, 200)

        j           interrupt_dispatch           # jump to interrupt_dispatch

enter_int:
        sw          $a1, STATION_ENTER_ACK        # Ack it

chase_station:
        li        $t0, 10               # $t0 = 10
        sw        $t0, VELOCITY         #

        lw          $t0, STATION_LOC        #
        srl         $t1, $t0, 16            # $t1 = STATION_LOC.x
        and         $t2, $t0, 0x0000ffff    # $t2 = STATION_LOC.y
        lw          $t3, BOT_X              # $t3 = BOT_X
        lw          $t4, BOT_Y              # $t4 = BOT_Y


        bne         $t1, $t3, goEW          # if station.x != bot.x then goEW
        bne         $t2, $t4, goSN          # if station.y != bot.y then goSN
        sw          $t0, DROPOFF_ASTEROIDS  # now the bot should overlap the station
        j           cs_end                  # jump to cs_end

goEW:
        bgt        $t1, $t3, goEast        # if station.x > bot.x then goEast
        # otherwise goWest
        li        $t0, 180                 # $t0 = 180
        sw        $t0, ANGLE               #
        li        $t0, 1                   # $t0 = 1
        sw        $t0, ANGLE_CONTROL       #
        j         cs_loop                  # jump to cs_loop

goEast:
        li        $t0, 0                 # $t0 = 180
        sw        $t0, ANGLE               #
        li        $t0, 1                   # $t0 = 1
        sw        $t0, ANGLE_CONTROL       #
        j         cs_loop                  # jump to cs_loop

goSN:
        bgt        $t2, $t4, goSouth      # if station.y > bot.y then goSouth
        # otherwise goNorth
        li        $t0, 270                 # $t0 = 180
        sw        $t0, ANGLE               #
        li        $t0, 1                   # $t0 = 1
        sw        $t0, ANGLE_CONTROL       #
        j         cs_loop                  # jump to cs_loop

goSouth:
        li        $t0, 90                 # $t0 = 180
        sw        $t0, ANGLE               #
        li        $t0, 1                   # $t0 = 1
        sw        $t0, ANGLE_CONTROL       #
        j         cs_loop                  # jump to cs_loop

cs_loop:
        j         chase_station             # jump to chase_station
cs_end:
        j           interrupt_dispatch            # jump to interrupt_dispatch

bonk_interrupt:
        sw          $a1, BONK_ACK               # acknowledge interrupt
        # jal         standby                     # jump to standby and save position to $ra
standby:
        li        $t0, 10               # $t0 = 10
        sw        $t0, VELOCITY         #

        li          $t0, 0x960032           # (150, 50)
        srl         $t1, $t0, 16            # $t1 = STATION_LOC.x
        and         $t2, $t0, 0x0000ffff    # $t2 = STATION_LOC.y
        lw          $t3, BOT_X              # $t3 = BOT_X
        lw          $t4, BOT_Y              # $t4 = BOT_Y
        li          $t5, 290                # $t5 = 290
        bgt         $t1, $t5, sb_end        # if station.x > 290 then


        bne         $t1, $t3, sb_goEW          # if station.x != bot.x then goEW
        bne         $t2, $t4, sb_goSN          # if station.y != bot.y then goSN
        j           sb_end                  # jump to cs_end

sb_goEW:
        bgt        $t1, $t3, sb_goEast        # if station.x > bot.x then goEast
        # otherwise goWest
        li        $t0, 180                 # $t0 = 180
        sw        $t0, ANGLE               #
        li        $t0, 1                   # $t0 = 1
        sw        $t0, ANGLE_CONTROL       #
        j         sb_loop                  # jump to cs_loop

sb_goEast:
        li        $t0, 0                 # $t0 = 180
        sw        $t0, ANGLE               #
        li        $t0, 1                   # $t0 = 1
        sw        $t0, ANGLE_CONTROL       #
        j         sb_loop                  # jump to cs_loop

sb_goSN:
        bgt        $t2, $t4, sb_goSouth      # if station.y > bot.y then goSouth
        # otherwise goNorth
        li        $t0, 270                 # $t0 = 180
        sw        $t0, ANGLE               #
        li        $t0, 1                   # $t0 = 1
        sw        $t0, ANGLE_CONTROL       #
        j         sb_loop                  # jump to cs_loop

sb_goSouth:
        li        $t0, 90                 # $t0 = 180
        sw        $t0, ANGLE               #
        li        $t0, 1                   # $t0 = 1
        sw        $t0, ANGLE_CONTROL       #
        j         sb_loop                  # jump to cs_loop

sb_loop:
        j         standby             # jump to chase_station
sb_end:
        li        $t0, 0        # $t0 = 180
        sw        $t0, ANGLE        #
        li        $t0, 1        # $t0 = 1
        sw        $t0, ANGLE_CONTROL        #

        li        $t0, 2        # $t0 = 1
        sw        $t0, VELOCITY        #

        # jr        $ra                       # jump to
        j           interrupt_dispatch              # see if other interrupts are waiting

non_intrpt:				# was some non-interrupt
	   li	            $v0, PRINT_STRING
	   la	            $a0, non_intrpt_str
	   syscall				# print out an error message
	# fall through to done

done:
	   la	            $k0, someSpace
	   lw	            $a0, 0($k0)		# Restore saved registers
	   lw	            $a1, 4($k0)
.set noat
	   move	        $at, $k1		# Restore $at
.set at
	   eret

# standby:
#         li        $t0, 10               # $t0 = 10
#         sw        $t0, VELOCITY         #
#
#         li          $t0, 0xc8005a           # (200, 90)
#         srl         $t1, $t0, 16            # $t1 = STATION_LOC.x
#         and         $t2, $t0, 0x0000ffff    # $t2 = STATION_LOC.y
#         lw          $t3, BOT_X              # $t3 = BOT_X
#         lw          $t4, BOT_Y              # $t4 = BOT_Y
#         li          $t5, 290                # $t5 = 290
#         bgt         $t1, $t5, sb_end        # if station.x > 290 then
#
#
#         bne         $t1, $t3, sb_goEW          # if station.x != bot.x then goEW
#         bne         $t2, $t4, sb_goSN          # if station.y != bot.y then goSN
#         j           sb_end                  # jump to cs_end
#
# sb_goEW:
#         bgt        $t1, $t3, sb_goEast        # if station.x > bot.x then goEast
#         # otherwise goWest
#         li        $t0, 180                 # $t0 = 180
#         sw        $t0, ANGLE               #
#         li        $t0, 1                   # $t0 = 1
#         sw        $t0, ANGLE_CONTROL       #
#         j         sb_loop                  # jump to cs_loop
#
# sb_goEast:
#         li        $t0, 0                 # $t0 = 180
#         sw        $t0, ANGLE               #
#         li        $t0, 1                   # $t0 = 1
#         sw        $t0, ANGLE_CONTROL       #
#         j         sb_loop                  # jump to cs_loop
#
# sb_goSN:
#         bgt        $t2, $t4, sb_goSouth      # if station.y > bot.y then goSouth
#         # otherwise goNorth
#         li        $t0, 270                 # $t0 = 180
#         sw        $t0, ANGLE               #
#         li        $t0, 1                   # $t0 = 1
#         sw        $t0, ANGLE_CONTROL       #
#         j         sb_loop                  # jump to cs_loop
#
# sb_goSouth:
#         li        $t0, 90                 # $t0 = 180
#         sw        $t0, ANGLE               #
#         li        $t0, 1                   # $t0 = 1
#         sw        $t0, ANGLE_CONTROL       #
#         j         sb_loop                  # jump to cs_loop
#
# sb_loop:
#         j         standby             # jump to chase_station
# sb_end:
#         li        $t0, 0        # $t0 = 180
#         sw        $t0, ANGLE        #
#         li        $t0, 1        # $t0 = 1
#         sw        $t0, ANGLE_CONTROL        #
#
#         li        $t0, 2        # $t0 = 1
#         sw        $t0, VELOCITY        #
#
#         jr        $ra                       # jump to
#
#
# chase_station:
#         li        $t0, 10               # $t0 = 10
#         sw        $t0, VELOCITY         #
#
#         lw          $t0, STATION_LOC        #
#         srl         $t1, $t0, 16            # $t1 = STATION_LOC.x
#         and         $t2, $t0, 0x0000ffff    # $t2 = STATION_LOC.y
#         lw          $t3, BOT_X              # $t3 = BOT_X
#         lw          $t4, BOT_Y              # $t4 = BOT_Y
#         # li          $t5, 290                # $t5 = 290
#         # bgt         $t1, $t5, cs_end        # if station.x > 290 then
#
#
#         bne         $t1, $t3, goEW          # if station.x != bot.x then goEW
#         bne         $t2, $t4, goSN          # if station.y != bot.y then goSN
#         sw          $t0, DROPOFF_ASTEROIDS  # now the bot should overlap the station
#         j           cs_end                  # jump to cs_end
#
# goEW:
#         bgt        $t1, $t3, goEast        # if station.x > bot.x then goEast
#         # otherwise goWest
#         li        $t0, 180                 # $t0 = 180
#         sw        $t0, ANGLE               #
#         li        $t0, 1                   # $t0 = 1
#         sw        $t0, ANGLE_CONTROL       #
#         j         cs_loop                  # jump to cs_loop
#
# goEast:
#         li        $t0, 0                 # $t0 = 180
#         sw        $t0, ANGLE               #
#         li        $t0, 1                   # $t0 = 1
#         sw        $t0, ANGLE_CONTROL       #
#         j         cs_loop                  # jump to cs_loop
#
# goSN:
#         bgt        $t2, $t4, goSouth      # if station.y > bot.y then goSouth
#         # otherwise goNorth
#         li        $t0, 270                 # $t0 = 180
#         sw        $t0, ANGLE               #
#         li        $t0, 1                   # $t0 = 1
#         sw        $t0, ANGLE_CONTROL       #
#         j         cs_loop                  # jump to cs_loop
#
# goSouth:
#         li        $t0, 90                 # $t0 = 180
#         sw        $t0, ANGLE               #
#         li        $t0, 1                   # $t0 = 1
#         sw        $t0, ANGLE_CONTROL       #
#         j         cs_loop                  # jump to cs_loop
#
# cs_loop:
#         j         chase_station             # jump to chase_station
# cs_end:
#         jr        $ra                       # jump to

#----------------------- end of interrupt handler data -----------------------#
