[IFDEF] bigforth
    include serial.fs
    
    dos also
[ELSE]
    include unix/serial.fs
    : linux ;
[THEN]

0 value b16
true Value do-serial
false Value record-dbg

$1000 cells Constant dbg#

Create dbg-buf dbg# allot

: dbg-empty  dbg-buf dbg# -1 fill ;

dbg-empty

: >dbg ( data addr -- )
    record-dbg 0= IF  2drop  EXIT  THEN
    dbg-buf dbg# bounds ?DO
	dup I @ = I @ -1 = or  IF  I 2!  unloop EXIT  THEN
    2 cells +LOOP  2drop ( ." No space in DBG" cr ) ;
: dbg> ( addr -- data )
    dbg-buf dbg# bounds ?DO
	dup I @ = IF  drop I cell+ @ unloop  EXIT  THEN
    2 cells +LOOP  drop  0 ;

: init-ser ( addr u -- )  r/w bin open-file throw to b16
    [IFDEF] key?-file  b16 key?-file drop  [THEN]
    [IFDEF] android
	"stty </dev/ttyUSB0 raw cs8 230400" system
    [ELSE]
	B230400 b16 ( fileno ) set-baud
    [THEN] ;

: ?open ( -- )  do-serial 0= ?EXIT
    b16 ?exit
    [IFDEF] linux
	s" /dev/ttyUSB0"
    [ELSE]
	s" COM1"
    [THEN] ['] init-ser catch
    IF
	[IFDEF] backtrace
	    backtrace $18 cells + off
	[ELSE]
	    noThrow
	[THEN]
	2drop false to do-serial ." Line not connected" cr
    THEN ;

[IFUNDEF] after
    : after ( n -- time )
	utime 1000 ud/mod drop nip + ;
    : wait ( time -- ) ms ;
[THEN]

Variable timeout

: waitx  10 ms timeout @ 0 after - 0< ;

[IFDEF] linux
: b16-clear ( -- )  do-serial 0= ?EXIT
    pad b16 check-read b16 read-file throw drop ;

: check-in ( n -- addr u ) &200 after timeout !
    BEGIN  dup b16 check-read u>  WHILE  waitx  UNTIL
	drop s" iii" b16 write-file throw
	&100 ms b16-clear
	pad 0 EXIT  THEN
    pad swap b16 read-file throw pad swap ;
[ELSE]
: b16-clear ( -- )  pad 100 b16 read-file throw drop ;

: check-in ( n -- addr u ) \ b16 flush-file throw
    &200 after timeout !  pad swap
    BEGIN  2dup b16 read-file throw /string  dup 0>  WHILE  waitx  UNTIL
        drop s" iii" b16 write-file throw
        &100 ms b16-clear
        pad 0 EXIT  THEN
    + pad tuck - ;
[THEN]

: hold16 ( n -- )  dup hold 8 rshift hold ;

\ load store

Variable addr' -1 addr' !

: addr ( addr -- )  ?open  addr' @ over addr' ! over <> IF 
	<# hold16 'a hold 0. #> b16 write-file throw
    ELSE  drop  THEN ;

: dbg@ ( addr -- u )
    do-serial 0= IF  dbg>  EXIT  THEN  ?open
    addr s" rl" b16 write-file throw  2 check-in
    0 -rot bounds ?DO  8 lshift I c@ or  LOOP  2 addr' +! ;

: bswaps ( addr u -- )
    bounds ?DO  I 1+ c@ I c@ I 1+ c! I c!  2 +LOOP ;

[IFDEF] $tmp
    : dbg@s ( source-addr addr u -- )
	do-serial 0= IF  2* bounds ?DO  dup dbg@ I w! 2 + 2 +LOOP  drop
	    EXIT  THEN  ?open  rot addr
	BEGIN  2dup $200 min
	    dup [: 0 ?DO ." rl" LOOP ;] $tmp b16 write-file throw
	    2* check-in 2dup bswaps
	    rot swap dup addr' +! move
	$400 safe/string  dup 0= UNTIL  2drop ;
[ELSE]
    Variable dbg$
    : dbg@s ( source-addr addr u -- )
	do-serial 0= IF  2* bounds ?DO  dup dbg@ I w! 2 + 2 +LOOP  drop
	    EXIT  THEN  ?open  rot addr
	BEGIN  2dup $200 min  s" " dbg$ $!
	    dup 0 ?DO s" rl" dbg$ $+! LOOP dbg$ $@ b16 write-file throw
	    2* check-in 2dup bswaps
	    rot swap dup addr' +! move
	$400 safe/string  dup 0= UNTIL  2drop ;
[THEN]

: dbgc@ ( addr -- u )
    do-serial 0= IF  dup 1 and >r -2 and dbg>
	r> 1 xor 3 lshift rshift $FF and  EXIT  THEN  ?open
    addr s" r" b16 write-file throw  1 check-in
    0 -rot bounds ?DO  8 lshift I c@ or  LOOP  1 addr' +! ;

: dbg! ( u addr -- )
    2dup >dbg  do-serial 0= IF  2drop  EXIT  THEN
    addr <# hold16 'W hold 0. #>
    b16 write-file throw 2 addr' +! ( b16 flush-file throw ) ;

: dbg!s ( addr u dest-addr -- )
    do-serial 0= IF
	-rot bounds ?DO  I w@ over dbg! 2 +  2 +LOOP  drop
	EXIT  THEN
    ?open addr
    bounds ?DO  I w@ addr' @ dbg!  2 +LOOP ;

: dbg-ram!s ( addr u dest-addr -- )
    do-serial 0= IF
	bounds ?DO  I ram@ over dbg! 2 +  2 +LOOP  drop
	EXIT  THEN
    ?open addr
    bounds ?DO  I ram@ addr' @ dbg!  2 +LOOP ;

: >dbgc ( u addr -- )  dup 1 and >r -2 and dup dbg> rot
    r> IF  $FF and swap $FF00 and or swap >dbg
    ELSE   $FF and 8 lshift swap $FF and or swap >dbg
    THEN ;

: dbgc! ( u addr -- )
    2dup >dbgc  do-serial 0= IF  2drop  EXIT  THEN
    addr <# hold 'w hold 0. #>
    b16 write-file throw 1 addr' +! ( b16 flush-file throw ) ;

: status@ ( -- n )  ?open  do-serial 0= IF  0  EXIT  THEN  b16-clear
    s" i" b16 write-file throw  1 check-in drop c@ ;

[IFDEF] linux
: ?in ( -- )  pad b16 check-read b16 read-file throw pad swap type ;
: ?flush ( -- )  pad $100 + b16 check-read b16 read-file throw drop ;
[ELSE]
: ?in ( -- )  pad 100 b16 read-file throw drop ;
: ?flush ( -- )  pad $100 + 100 b16 read-file throw drop ;
[THEN]

[IFDEF] bigforth
    previous
[THEN]
