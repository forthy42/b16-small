#! /usr/local/bin/gforth
\ b16 simulator

\ Instruction set:
\ 1, 5, 5, 5 bits
\     0    1    2    3    4    5    6    7
\  0: nop  call jmp  ;    jz   jnz  jc   jnc
\          exec goto ;    gz   gnz  gc   gnc   for slot 3
\  8: xor  com  and  or   +    +c   *+   /-
\ 10: A!+  A@+  R@+  lit  Ac!+ Ac@+ Rc@+ litc
\     A!   A@   R@   lit  Ac!  Ac@  Rc@  litc  for slot 1
\ 18: nip  drop over dup  >r   >a   r>   a

\ $Log: b16.fs,v $
\ Revision 1.3  2003/01/06 20:35:21  bernd
\ Changes to run with Icarus Verilog
\ USB interrupts
\ Added interrupts to the b16 core
\

warnings off

: 0.r ( n r -- )  0 swap <# 0 ?DO # LOOP #> type ;

\ Variables

Variable Inst
Variable P
Variable A
Variable c
Variable sp  here &10 cells dup allot erase  2 sp !
Variable rp  here   8 cells dup allot erase
Variable slot  4 slot !
Variable cycles

\ RAM access

$10000 allocate throw Value RAM  RAM $10000 erase
: ramc@ ( addr -- n )  RAM + c@ ;
: ramc! ( n addr -- )  RAM + c! ;
: ram@  ( addr -- n )  dup ramc@ 8 lshift swap 1+ ramc@ or ;
: ram!  ( n addr -- )  over 8 rshift over ramc!  1+ ramc! ;

\ Stack access

: T ( -- n )  sp @ 1+ cells sp + @ ;
: R ( -- n )  rp @ 1+ cells rp + @ ;
: ?sp ( -- )  sp @ &10 u> abort" Stack wrap" ;
: ?rp ( -- )  rp @ 8 u> abort" Rstack wrap" ;
: pop ( -- n )  T  -1 sp +! ?sp ;
: push ( n -- ) 1 sp +! ?sp sp @ 1+ cells sp + ! ;
: rpop ( -- n )  R  -1 rp +! ?rp ;
: rpush ( n -- ) 1 rp +! ?rp rp @ 1+ cells rp + ! ;

\ Jumps

Vocabulary b16-sim  also b16-sim definitions also Forth

: nop   ;
: jmp   slot @ 3 = IF  pop P ! EXIT  THEN
        1 3 slot @ - 5 * lshift 1- dup Inst @ and
        swap invert P @ 2/ and or P ! 4 slot ! ;
: call  P @ rpush jmp ;
: ret   rpop P ! 4 slot ! ;
: jz    T 0= IF  jmp  THEN  4 slot ! ;
: jnz   T 0<> IF  jmp  THEN  4 slot ! ;
: jc    c @ IF  jmp  THEN  4 slot ! ;
: jnc   c @ 0= IF  jmp  THEN  4 slot ! ;

\ ALU

: xor  pop pop xor push ;
: com  pop $FFFF xor push ;
: and  pop pop and push ;
: or   pop pop or  push ;
: +rest dup $FFFF and push $10 rshift c ! ;
: add  pop pop +   +rest ;
: addc pop pop + c @ + +rest ;
: *+   pop c @ IF  T +  THEN  dup 2/ push 
  1 and $10 lshift A @ or  dup 1 and c ! 2/ A ! ;
: /-   pop dup T + 1+  dup $10 rshift c @ or dup >r
  IF  nip  ELSE  drop  THEN  $10 lshift A @ or
  dup $1F rshift c !  2* r> or  dup $FFFF A ! $10 rshift push ;

\ Memory

: A@  A @ ram@ push ;
: A!  pop A @ ram! ;
: R@  R ram@ push ;
: Ac@ A @ ramc@ push ;
: Ac! pop A @ ramc! ;
: Rc@ R ramc@ push ;
: A@+ A@ 2 A +! ;
: A!+ A! 2 A +! ;
: R@+ R@ rpop 2 + rpush ;
: Ac@+ Ac@ 1 A +! ;
: Ac!+ Ac! 1 A +! ;
: Rc@+ Rc@ rpop 1 + rpush ;

: @    pop ram@ push ;
: @+   pop dup ram@ push 2 + push ;
: @.   pop dup ram@ push push ;

: !    pop pop swap ram! ;
: !+   pop pop over ram! 2 + push ;
: !.   pop pop over ram! push ;

: c@   pop ramc@ push ;
: c@+  pop dup ramc@ push 1 + push ;
: c@.  pop dup ramc@ push push ;

: c!   pop pop swap ramc! ;
: c!+  pop pop over ramc! 1 + push ;
: c!.  pop pop over ramc! push ;

: lit P @ ram@ push  2 P +! ;
: litc P @ ramc@ push 1 P +! ;

\ stack

: nip  pop pop drop push ;
: drop pop drop ;
: over pop T swap push push ;
: dup  T push ;
: >r   pop rpush ;
: >a   pop A ! ;
: r>   rpop push ;
: a    A @ push ;

\ toplevel

Forth definitions
: (jmps) ( n1 n2 -- )  and cells r> + @ execute ;
: jmps ( n -- )  dup 1- postpone literal postpone (jmps)
  also b16-sim  0 ?DO  ' ,  LOOP  previous  postpone ; ;
  immediate

: <jmps>  [ 8 ] jmps  nop call jmp ret jz jnz jc jnc
: <ALUs>  [ 8 ] jmps  xor com and or add addc *+ /-
: <mem+>  1 cycles +! [ 8 ] jmps  !+ @+ @ lit  c!+ c@+ c@ litc
: <mem>   1 cycles +! [ 8 ] jmps  !. @. @ lit  c!. c@. c@ litc
: <stack> [ 8 ] jmps  nip drop over dup >r >a r> a
: <op23> dup 3 rshift [ 4 ] jmps <jmps> <ALUs> <mem+> <stack>
: <op1> dup 3 rshift [ 4 ] jmps <jmps> <ALUs> <mem> <stack>
: <op>  dup slot @ 0> or 0<> negate cycles +!
  1 slot +!  slot @ 2 = IF  <op1>  ELSE  <op23>  THEN ;
Defer <inst>  ' noop IS <inst>
: run  BEGIN  slot @ 4 = IF 
       P @ ram@ Inst ! 2 P +! slot off  THEN  <inst>
       Inst @ 3 slot @ - 5 * rshift <op>  AGAIN ;

\ trace

: .v base @ >r hex 4 0.r space r> base ! ;
Create i0
," nop call"
," nop calljmp ret jz  jnz jc  jnc xor com and or  +   +c  *+  /-  A!  A@  R@  lit Ac@ Ac! Rc@ litcnip dropoverdup >r  >a  r>  a   "
," nop calljmp ret jz  jnz jc  jnc xor com and or  +   +c  *+  /-  A!+ A@+ R@+ lit Ac@+Ac!+Rc@+litcnip dropoverdup >r  >a  r>  a   "
," nop execgotoret gz  gnz gc  gnc xor com and or  +   +c  *+  /-  A!+ A@+ R@+ lit Ac@+Ac!+Rc@+litcnip dropoverdup >r  >a  r>  a   "

: .inst cr P @ .v Inst @ 3 slot @ - 5 * rshift $1F and
    i0 slot @ 0 ?DO count + LOOP 1+ swap 4 * + 4 type space
    pop pop dup push over push swap .v .v ;
' .inst IS <inst>

previous previous

\ Assembler

Vocabulary b16-asm

Variable slot#  slot# off
Variable IP     IP off
Variable bundle bundle off
Variable extra-inc  extra-inc off 0 c, 0 c, 0 c, 0 c, 0 c, 0 c,
Variable old-einc
Variable listing  listing on

: .#4 base @ >r hex 0 <# # # # # #> type r> base ! ;
: .#2 base @ >r hex 0 <# # # #> type r> base ! ;
: .#1 base @ >r hex 0 <# # #> type r> base ! ;
: .slot# ( -- )    listing @ IF
	'# emit sourceline# . >in @ .
	'$ emit IP @ 2 +  extra-inc @ + .#4 space
	slot# @ 1- .#1 ."  pos," cr
    THEN ;
: .slot#2 ( -- )    listing @ IF
	'# emit sourceline# . >in @ .
	'$ emit IP @ .#4 space
	slot# @ .#1 ."  pos," cr
    THEN ;
: slot, ( -- )
    listing @ IF
	#tab emit source drop >in @ type cr
	'@ emit IP @ .#4 space bundle @ .#4 cr
	extra-inc @ 0 ?DO
	    '@ emit I cell+ extra-inc + c@ IP @ I 2 + + .#4 space .#2 cr
    LOOP
    THEN
    bundle @ IP @ ram!  2 IP +!
    extra-inc @ 0 ?DO
        I cell+ extra-inc + c@ IP @ ramc!  1 IP +!
    LOOP
    slot# off bundle off extra-inc off
    IP @ 1 and abort" odd IP" .slot#2 ;
: slot ( inst -- )
    slot# @ 4 = IF slot, THEN 
    dup 1 > slot# @ 0= and IF  1 slot# +!  THEN
    3 slot# @ - 5 * lshift bundle +! 1 slot# +!
    .slot# ;
: slot1 ( inst -- )
    BEGIN  slot# @ 1 <> WHILE  0 slot  REPEAT  slot ;
: slot23 ( inst -- )
    BEGIN  slot# @ 2 and 2 <> WHILE  0 slot  REPEAT  slot ;
: slot3 ( inst -- )
    BEGIN  slot# @ 3 <> WHILE  0 slot  REPEAT  slot ;
: inst ( n -- )  Create ,  DOES> @ slot ;
: inst1 ( n -- )  Create ,  DOES> @ slot1 ;
: inst23 ( n -- )  Create ,  DOES> @ slot23 ;
: inst3 ( n -- )  Create ,  DOES> @ slot3 ;
: insts ( n1 n -- )  bounds ?DO  I inst  LOOP ;
: insts1 ( n1 n -- )  bounds ?DO  I inst1  LOOP ;
: insts23 ( n1 n -- )  bounds ?DO  I inst23  LOOP ;
: insts3 ( n1 n -- )  bounds ?DO  I inst3  LOOP ;

: addrmask ( -- mask ) $7FFF slot# @ 5 * rshift ;
: fit? ( addr -- flag )  2/ addrmask
    IP @ 2/ 1+ over invert and >r over and r> or = ;
: inst, ( -- )  slot# @ 0= ?EXIT
    BEGIN  slot# @ 4 < WHILE  0 slot  REPEAT  slot, ;
: jmp, ( addr inst -- ) over fit? 0= IF inst, THEN
    swap 2/ addrmask and
    over 1 <> IF  $3FF and  THEN  bundle +!
    slot 4 slot# ! ( inst, ) ;
: jmp ( inst -- )  Create , DOES> @ jmp, ;
: jmps ( start n -- ) bounds ?DO  I jmp  LOOP ;

: clit, ( n -- ) extra-inc dup @ cell+ + c! 1 extra-inc +! ;

also B16-asm definitions

: F Forth ' state @ IF  compile,  ELSE  execute  THEN  B16-asm ; immediate
: c, ( n -- )   IP @ ramc!  1 IP +! ;
: ,  ( c -- )   IP @ ram!   2 IP +! ;
: align ( -- )  inst, IP @ 1 and IP +! ;
: org ( n -- )  inst, IP ! .slot#2 ;
: $, ( addr u -- )
    bounds ?DO
        I c@ c,  LOOP ;

$02 1 jmps    jmp
$04 4 jmps    jz   jnz  jc   jnc
$10 8 insts   !*   @*   @   lit  c!* c@* c@  litc
$10 2 insts1  !.   @.
$14 2 insts1  c!.  c@.
$10 2 insts23 !+   @+
$14 2 insts23 c!+  c@+

: # ( n -- ) lit \ bl sword s>number drop
    $FFFF and $100 /mod clit, clit, ;
: #c ( n -- ) litc \ bl sword s>number drop
    clit, ;

also Forth
: BEGIN  inst, IP @ ;
: fws  slot# @ 2 > IF  inst,  THEN  IP @ $FFC0 2dup and ;
: fw   inst, IP @ $FC00 2dup and ;
b16-asm
: AHEAD  fw jmp ;
: sAHEAD  fws jmp ;
: AGAIN ( addr -- )  jmp ;
: UNTIL ( addr -- )  jz ;
: -UNTIL ( addr -- )  jnz ;
: cUNTIL ( addr -- )  jnc ;
: -cUNTIL ( addr -- )  jc ;
: IF   fw jz ;
: -IF  fw jnz ;
: -cIF fw jc ;
: cIF  fw jnc ;
: IFs   fws jz ;
: -IFs  fws jnz ;
: -cIFs fws jc ;
: cIFs  fws jnc ;
: WHILE   >r fw jz r> ;
: -WHILE  >r fw jnz r> ;
: -cWHILE >r fw jc r> ;
: cWHILE  >r fw jnc r> ;
: sIF   fws jz ;
: -sIF  fws jnz ;
: -csIF fws jc ;
: csIF  fws jnc ;
Forth
: THEN ( addr mask -- ) inst,
    swap >r r@ ram@ over and swap invert IP @ 2/ and or r> ram! ;
b16-asm
: REPEAT ( addr1 addr2 -- )  jmp THEN ;
: ELSE  AHEAD  2swap  THEN ;
: sELSE  sAHEAD  2swap  THEN ;
Forth
0 Value fd
0 Value rom-start
$800 Value rom-end
: new-fd ( addr u -- ) r/w create-file throw to fd ;
: .mif-head ( addr u -- ) new-fd
    s" WIDTH = 8;" fd write-line throw
    s" DEPTH = 512;" fd write-line throw
    s" ADDRESS_RADIX = HEX;" fd write-line throw
    s" DATA_RADIX = HEX;" fd write-line throw
    s" CONTENT BEGIN" fd write-line throw ;
: .mif-head16 ( addr u -- ) new-fd
    s" WIDTH = 16;" fd write-line throw
    s" DEPTH = 512;" fd write-line throw
    s" ADDRESS_RADIX = HEX;" fd write-line throw
    s" DATA_RADIX = HEX;" fd write-line throw
    s" CONTENT BEGIN" fd write-line throw ;
: .mif-tail ( -- )  s" END;" fd write-line throw
    fd close-file throw ;
: .mif-dump ( val addr -- ) s"         " fd write-file throw
    0 <# #S #> fd write-file throw s"  : " fd write-file throw
    0 <# # # #> fd write-file throw s" ;" fd write-line throw ;
: .mif16-dump ( val addr -- ) s"         " fd write-file throw
    0 <# #S #> fd write-file throw s"  : " fd write-file throw
    0 <# # # # # #> fd write-file throw s" ;" fd write-line throw ;
: .mif ( "file" -- )  hex inst,
    parse-word .mif-head16
    rom-end rom-start ?DO I ram@ I rom-start - 2/ .mif16-dump 2 +LOOP
    .mif-tail decimal ;
: .hex ( start n "file" -- ) over swap hex
    parse-word new-fd
    bounds ?DO
	I over - 2/ 0 <# I ram@ 0 # # # # 2drop bl hold # # # # '@ hold #>
	fd write-line throw 2 +LOOP fd close-file throw  drop decimal ;
: .hexl ( start n "file" -- ) over swap hex
    parse-word new-fd
    bounds ?DO
	I over - 2/ 0 <# I ram@ 0 # # 2drop bl hold # # # # '@ hold #>
	fd write-line throw 2 +LOOP fd close-file throw  drop decimal ;
: .hexh ( start n "file" -- ) over swap hex
    parse-word new-fd
    bounds ?DO
	I over - 2/ 0 <# I ram@ 8 rshift 0 # # 2drop bl hold # # # # '@ hold #>
	fd write-line throw 2 +LOOP fd close-file throw  drop decimal ;
: .hexb ( start n "file" -- ) over swap hex
    parse-word new-fd
    bounds ?DO
	I over -    0 <# I ram@ 8 rshift 0 # # 2drop bl hold # # # # '@ hold #>
	fd write-line throw
	I over - 1+ 0 <# I ram@          0 # # 2drop bl hold # # # # '@ hold #>
	fd write-line throw
    2 +LOOP fd close-file throw  drop decimal ;
: .end inst, ;
: ;; inst, ;
: macro: : ;
: end-macro postpone ; ; immediate
: : Create  inst, IP @ , DOES> @ inst, 1 jmp, ;
: | Create  inst, IP @ , DOES> @ ;
: ' ' >body @ ;

$00 inst nop
$01 4 insts3 exec goto gz   gnz
$03 inst ret
$08 8 insts xor  com   and  or   +    +c   *+   /-
$18 8 insts nip  drop  over dup  >r   --2  r>   --3

macro: ;
  slot# @ 4 = bundle @ $8000 and and
  IF  slot# off  bundle @ $7FFF and 2* bundle off 2 jmp,
  ELSE  ret  THEN end-macro

macro: org inst, IP ! .slot#2 end-macro
  
previous previous definitions

\ communication program

s" bigforth" environment? [IF]  2drop
  
include serial.fs

dos also

0 value b16
: init ( -- )  s" /dev/b16" r/w bin open-file throw to b16
    B115200 b16 filehandle @ set-baud ;

: ?in ( -- )  pad b16 check-read b16 read-file throw pad swap type ;
: ?flush ( -- )  pad $100 + b16 check-read b16 read-file throw drop ;

: program ( addr u addr -- ) ?flush
    <# over hold $100 /mod swap hold hold '0 hold 0. #>
    b16 write-file throw b16 write-file throw ?flush ;

: check ( addr u -- ) ?flush swap
    <# over hold $100 /mod swap hold hold '1 hold 0. #>
    b16 write-file throw
    pad $F + -$10 and swap 2dup bounds ?DO
	I I' over - b16 read-file throw
    +LOOP  dump  ?flush ;

: exec ( addr -- ) ?flush
    <# $100 /mod swap hold hold '2 hold 0. #>
    b16 write-file throw ?in ;

previous b16-asm also Forth

: prog ( >defs -- )  also b16-asm interpret previous inst, ;
: comp ( >defs -- )
    IP @ >r prog r@ RAM + IP @ r@ - r> program ;
: eval ( >defs -- )
    IP @ >r comp r@ exec r> org &20 wait ?in ;
: sim  ( >defs -- )
    IP @ >r prog r@ P ! ['] run catch r> org ;

init

previous Forth
[ELSE]
b16-asm also Forth
[THEN]

: asm-load ( -- )  b16-asm definitions include forth definitions ;

previous Forth
\ asm-load boot.asm

