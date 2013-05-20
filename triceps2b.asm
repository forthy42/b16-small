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

\ position tracking

| deltax 0 ,
| deltay 0 ,
| deltaz 0 ,
| dist   0 ,
| stepx  0 , | errx 0 ,
| stepy  0 , | erry 0 ,
| stepz  0 , | errz 0 ,
| speed  0 ,

| freiablage &0 ,

|# destination 0 , 0 ,
|# tremor 0 ,
|# extra-cmd 0 ,

$2000 org
\ coordinate transforation constants

decimal
| distance #335 ,        \ 33.5cm center to arm
| arm      #200 ,        \ 20cm arm length
| height   #140 ,        \ 14cm height
| faden    #400 ,        \ 40cm string length

| offset1 $-200 ,
| offset2 $-600 ,
| offset3 $-500 ,

| motor-min#  #18300 ,
| motor-gain# #45000 ,

$DDB3 Constant sqrt3/2

include b16-prim.fs \ Extentions fuer b16

\ include b16-db.fs   \ RAM Debugging Interface

include b16-sqrt.fs

: init-port
    TIMERVAL0 # @+ @  swap TVAL0 # !+ !
    $0000 # GPIO02  # !  $1111 # GPIO02T # ! ;

GPIO02 Value port

: after ( ms -- dtime )
    #50000 # mul
: tick-after ( ticks -- dtime )
    TVAL1 # @  TVAL0 # @ d+ ;

: µafter ( µs -- dtime )
    #50 # mul tick-after ;

\ min: 740, max: 2250
\ min: 600, max: 2100?
\ #19000 Constant motor-min#
\ #37750 Constant motor-gain#

: ausschlag ( 0-ffff -- dtime )
    tremor @ +
    motor-gain# # @ mul nip
    motor-min#  # @ + dup + 0 # dup +c  tick-after ;

macro: >irq  0 # IRQACT # c!* drop end-macro

: till ( dtime -- )
    TVAL0 # !+ !  >irq ;

\ motor control

: -motor  $0000 # port # ! ;
: motor1  $0001 # port # ! ;
: motor2  $0010 # port # ! ;
: motor3  $0100 # port # ! ;

: do-motor
    motor1 pos1 # @ offset1 # @ + ausschlag till -motor
    motor2 pos2 # @ offset2 # @ + ausschlag till -motor
    motor3 pos3 # @ offset3 # @ + ausschlag till -motor
    tremor @ com tremor ! ;

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
    $8000 # + tablesize# # mul cells acostable # + @+ @
    >r over r> mul >r drop >r com r> mul r> + nip ;

\ coord transformation words

macro: faden² faden # @ dup mul end-macro

: >xy  ( x y -- x' y' ) >r 2/ negate sqrt3/2 # r> usmul nip ;

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
    x # @ y # @
    2dup >xy + xl # !
    2dup >xy - xr # !  swap
    2dup >xy - yl # !
         >xy + yr # !
    >sc >c >cos >alpha >angle ;

\ wait loop

: motor-step ( -- )
    coord-calc  12 # after  till  8 # after  do-motor  till
    ( 1 # LED7 # +! ) ;
macro: LOOP  -1 # + dup -UNTIL  drop  end-macro
: wait ( n -- )
    BEGIN  motor-step  LOOP ;

24 Constant speedlimit#
: >movez ( z -- )  z # @ - dup deltaz # !  abs 2* 2* 2* dist # !
    0 # dup stepx # !+ !
    0 # dup stepy # !+ !
    0 # dup deltaz # @ dist # @ sdiv drop stepz # !+ !
    0 # speed # ! ;
: >moveto ( x y -- )
    y # @ - deltay # !  x # @ - deltax # !
    deltax # @ abs 2* dup mul
    deltay # @ abs 2* dup mul d+
    sqrt 2* dup -IF  drop 1 #  THEN  dist # ! \ avoid zero delta
    0 # dup deltax # @ dist # @ sdiv drop stepx # !+ !
    0 # dup deltay # @ dist # @ sdiv drop stepy # !+ !
    0 # dup stepz # !+ !
    0 # speed # ! ;
: movestep ( -- )
    stepx # @+ @. >r >r dup 0< r> x # @ d+ x # ! r> ! 
    stepy # @+ @. >r >r dup 0< r> y # @ d+ y # ! r> !
    stepz # @+ @. >r >r dup 0< r> z # @ d+ z # ! r> !
    dist # @. >r -1 # + dup 0<IF  drop 0 #  THEN  r> ! ;
: movesteps ( -- )
    speed # @ dist # @ umin  u2/ u2/
    speedlimit# # umin u2/ u2/ 1 # +
    BEGIN  movestep  1 # speed # +!  dist # @ -IF  drop ;  THEN
    LOOP ;

: >pos    BEGIN  movesteps motor-step  dist # @ -UNTIL ;
: moveto ( x y -- )  2dup destination !+ !  >moveto  >pos ;
: movez ( z -- )  >movez  >pos ;

: down     #15 # movez ;
: lift     #40 # movez ;
: release  #40 # z # ! 10 # wait ;
: pick   down lift ;
: place  #20 # wait  down release ;

\ game play: positions

: spiel-feld ( x-nr y-nr -- )
    #20 # sumul drop #-60 # + >r #20 # sumul drop #-60 # + r>  moveto ;

: reihe1 ( nr -- )  -1 # +   -1 #    spiel-feld ;
: reihe2 ( nr -- )  -1 # + >r 7 # r> spiel-feld ;
: reihe3 ( nr -- )  com 8 # + 7 #    spiel-feld ;
: reihe4 ( nr -- )  com 8 # + >r -1 # r> spiel-feld ;

| reihen ' reihe1 , ' reihe2 , ' reihe3 , ' reihe4 ,

: ablage ( nr -- )  0 # #8 # div swap cells reihen # + @ goto ;

: .stand &32 # freiablage # @ - 0 # 
    &10 # div swap 2* 2* 2* 2* + LED7 # ! ;

macro: kugel-wegnehmen ( n m -- )
   spiel-feld pick end-macro

macro: kugel-ablegen   ( n m -- )
   spiel-feld place end-macro

: kugel-entfernen
   freiablage # @ ablage place  1 # freiablage # +!  .stand ;

: kugel-holen
   -1 # freiablage # +! freiablage # @ ablage pick  ;

: einraeumen
   kugel-holen kugel-ablegen  .stand ;

: spiele1 ( n m -- )
    2dup          kugel-wegnehmen
    2dup >r 2- r> kugel-ablegen
         >r 1- r> kugel-wegnehmen kugel-entfernen ;

: spiele2 ( n m -- )
    2dup kugel-wegnehmen 2dup 2+ kugel-ablegen 1+
    kugel-wegnehmen kugel-entfernen ;

: spiele3 ( n m -- )
    2dup          kugel-wegnehmen
    2dup >r 2+ r> kugel-ablegen
         >r 1+ r> kugel-wegnehmen kugel-entfernen ;

: spiele4 ( n m -- )
    2dup kugel-wegnehmen 2dup 2- kugel-ablegen 1-
    kugel-wegnehmen kugel-entfernen ;

: 2drops 2drop ;  \ weil 2drop ein Macro ist

\ game play: Tasker

: 432einraeumen  ( n -- )
    dup 4 # einraeumen  dup 3 # einraeumen  2 # einraeumen ;
: 654einraeumen ( n -- )
    dup 6 # einraeumen  dup 5 # einraeumen  dup  4 # einraeumen ;
: 210einraeumen ( n -- )
    dup 2 # einraeumen  dup 1 # einraeumen  0 # einraeumen ;

: calibrate
    3 # 3 # spiel-feld  250 # wait
     0 # reihe1         250 # wait
     0 # reihe2         250 # wait
     0 # reihe3         250 # wait
     0 # reihe4         250 # wait
    3 # 3 # spiel-feld  250 # wait
    down                250 # wait
    6 # 3 # spiel-feld  250 # wait
    3 # 6 # spiel-feld  250 # wait
    3 # 0 # spiel-feld  250 # wait
    lift                250 # wait ;

\ extra commands for playing Go
: wait-extra ( -- )
    BEGIN  extra-cmd @ UNTIL ;
: do-extras ( -- )
    BEGIN  wait-extra  extra-cmd @ exec   0 # extra-cmd !  AGAIN ;

\ boot

\ $2800 org
: boot
    $00 # LED7 # !
    0 # dup dup #40 # z #  !+ !+ !+ !
    0 # deltaz # !  0 # tremor !  0 # extra-cmd !
    init-port
    calibrate
    extra-cmd @ IF  do-extras  THEN
    BEGIN
        &32 # freiablage # !
                           0 # 432einraeumen
                           1 # 432einraeumen
    2 # 654einraeumen  dup 3 # einraeumen  210einraeumen
    3 # 654einraeumen                      210einraeumen
    4 # 654einraeumen  dup 3 # einraeumen  210einraeumen
                           5 # 432einraeumen
                           6 # 432einraeumen
        
        3 # 1 # spiele2
        1 # 2 # spiele3
        4 # 2 # spiele1
        6 # 2 # spiele1
        1 # 4 # spiele4
        3 # 4 # spiele1
        1 # 2 # spiele3
        3 # 2 # spiele3
        5 # 4 # spiele1
        2 # 0 # spiele2
        2 # 3 # spiele4
        6 # 4 # spiele4
        4 # 0 # spiele1
        4 # 6 # spiele4
        2 # 6 # spiele3
        4 # 3 # spiele2
        2 # 0 # spiele2
        0 # 4 # spiele3
        3 # 4 # spiele1
        6 # 2 # spiele1
        4 # 1 # spiele2
        0 # 2 # spiele2
        0 # 4 # spiele3
        4 # 6 # spiele4
        2 # 5 # spiele4
        4 # 3 # spiele2
        2 # 2 # spiele2
        4 # 5 # spiele1
        2 # 5 # spiele4
        2 # 3 # spiele3
        5 # 3 # spiele1
        3 # 3 # kugel-wegnehmen kugel-entfernen
        3 # 3 # spiel-feld
        #1000 # wait
    AGAIN ;
| scratch

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
    (("0<if" "-if" "cif" "-cif" "u<if" "-until" "cuntil" "-cuntil"
     "-while" "cwhile" "-cwhile") compile-only (font-lock-keyword-face . 2))
    )
forth-local-indent-words:
    (
        (("macro:") (0 . 2) (0 . 2) non-immediate)
        (("end-macro") (-2 . 0) (0 . -2))
        (("0<if" "-if" "cif" "-cif" "u<if") (0 . 2) (0 . 2))
        (("-until" "cuntil" "-cuntil") (-2 . 0) (-2 . 0))
        (("-while" "cwhile" "-cwhile") (-2 . 4) (0 . 2))
    )
End:
[THEN]
