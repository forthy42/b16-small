\ triceps2

include regmap.asm

$0000 org
\ motor angle 0-ffff for 0-180°
0 [IF]
| pos1 0 ,
| pos2 0 ,
| pos3 0 ,
[THEN]
\ position, in mm relative to north tower, floor level
\ (front/right/up is positive)
\ north tower aligns with board, center is zero point
| z 0 , \ no need to transform this
| y 0 ,
| x 0 ,
| sc 0 , \ string circle radius
| b 0 ,
| cos 0 ,
| alpha 0 ,
| angle | pos1 0 , 0 ,
\ position transformation left tower
| yl 0 ,
| xl 0 ,
| scl 0 , \ string circle radius left
| bl 0 ,
| cosl 0 ,
| alphal 0 ,
| anglel | pos2 0 , 0 ,
\ position transformation right tower
| yr 0 ,
| xr 0 ,
| scr 0 , \ string circle radius right
| br 0 ,
| cosr 0 ,
| alphar 0 ,
| angler | pos3 0 , 0 ,

$2000 org
include b16-prim.fs \ Extentions fuer b16

include b16-db.fs   \ RAM Debugging Interface

include b16-sqrt.fs

: init-port
   $0000 # GPIO02  # !
   $1111 # GPIO02T # ! ;

GPIO02 Value port

: after ( ms -- dtime )
    #50000 # mul
: tick-after ( ticks -- dtime )
    TVAL1 # @  TVAL0 # @ d+ ;

: µafter ( µs -- dtime )
    #50 # mul tick-after ;

\ min: 740, max: 2250
\ min: 600, max: 2100?
#19000 Constant motor-min#
#37750 Constant motor-gain#

: ausschlag ( 0-ffff -- dtime )
    motor-gain# # mul nip
    motor-min#  # + dup + 0 # dup +c  tick-after ;

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

\ coordinate transforation constants

decimal
#500 Constant distance#  \ 500mm from tower to tower
distance# F 2/ Constant distance/2#
distance# s>f .5e fsqrt f* f>s Constant distance/rt2# \ center to arm
#200 Constant arm#       \ 20cm arm length
#140 Constant height#    \ 14cm height
#320 Constant faden#     \ 32cm string length
faden# F dup F negate F * Constant -faden²#
arm# F dup F * faden# F dup F * F - Constant arm²-faden²#

macro: 2# F dup $FFFF F and # $10 F rshift # end-macro

$B504 Constant 1/sqrt2

\ arccos computation
\ input scaling is -1..1 is -$8000..$7FFF
\ output scaling is 0..pi 0..$FFFF
\ 64 value table, linear interpolation
\ most accurate around pi/2, which is what we want

$40 Constant tablesize#

also forth
: gentable -1e tablesize# 1+ 0 DO  fdup facos pi f/ $FFFF s>f f* f>s
        [ previous ] , [ also forth ]
        1e 32e f/ f+
    LOOP  fdrop ;
previous
| acostable  gentable

: acos ( cos -- alpha )
    $8000 # + tablesize# # mul 2* acostable # + @+ @
    >r over r> mul >r drop >r com r> mul r> + nip ;

\ coord transformation words

: >xl  1/sqrt2 # y # @        usmul nip x # @ 2/ - xl # ! ;
: >xr  1/sqrt2 # y # @ negate usmul nip x # @ 2/ - xr # ! ;
: >yl  y # @ 2/ negate 1/sqrt2 # x # @ usmul nip - yl # ! ;
: >yr  y # @ 2/ negate 1/sqrt2 # x # @ usmul nip + yr # ! ;

: >sc>  ( addr -- )  @+ >r abs dup mul -faden²# 2# d+ sqrt r> ! ;
: >b>   ( addr -- )  @+ >r dup mul height# # z # @ - dup mul d+ sqrt r> ! ;
: >cos> ( addr -- ) @+ >r
    dup >r dup mul drop arm²-faden²# # + 2/ 2/ >r 0 # r>
    r> arm# # mul drop sdiv drop r> ! ;
: >alpha> ( addr -- ) @+ >r acos r> ! ;
: >angle1 ( y-addr -- angle )  @ distance/rt2# # + 2* >r
    0 # height# # z # @ - r> sdiv drop acos ;
: >angle2 ( angle alpha-addr -- )
    @+ >r + $8000 # + r> ! ;

: >sc     x  # >sc>  xl # >sc>  xr # >sc> ;
: >b      sc  # >b>  scl # >b>  scr # >b> ;
: >cos    b  # >cos>  bl # >cos>  br # >cos> ;
: >alpha  cos # >alpha>  cosl # >alpha>  cosr # >alpha> ;
: >angle
    y  # >angle1 alpha  # >angle2
    yl # >angle1 alphal # >angle2
    yr # >angle1 alphar # >angle2 ;

: coord-calc
    >xl >xr >yl >yr
    >sc >b >cos >alpha >angle ;

\ main loop

: motor-loop
    BEGIN
        20 # after  do-motor  coord-calc  till
        1 # LED7 # +!
    AGAIN ;

: boot
    $00 # LED7 # ! $4000 # dup dup 0 # !+ !+ !
    0 # dup dup z #  !+ !+ !
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
0 [IF]
Local Variables:
mode: Forth
forth-local-words:
    (
    (("\|") non-immediate (font-lock-type-face . 2)
     "[ \t\n]" t name (font-lock-variable-name-face . 3))
    (("macro:") definition-starter (font-lock-keyword-face . 1)
     "[ \t\n]" t name (font-lock-function-name-face . 3))
    (("end-macro") definition-ender (font-lock-keyword-face . 1))
    (("0<if") compile-only (font-lock-keyword-face . 2))
    )
forth-local-indent-words:
    (
        (("macro:") (0 . 2) (0 . 2) non-immediate)
        (("end-macro") (-2 . 0) (0 . -2))
        (("0<if") (0 . 2) (0 . 2))
    )
End:
[THEN]
