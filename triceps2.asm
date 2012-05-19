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
| c 0 , \ triangle hypothenuse
| x 0 ,
| sc 0 , \ string circle radius
| cos 0 ,
| alpha 0 ,
| angle | pos1 0 ,
| b 0 ,
\ position transformation left tower
| yl 0 ,
| cl 0 ,
| xl 0 ,
| scl 0 , \ string circle radius left
| cosl 0 ,
| alphal 0 ,
| anglel | pos2 0 ,
| bl 0 ,
\ position transformation right tower
| yr 0 ,
| cr 0 ,
| xr 0 ,
| scr 0 , \ string circle radius right
| cosr 0 ,
| alphar 0 ,
| angler | pos3 0 ,
| br 0 ,

$2000 org
\ coordinate transforation constants

decimal
| distance #305 ,        \ center to arm
| arm      #200 ,        \ 20cm arm length
| height   #140 ,        \ 14cm height
| faden    #310 ,        \ 32cm string length

$B504 Constant 1/sqrt2

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

macro: faden² faden # @ dup mul end-macro

: >xl  1/sqrt2 # y # @        usmul nip x # @ 2/ - xl # ! ;
: >xr  1/sqrt2 # y # @ negate usmul nip x # @ 2/ - xr # ! ;
: >yl  y # @ 2/ negate 1/sqrt2 # x # @ usmul nip - yl # ! ;
: >yr  y # @ 2/ negate 1/sqrt2 # x # @ usmul nip + yr # ! ;

: >sc>  ( addr -- )  @+ >r >r faden² r> abs dup mul d- sqrt r> ! ;
: >c>   ( addr -- )  @+ >r distance # @ +
    dup mul height # @ z # @ - abs dup mul d+ sqrt r> ! ;
\ : >b>   ( addr -- )  @+ >r dup mul height # @ z # @ - dup mul d+ sqrt r> ! ;
: >cos> ( c-addr b-addr -- ) @+ >r >r
    @ u2/ dup dup mul drop
    arm # @ 2/ dup mul drop r> 2/ dup mul drop - +
    over >r >r drop 0 # r> 2/ r>
    arm # @ mul drop sdiv drop r> ! ;
: >alpha> ( addr -- ) @+ >r acos r> ! ;
: >angle1 ( y-addr -- angle )  @ >r
    0 # height # @ z # @ - r> 2* sdiv drop acos ;
: >angle2 ( angle alpha-addr -- )
    @+ >r + $8000 # + r> ! ;

: >sc     x  # >sc>  xl # >sc>  xr # >sc> ;
: >c      y  # >c>   yl # >c>   yr # >c> ;
\ : >b      sc  # >b>  scl # >b>  scr # >b> ;
: >cos    c # sc  # >cos>  cl # scl # >cos>  cr # scr # >cos> ;
: >alpha  cos # >alpha>  cosl # >alpha>  cosr # >alpha> ;
: >angle
    c  # >angle1 dup b  # !  alpha  # >angle2
    cl # >angle1 dup bl # !  alphal # >angle2
    cr # >angle1 dup br # !  alphar # >angle2 ;

: coord-calc
    >xl >xr >yl >yr
    >sc >c >cos >alpha >angle ;

\ main loop

: motor-loop
    BEGIN
        20 # after  do-motor  coord-calc  till
        1 # LED7 # +!
    AGAIN ;

: boot
    $00 # LED7 # !
    0 # dup dup dup z #  !+ !+ !+ !
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
