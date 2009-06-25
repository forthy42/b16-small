\
include regmap.asm
$2000 org
        $AA56 ,

include b16-prim.fs \ Extentions fuer b16

include b16-db.fs   \ RAM Debugging Interface

include b16-sqrt.fs

: bitset ( adr 16b -- ) over @ or swap ! ;

: bitclr ( adr 16b -- ) $FFFF # xor over @ and swap ! ;

: 3dup ( n1 n2 n3 -- n1 n2 n3 n1 n2 n3 )
    dup >r rot
    dup >r rot
    dup >r rot
    r> r> swap r> ;

\ abs wird gebraucht weil negative Differenzen entstehen
\ und mul und div mit ud arbeiten

: ds ( dx dy dz -- s )
     abs dup mul >r >r 
     abs dup mul >r >r 
     abs dup mul r> r> d+ r> r> d+ 
     sqrt ;

: v- ( x1 y1 z1 x2 y2 z2 -- dx dy dz )
     >r rot r> swap - >r      \ dz
     rot - >r                 \ dy
     swap - r> r> ;

: v+ ( x1 y1 z1 x2 y2 z2 -- x3 y3 z3 )
    >r rot r> + >r      \ z
    rot + >r            \ y
    + r> r> ;

macro: .v >h >r >h >r >h r> r> +l end-macro

: after ( ms -- dtime )
    $01c0 # mul
    TVAL1 # @  TVAL0 # @ d+ ; 

: till ( dtime -- )
      TVAL0 # ! TVAL1 # !
      0 # IRQACT # c!* drop ;

: init-port
   $03FF # GPIO02T # !
   $0000 # GPIO02  # ! ;

GPIO02 Value port

: motorout ( 8b -- )
   $00FF # and port # @ $FF00 # and or port # !
   $2 # BEGIN 1 # - dup 0= UNTIL drop
   port # $0200 # bitset 
   $2 # BEGIN 1 # - dup 0= UNTIL drop
   port # $0200 # bitclr 
   $80 # BEGIN 1 # - dup 0= UNTIL drop
   ;

: magnet port # $0100 # ;

Label mottab    $27 c, $2D c, $1C c, $0D c,
                $03 c, $09 c, $38 c, $29 c,

Label /ma     $00 , 0 , 
Label /mb     $40 , 0 , 
Label /mc     $80 , 0 , 

: ma /ma @+ ;
: mb /mb @+ ;
: mc /mc @+ ;

macro: left   1 # end-macro
macro: right -1 # end-macro

: step ( mbit adr direction -- )
   over +! @ $07 # and mottab + c@ or motorout ;

  &600 Value maxsteptime
   &60 Value minsteptime

\ steptimeslope darf max $7fff bei div durch 1 sein, sonst neg !

     0 Value steptimeslope-h
 $5000 Value steptimeslope-l 

: arelstep ( n -- )
   dup IF 0<
          IF    ma left  step 
          ELSE  ma right step THEN
       ELSE drop THEN ;
: brelstep ( n -- )
   dup IF 0<
          IF    mb left  step 
          ELSE  mb right step THEN
       ELSE drop THEN ;

: crelstep ( n -- )
   dup IF 0<
          IF    mc left  step 
          ELSE  mc right step THEN
       ELSE drop THEN ;

Label ma-pos      0 ,  0 , 0 ,
Label mb-pos &5400 ,  0 , 0 ,
Label mc-pos &5400 F dup s>f pi f2* !6 f/ fcos f* f>s ,
                       s>f pi f2* !6 f/ fsin f* f>s , 0 ,
Label gr-pos &5400 F dup F 2/ ,
              s>f pi f2* !6 f/ fsin f* !3 f/ f>s , &3600 ,
\ kreuzungs Position
Label gr-org &5400 F dup F 2/ ,
              s>f pi f2* !6 f/ fsin f* !3 f/ f>s , &3600 ,

: schritte ( mm -- schritte )
    &400 # mul &642 # div drop ;

macro: x-pos end-macro
macro: y-pos  cell+ end-macro
macro: z-pos 2cell+ end-macro

: pos@ ( adr -- x y z ) dup >r x-pos  @ r@ y-pos  @ r> z-pos  @ ;
: pos! ( x y z adr -- ) dup >r z-pos  ! r@ y-pos  ! r> x-pos  ! ;

\ : seillaengen ( x y z -- sa sb sc )
\    3dup mc-pos pos@  v- ds >r
\    3dup mb-pos pos@  v- ds >r
\         ma-pos pos@  v- ds r> r> ;

Label temp-pos     0 ,   0 , 0 ,

: seillaengen ( x y z -- sa sb sc )
   temp-pos pos!
   ma-pos x-pos @ temp-pos x-pos @  -  
   ma-pos y-pos @ temp-pos y-pos @  -  
   ma-pos z-pos @ temp-pos z-pos @  -
   ds
   mb-pos x-pos @ temp-pos x-pos @  -  
   mb-pos y-pos @ temp-pos y-pos @  -  
   mb-pos z-pos @ temp-pos z-pos @  -  
   ds 
   mc-pos x-pos @ temp-pos x-pos @  -  
   mc-pos y-pos @ temp-pos y-pos @  -  
   mc-pos z-pos @ temp-pos z-pos @  -  
   ds ;

: init-seillaengen 
   gr-org pos@ 
   3dup gr-pos pos! 
   seillaengen  
   schritte mc nip ! 
   schritte mb nip ! 
   schritte ma nip ! ;

\ es darf immer nur ein Schritt gemacht werden
\ einer prüft und gibt Mehrfach-Schritte auf dem Heap aus

\ : einer  
\    dup IF dup abs 1- IF >r >h r> >h +l THEN THEN ;

\ xrelstep fuehrt immer nur einen Schritt aus
\ bei zwei Schritte wird der naechste verschoben ausgefuehrt

: positioniere ( x y z -- ) 
   seillaengen  
   schritte mc nip @ swap - ( einer) crelstep
   schritte mb nip @ swap - ( einer) brelstep
   schritte ma nip @ swap - ( einer) arelstep 
   ;

: steptime ( distance -- steptime )
    dup 0= IF drop 1 # THEN \ wegen div durch 0 
    steptimeslope-l # 
    steptimeslope-h # 
    rot div drop
    maxsteptime # min
    minsteptime # max ;

: ramptime ( topos frompos pos -- steptime )
    dup >r swap - swap r> - min steptime ;


\     sum | divisor | dividend
Label dx  0 , 0 , 0 ,
Label dy  0 , 0 , 0 ,
Label dz  0 , 0 , 0 ,

: go ( adr -- steps ) \ steps => links=-1 | rechts=1 | 0
   dup >r @+ @+ drop abs + dup 0<
    IF 0 # swap
    ELSE r@ cell+ @ 0< 
       IF 1 # ELSE -1 # THEN swap
          r@ 2cell+ @ -  
    THEN r> ! ;

: >ratio ( count div adr -- )
     >r over >r 0 # r> - r> !+ !+ !+ drop ;

Label temp2-pos     0 ,  0 , 0 ,

: absbewegen ( x y z -- )
   gr-pos pos@ v- 
   3dup ds 2* dup \ 2* verarbeitet eventuell aufgestaute Schritte
   IF under swap dz >ratio 
      under swap dy >ratio 
      under swap dx >ratio
      >r gr-pos pos@ r@
      BEGIN dup WHILE >r
      dx go dy go dz go v+
      3dup temp2-pos pos! positioniere
      temp2-pos pos@
      r> r> over over >r >r 0 # rot
      ramptime after till
      r> 1- REPEAT drop r> drop
      gr-pos pos!
   ELSE 2drop 2drop 2drop drop THEN
   ;

: down ( dz -- )
    0 # 0 # rot gr-pos pos@ v+ absbewegen ;
: up   ( dz -- )
    negate down ;
: left ( dx -- )
    0 # 0 # gr-pos pos@ v+ absbewegen ;
: right ( dx -- )
    negate left ;
: forw
    0 # swap 0 # gr-pos pos@ v+ absbewegen ;
: back ( dy -- )
    negate forw ;

: spiel-feld ( x-nr  y-nr -- )
   &200 # mul drop &600 # - swap 
   &200 # mul drop &600 # - swap &-200 # ( x y z )
   gr-org pos@ v+ absbewegen ;

: reihe1 ( nr -- )
   &200 # mul drop &1000 # - &-1000 # &-200 # ( x y z )
   gr-org pos@ v+ 
   absbewegen ;

\ $10000 s>f pi f2* !6 f/ fsin f* f>s # mul nip 
\ multipliziert mit dem sin von $10000 und nip erspart Division

: reihe2 ( nr -- ) 
    &200 # mul drop &750 # + dup
    $10000 s>f pi f2* !6 f/ fsin f* f>s # mul nip 
    swap
    $10000 s>f pi f2* !6 f/ fcos f* f>s # mul nip 
    swap &-200 #
    &-1750 # &-1000 # 0 # v+
    gr-org pos@ v+ absbewegen ;

: reihe3 ( nr -- ) 
    &200 # mul drop  &750 # + dup
    $10000 s>f pi f2* !6 f/ fsin f* f>s # mul nip 
    swap
    $10000 s>f pi f2* !6 f/ fcos f* f>s # mul nip
    negate swap &-200 #
    &1750 # &-1000 # 0 # v+
    gr-org pos@ v+ absbewegen ;

Label reihen ' reihe1 , ' reihe2 , ' reihe3 ,
\ DOES> swap cells + perform ;

: ablage ( nr -- )
     0 # &11 # div swap cells reihen + @ exec ;

Label freiablage &0 ,

: (kugel-aufnehmen  magnet bitset &250 # down &250 # up ;

: (kugel-ablegen    &200 # down magnet bitclr &200 # up ;

: kugel-wegnehmen ( n m -- )
   spiel-feld (kugel-aufnehmen ;

: kugel-ablegen   ( n m -- )
   spiel-feld (kugel-ablegen ;

: kugel-entfernen
   freiablage @ ablage (kugel-ablegen 1 # freiablage +! ;

: kugel-holen
   -1 # freiablage +! freiablage @ ablage (kugel-aufnehmen ;

: .stand &33 # freiablage @ - 0 # 
    &10 # div swap $10 # mul drop swap + LED7 # ! ;

: einraeumen
   kugel-holen kugel-ablegen .stand ;

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

Label /spiele ( n m flg -- )
' 2drops  ,
' spiele1 ,
' spiele2 ,
' spiele3 ,
' spiele4 ,
\ DOES> swap cells + perform ;

: spiele ( n m flg -- )
         cells /spiele + @ exec .stand ;

: boot
    $00 # LED7 # !
    init-heap
    init-port
    &8000 # after till
    init-seillaengen
&33 # freiablage !
6 # 4 # einraeumen
6 # 3 # einraeumen
6 # 2 # einraeumen
5 # 4 # einraeumen
5 # 3 # einraeumen
5 # 2 # einraeumen
4 # 6 # einraeumen
4 # 5 # einraeumen
4 # 4 # einraeumen
4 # 3 # einraeumen
4 # 2 # einraeumen
4 # 1 # einraeumen
4 # 0 # einraeumen
3 # 6 # einraeumen
3 # 5 # einraeumen
3 # 4 # einraeumen
3 # 2 # einraeumen
3 # 1 # einraeumen
3 # 0 # einraeumen
2 # 6 # einraeumen
2 # 5 # einraeumen
2 # 4 # einraeumen
2 # 3 # einraeumen
2 # 2 # einraeumen
2 # 1 # einraeumen
2 # 0 # einraeumen
1 # 4 # einraeumen
1 # 3 # einraeumen
1 # 2 # einraeumen
0 # 4 # einraeumen
0 # 3 # einraeumen
0 # 2 # einraeumen

3 # 1 # 2 # spiele
1 # 2 # 3 # spiele
4 # 2 # 1 # spiele
6 # 2 # 1 # spiele
1 # 4 # 4 # spiele
3 # 4 # 1 # spiele
1 # 2 # 3 # spiele
3 # 2 # 3 # spiele
5 # 4 # 1 # spiele
2 # 0 # 2 # spiele
2 # 3 # 4 # spiele
6 # 4 # 4 # spiele
4 # 0 # 1 # spiele
4 # 6 # 4 # spiele
2 # 6 # 3 # spiele
4 # 3 # 2 # spiele
2 # 0 # 2 # spiele
0 # 4 # 3 # spiele
3 # 4 # 1 # spiele
6 # 2 # 1 # spiele
4 # 1 # 2 # spiele
0 # 2 # 2 # spiele
0 # 4 # 3 # spiele
4 # 6 # 4 # spiele
2 # 5 # 4 # spiele
4 # 3 # 2 # spiele
2 # 2 # 2 # spiele
4 # 5 # 1 # spiele
2 # 5 # 4 # spiele
2 # 3 # 3 # spiele
5 # 3 # 1 # spiele
3 # 3 # kugel-wegnehmen kugel-entfernen .stand
gr-org pos@ absbewegen
    BEGIN
    AGAIN ; hier .
    ;;
$3FFE org
     boot ;;
$2000 $2000 .hex b16.hex        \ print verilog hex for $2000 bytes
$2000 $2000 .hexh b16h.hex      \ print verilog hex for $2000 bytes
$2000 $2000 .hexl b16l.hex      \ print verilog hex for $2000 bytes
$2000 $2000 .hexb b16b.hex      \ print verilog hex for $2000 bytes
.mif test.mif
\ $21FE org
\      boot ;;
\ $2000 $200 .hexb b16b.ee8
.end                    \ end of test program
