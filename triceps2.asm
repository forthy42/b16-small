\ triceps2
\ -*- forth-mode -*-
include regmap.asm

$0000 org
\ motor angle 0-ffff for 0-180°
| pos1 0 ,
| pos2 0 ,
| pos3 0 ,
\ position, in mm relative to north tower, floor level
\ (front/right/up is positive
| x 0 ,
| y 0 ,
| z 0 ,
\ position transformation left tower
| xl 0 ,
| yl 0 ,
| scl 0 , \ string circle radius
\ position transformation right tower
| xr 0 ,
| yr 0 ,
| scr 0 , \ string circle radius

$2000 org
include b16-prim.fs \ Extentions fuer b16

include b16-db.fs   \ RAM Debugging Interface

include b16-sqrt.fs

: init-port
   $1111 # GPIO02T # !
   $0000 # GPIO02  # ! ;

GPIO02 Value port

: after ( ms -- dtime )
    #50000 # mul
: tick-after ( ticks -- dtime )
    TVAL1 # @  TVAL0 # @ d+ ;

: µafter ( µs -- dtime )
    #50 # mul tick-after ;

\ min: 740, max: 2250
: ausschlag ( 0-ffff -- dtime )
    #37750 # mul nip
    #20000 # + dup + 0 # dup +c  tick-after ;

macro: >irq  0 # IRQACT # c!* drop end-macro

: till ( dtime -- )
    TVAL0 # !+ !  >irq ;

\ motor control

: -motor  $0000 # port # ! ;
: motor1  $0001 # port # ! ;
: motor2  $0010 # port # ! ;
: motor3  $0100 # port # ! ;

: do-motor
    motor1 pos1 # @ ausschlag till -motor
    motor2 pos2 # @ ausschlag till -motor
    motor3 pos3 # @ ausschlag till -motor ;

\ coordinate transforation

decimal
#800 Constant distance#  \ 800mm from tower to tower
distance# F 2/ Constant distance/2#
distance# s>f .5e fsqrt f* f>s Constant distance/rt2#
#200 Constant arm#       \ 200mm arm length
#250 Constant height#    \ 250mm height
#400 Constant faden#     \ 400mm string length
faden# F dup F negate F * Constant -faden²#

macro: 2# F dup $FFFF F and # $10 F rshift # end-macro

$B504 Constant 1/sqrt2

: >xl  1/sqrt2 # y # @ distance/rt2# # - usmul nip x # @ 2/ - xl # ! ;
: >xr  1/sqrt2 # distance/rt2# # y # @ - usmul nip x # @ 2/ - xr # ! ;
: >yl  y # @ distance/rt2# # - 2/ 1/sqrt2 # x # @ usmul nip -
    distance/rt2# # + yl # ! ;
: >yr  y # @ distance/rt2# # - 2/ 1/sqrt2 # x # @ usmul nip +
    distance/rt2# # + yr # ! ;
: >sc  ( n -- n' ) dup mul -faden²# 2# d+ sqrt ;
: >scl yl # @ >sc scl # ! ;
: >scr yr # @ >sc scr # ! ;

: coord-calc  >xl >xr >yl >yr >scl >scr ;

\ main loop

: motor-loop
    BEGIN
        20 # after  do-motor  coord-calc  till
        1 # LED7 # +!
    AGAIN ;

: boot
    $00 # LED7 # ! $E000 # dup dup 0 # !+ !+ !
    0 # dup dup x #  !+ !+ !
    init-port motor-loop ;

$3FFE org
     boot ;;
$2000 $2000 .hex b16.hex        \ print verilog hex for $2000 bytes
$2000 $2000 .hexh b16h.hex      \ print verilog hex for $2000 bytes
$2000 $2000 .hexl b16l.hex      \ print verilog hex for $2000 bytes
$2000 $2000 .hexh' b16h.mem     \ print verilog hex for $2000 bytes, unaddressed
$2000 $2000 .hexl' b16l.mem     \ print verilog hex for $2000 bytes, unaddressed
\ $2000 $2000 .hexb b16b.hex      \ print verilog hex for $2000 bytes
\ .mif test.mif
\ $21FE org
\      boot ;;
\ $2000 $200 .hexb b16b.ee8
.end                    \ end of test program
