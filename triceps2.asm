\ triceps2
\ -*- forth-mode -*-
include regmap.asm

$0000 org
| pos1 0 ,
| pos2 0 ,
| pos3 0 ,

$2000 org
include b16-prim.fs \ Extentions fuer b16

include b16-db.fs   \ RAM Debugging Interface

include b16-sqrt.fs

: init-port
   $0111 # GPIO02T # !
   $0000 # GPIO02  # ! ;

GPIO02 Value port

: after ( ms -- dtime )
    #12500 # mul
: tick-after ( ticks -- dtime )
    TVAL1 # @  TVAL0 # @ d+ ;

: µafter ( µs -- dtime )
    #12 # mul tick-after ;

\ min: 740, max: 2250
: ausschlag ( 0-ffff -- dtime )
    #18875 # mul nip
    #09250 # + 0 #  tick-after ;

macro: >irq  0 # IRQACT # c!* drop end-macro

: till ( dtime -- )
    TVAL0 # !+ !  >irq ;

\ microseconds:

: -motor  $0000 # port # ! ;
: motor1  $0001 # port # ! ;
: motor2  $0010 # port # ! ;
: motor3  $0100 # port # ! ;

: motor-loop
    BEGIN
        50 # after
        motor1 pos1 # @ ausschlag till
        motor2 pos2 # @ ausschlag till
        motor3 pos3 # @ ausschlag till
        1 # LED7 # +!
        -motor till
    AGAIN ;

: boot
     $00 # LED7 # ! 0 # dup dup 0 # !+ !+ !
     init-port motor-loop ;

$3FFE org
     boot ;;
$2000 $2000 .hex b16.hex        \ print verilog hex for $2000 bytes
\ $2000 $2000 .hexh b16h.hex      \ print verilog hex for $2000 bytes
\ $2000 $2000 .hexl b16l.hex      \ print verilog hex for $2000 bytes
$2000 $2000 .hexh' b16h.mem     \ print verilog hex for $2000 bytes, unaddressed
$2000 $2000 .hexl' b16l.mem     \ print verilog hex for $2000 bytes, unaddressed
\ $2000 $2000 .hexb b16b.hex      \ print verilog hex for $2000 bytes
\ .mif test.mif
\ $21FE org
\      boot ;;
\ $2000 $200 .hexb b16b.ee8
.end                    \ end of test program
