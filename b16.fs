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

warnings off

[IFUNDEF] $! include string.fs [THEN]

: 0.r ( n r -- )  0 swap <# 0 ?DO # LOOP #> type ;

\ Variables

#34 Constant max-sp
#16 Constant max-rp

Variable Inst
Variable P
Variable c
Variable sp  here #34 cells dup allot erase  2 sp !
Variable rp  here #16 cells dup allot erase
Variable slot  4 slot !
Variable cycles

: sim-reset  $3FFE P !  2 sp ! 0 rp ! 4 slot ! ;

\ RAM access

$10000 allocate throw Value RAM  RAM $10000 erase
: ramc@ ( addr -- n )  $FFFF and RAM + c@ ;
: ramc! ( n addr -- )  $FFFF and RAM + c! ;
: ram@  ( addr -- n )  dup ramc@ 8 lshift swap 1 xor ramc@ or ;
: ram!  ( n addr -- )  over 8 rshift over ramc!  1 xor ramc! ;

\ Stack access

: T ( -- n )  sp @ 1+ cells sp + @ ;
: N ( -- n )  sp @    cells sp + @ ;
: R ( -- n )  rp @ 1+ cells rp + @ ;
: !R ( n -- )  rp @ 1+ cells rp + ! ;
: ?sp ( -- )  sp @ max-sp u> abort" Stack wrap" ;
: ?rp ( -- )  rp @ max-rp u> abort" Rstack wrap" ;
: pop ( -- n )  T  -1 sp +! ?sp ;
: dpush ( n -- ) 1 sp +! ?sp sp @ 1+ cells sp + ! ;
: rpop ( -- n )  R  -1 rp +! ?rp ;
: rpush ( n -- ) 1 rp +! ?rp !R ;

\ Jumps

Vocabulary b16-sim  also b16-sim definitions also Forth

: nop   ;
: (jmp)   slot @ 4 = IF  pop P ! EXIT  THEN
    1 4 slot @ - 5 * lshift 1- dup Inst @ and
    swap invert P @ 2/ and or 2* P ! ;
: jmp   (jmp)  4 slot ! ;
: call  P @ rpush jmp ;
: ret   rpop P ! 4 slot ! ;
: ?drop slot @ 4 < IF  pop drop  THEN 4 slot ! ;
: jz    T 0=   IF  (jmp)  THEN  ?drop ;
: jnz   T 0<>  IF  (jmp)  THEN  ?drop ;
: jc    c @    IF  (jmp)  THEN  ?drop ;
: jnc   c @ 0= IF  (jmp)  THEN  ?drop ;

\ ALU

: +rest dup $FFFF and dpush $10 rshift c ! ;
: add  pop pop +   +rest ;
: addc pop pop + c @ + +rest ;
: *+   pop c @ IF  T +  THEN  dup 2/ dpush 
  1 and $10 lshift R or  dup 1 and c ! 2/ !R ;
: /-   pop dup T + 1+  dup $10 rshift c @ or dup >r
  IF  nip  ELSE  drop  THEN  $10 lshift R or
  dup $1F rshift c !  2* r> or  dup $FFFF and !R $10 rshift dpush ;
: and  pop pop and dpush ;
: or   pop pop or  dpush ;
: com  pop $FFFF xor dpush 1 c ! ;
: xor  pop pop xor dpush ;

\ Memory

: @    pop ram@ dpush ;
: @+   pop dup ram@ dpush 2 + dpush ;
: @.   pop dup ram@ dpush dpush ;

: !    pop pop swap ram! ;
: !+   pop pop over ram! 2 + dpush ;
: !.   pop pop over ram! dpush ;

: c@   pop ramc@ dpush ;
: c@+  pop dup ramc@ dpush 1 + dpush ;
: c@.  pop dup ramc@ dpush dpush ;

: c!   pop pop swap ramc! ;
: c!+  pop pop over ramc! 1 + dpush ;
: c!.  pop pop over ramc! dpush ;

: lit P @ ram@ dpush  2 P +! ;
: litc P @ ramc@ dpush 1 P +! ;

\ stack

: nip  pop pop drop dpush ;
: drop pop drop ;
: over pop T swap dpush dpush ;
: dup  T dpush ;
: >r   pop rpush ;
\ : >a   pop A ! ;
: r>   rpop dpush ;
\ : a    A @ push ;

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
: <stack> [ 8 ] jmps  nip drop over dup >r noop r> noop
: <op23> dup 3 rshift [ 4 ] jmps <jmps> <ALUs> <mem+> <stack>
: <op1> dup 3 rshift [ 4 ] jmps <jmps> <ALUs> <mem> <stack>
: <op>  dup slot @ 0> or 0<> negate cycles +!
  1 slot +!  slot @ 2 = IF  <op1>  ELSE  <op23>  THEN ;
Defer <inst>  ' noop IS <inst>
: step  slot @ 4 = IF 
       P @ ram@ Inst ! 2 P +! slot off  THEN  <inst>
       Inst @ 3 slot @ - 5 * rshift <op> ;
: steps  0 ?DO  step  LOOP ;
: run  BEGIN  step  AGAIN ;

\ trace

: .v base @ >r hex 4 0.r space r> base ! ;
: .<> base @ >r hex 0 <# '>' hold #S '<' hold #> type r> base ! ;
Create i0
," nop call"
," nop execgotoret jz  jnz jc  jnc xor com and or  +   +c  *+  /-  !.  @.  @   lit c!. c@. c@  litcnip dropoverdup >r  --  r>  --  "
," nop calljmp ret jz  jnz jc  jnc xor com and or  +   +c  *+  /-  !+  @+  @   lit c!+ c@+ c@  litcnip dropoverdup >r  --  r>  --  "
," nop calljmp ret gz  gnz gc  gnc xor com and or  +   +c  *+  /-  !+  @+  @   lit c!+ c@+ c@  litcnip dropoverdup >r  --  r>  --  "

: .inst cr P @ .v slot @ 1 .r ':' emit Inst @ 3 slot @ - 5 * rshift $1F and
    i0 slot @ 0 ?DO count + LOOP 1+ swap 4 * + 4 type space
    sp @ .<> T .v N .v rp @ .<> R .v ;

: trace-on   ['] .inst IS <inst> ;
: trace-off  ['] noop  IS <inst> ;

trace-on

previous previous

\ Assembler

Vocabulary b16-asm

Variable slot#  slot# off
Variable IP     IP off
Variable bundle bundle off
Variable extra-inc  extra-inc off 0 c, 0 c, 0 c, 0 c, 0 c, 0 c,
Variable old-einc
Variable listing? listing? off
Variable listpos? listpos? on
Variable listing
Create pos-field 0 , 0 , 0 , 0 ,
: pos,  pos-field 2! pos-field 2 cells + 2!
    pos-field 4 cells listing $+! ;
: search-listing ( addr step -- line char )
    listing @ 0= ?EXIT
    listing $@ bounds ?DO
        over I cell+ @ =  over I @ = and
        IF  2drop I 2 cells + 2@ swap 1- swap unloop EXIT  THEN
    4 cells +LOOP  2drop 0 0 ;

: search-line ( line -- addr/-1 )
    listing @ 0= ?EXIT
    listing $@ bounds ?DO
        dup I 3 cells + @ = I @ 0= and  IF  drop I cell+ @ unloop  EXIT  THEN
    4 cells +LOOP  drop -1 ;

[IFUNDEF] sourceline#  : sourceline# line @ ; [THEN]

: hier IP @ ;
: include listpos? @ >r listpos? off ['] include catch r> listpos? ! throw ;
: .#4 base @ >r hex 0 <# # # # # #> type r> base ! ;
: .#2 base @ >r hex 0 <# # # #> type r> base ! ;
: .#1 base @ >r hex 0 <# # #> type r> base ! ;
: >in? ( -- n )  0 source drop >in @ bounds ?DO
	I c@ #tab = IF  8 + -8 and  ELSE  1+  THEN  LOOP ;
: .slot# ( -- )    listing? @ IF
	'# emit sourceline# . >in? .
	'$ emit hier 2 +  extra-inc @ + .#4 space
	slot# @ 1- .#1 ."  pos," cr
    THEN
    listing @ listpos? @ and IF
    	sourceline# >in? hier 2 + extra-inc @ + slot# @ 1- pos,
    THEN ;
: .slot#2 ( -- )    listing? @ IF
	'# emit sourceline# . >in? .
	'$ emit hier .#4 space
	slot# @ .#1 ."  pos," cr
    THEN
    listing @ listpos? @ and IF
    	sourceline# >in? hier slot# @ pos,
    THEN ;
: slot, ( -- )
    listing? @ IF
	#tab emit source drop >in? type cr
	'@ emit hier .#4 space bundle @ .#4 cr
	extra-inc @ 0 ?DO
	    '@ emit I cell+ extra-inc + c@ hier I 2 + + .#4 space .#2 cr
    LOOP
    THEN
    bundle @ hier ram!  2 IP +!
    extra-inc @ 0 ?DO
        I cell+ extra-inc + c@ hier ramc!  1 IP +!
    LOOP
    slot# off bundle off extra-inc off
    hier 1 and abort" odd IP" .slot#2 ;
: >slot ( inst -- )
    slot# @ 4 = IF slot, THEN 
    dup 1 > slot# @ 0= and IF  .slot#2  1 slot# +!  THEN
    3 slot# @ - 5 * lshift bundle +! 1 slot# +!
    .slot# ;
: slot1 ( inst -- )
    BEGIN  slot# @ 1 <> WHILE  0 >slot  REPEAT  >slot ;
: slot23 ( inst -- )
    BEGIN  slot# @ 2 and 2 <> WHILE  0 >slot  REPEAT  >slot ;
: slot3 ( inst -- )
    BEGIN  slot# @ 3 <> WHILE  0 >slot  REPEAT  >slot ;
: inst ( n -- )  Create ,  DOES> @ >slot ;
: inst1 ( n -- )  Create ,  DOES> @ slot1 ;
: inst23 ( n -- )  Create ,  DOES> @ slot23 ;
: inst3 ( n -- )  Create ,  DOES> @ slot3 ;
: insts ( n1 n -- )  bounds ?DO  I inst  LOOP ;
: insts1 ( n1 n -- )  bounds ?DO  I inst1  LOOP ;
: insts23 ( n1 n -- )  bounds ?DO  I inst23  LOOP ;
: insts3 ( n1 n -- )  bounds ?DO  I inst3  LOOP ;

: addrmask ( -- mask ) $7FFF slot# @ 5 * rshift ;
: fit?' ( addr mask -- flag )
    hier 2/ 1+ over and >r and r> = ;
: fit? ( addr -- flag )  2/ addrmask invert fit?' ;
: inst, ( -- )  slot# @ 0= ?EXIT
    BEGIN  slot# @ 4 < WHILE  0 >slot  REPEAT  slot, ;
: jmp, ( addr inst -- ) over fit? 0= IF
	inst, over 1 <> IF  0 >slot  THEN  THEN
    over fit? 0= abort" jmp across 2k/64b boundary!"
    swap 2/ addrmask and
    over 1 <> IF  $3FF and  THEN  bundle +!
    >slot 4 slot# ! ( inst, ) ;
: jmp ( inst -- )  Create , DOES> @ jmp, ;
: jmps ( start n -- ) bounds ?DO  I jmp  LOOP ;

: clit, ( n -- ) extra-inc dup @ cell+ + c! 1 extra-inc +! ;

also B16-asm definitions

: F Forth ' state @ IF  compile,  ELSE  execute  THEN  B16-asm ; immediate
: c, ( n -- )   hier ramc!  1 IP +! ;
: ,  ( c -- )   hier ram!   2 IP +! ;
: align ( -- )  inst, hier 1 and IP +! ;
: org ( n -- )  inst, IP ! .slot#2 slot# off ;
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
: BEGIN  inst, hier ;
: fws  slot# @ 2 > IF  inst,  THEN  hier $FFC0 over ;
: fw   inst, hier $FC00 over ;
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
    over 2/ over fit?' 0= abort" resolve across 2k/64b boundary!"
    swap >r r@ ram@ over and swap invert hier 2/ and or r> ram! ;
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
    parse-name .mif-head16
    rom-end rom-start ?DO I ram@ I rom-start - 2/ .mif16-dump 2 +LOOP
    .mif-tail decimal ;
: .hex ( start n "file" -- ) over swap hex
    parse-name new-fd
    bounds ?DO
	I over - 2/ 0 <# I ram@ 0 # # # # 2drop bl hold # # # # '@ hold #>
	fd write-line throw 2 +LOOP fd close-file throw  drop decimal ;
: .hexl ( start n "file" -- ) over swap hex
    parse-name new-fd
    bounds ?DO
	I over - 2/ 0 <# I ram@ 0 # # 2drop bl hold # # # # '@ hold #>
	fd write-line throw 2 +LOOP fd close-file throw  drop decimal ;
: .hexh ( start n "file" -- ) over swap hex
    parse-name new-fd
    bounds ?DO
	I over - 2/ 0 <# I ram@ 8 rshift 0 # # 2drop bl hold # # # # '@ hold #>
	fd write-line throw 2 +LOOP fd close-file throw  drop decimal ;
: .hexb ( start n "file" -- ) over swap hex
    parse-name new-fd
    bounds ?DO
	I over -    0 <# I ram@ 8 rshift 0 # # 2drop bl hold # # # # '@ hold #>
	fd write-line throw
	I over - 1+ 0 <# I ram@          0 # # 2drop bl hold # # # # '@ hold #>
	fd write-line throw
    2 +LOOP fd close-file throw  drop decimal ;
: .hex' ( start n "file" -- ) over swap hex
    parse-name new-fd
    bounds ?DO
	I over - 2/ 0 <# I ram@ 0 # # # # 2drop #>
	fd write-line throw 2 +LOOP fd close-file throw  drop decimal ;
: .hexl' ( start n "file" -- ) over swap hex
    parse-name new-fd
    bounds ?DO
	I over - 2/ 0 <# I ram@ 0 # # 2drop #>
	fd write-line throw 2 +LOOP fd close-file throw  drop decimal ;
: .hexh' ( start n "file" -- ) over swap hex
    parse-name new-fd
    bounds ?DO
	I over - 2/ 0 <# I ram@ 8 rshift 0 # # 2drop #>
	fd write-line throw 2 +LOOP fd close-file throw  drop decimal ;
: .hexb' ( start n "file" -- ) over swap hex
    parse-name new-fd
    bounds ?DO
	I over -    0 <# I ram@ 8 rshift 0 # # 2drop #>
	fd write-line throw
	I over - 1+ 0 <# I ram@          0 # # 2drop #>
	fd write-line throw
    2 +LOOP fd close-file throw  drop decimal ;
: .end inst, ;
: ;; inst, ;
: macro: : ;
: end-macro postpone ; ; immediate
: : Create  inst, hier , .slot#2 DOES> @ inst, 1 jmp, ;
: | Create  inst, hier , .slot#2 DOES> @ ;
: |# Create  inst, hier , .slot#2 DOES> @ [ b16-asm ] # [ forth ] ;
: Label Create  inst, hier , .slot#2 DOES> @ [ b16-asm ] # [ forth ] ;
: ' ' >body @ ;

$00 inst nop
$01 4 insts3 exec goto gz   gnz
$03 inst ret
$08 8 insts xor  com   and  or   +    +c   *+   /-
$18 8 insts nip  drop  over dup  >r   --2  r>   --3

: ;
  slot# @ 4 = bundle @ $8000 and and
  bundle @ $7C00 and 2* hier $F800 and = and
  IF  slot# off  bundle @ $7FFF and 2* bundle off 2 jmp,
  ELSE  ret  THEN end-macro

: org inst, IP ! .slot#2 end-macro
  
previous previous definitions

\ communication program

s" bigforth" environment? [IF]  2drop
  
include b16-serial.fs
include regmap.fs

: b16-stop ( -- ) DBG_STATE dbg@ drop ;
: b16-run  ( -- ) DBG_STATE dbg@ $1000 or DBG_STATE dbg! ;
: b16-step  ( -- ) DBG_STATE dbg@ $1000 invert and DBG_STATE dbg! ;
: b16-steps ( n -- ) 0 ?DO  b16-step  LOOP ;
: b16-reset ( -- )  b16-stop  $3FFE DBG_P dbg! 0 DBG_I dbg! 0 DBG_STATE dbg! ;

Variable breakpoint

: bp! ( addr -- )  dup breakpoint ! DBG_BP dbg! ;
: set-bp ( addr -- )  bp! ;
: clear-bp ( addr -- )  drop $FFFF set-bp ;
: find-bp? ( addr -- inst flag )
    breakpoint @ = 0 swap ;

\ upload program

$2000 Value rom-offset
$2000 Value rom-size
Variable spi-addr

: >hex ( addr u -- )  base @ >r hex
    over c@ '@ = IF
	0. 2swap 1 /string >number 2swap drop 2* rom-offset + spi-addr !
	bl skip THEN  0. 2swap >number 2drop drop spi-addr @
    2 spi-addr +!  r> base ! ;

: include-hex ( addr u -- )
    b16-reset
    r/o open-file throw >r
    BEGIN  pad c/l r@ read-line throw  WHILE  pad swap >hex dbg!
    REPEAT  drop r> close-file throw ;

: postfix? ( addr1 u1 addr2 u2 -- flag )
    tuck 2>r over swap - 0 max /string 2r> str= ;

: upload ( -- )  record-dbg >r  false to record-dbg
    b16-reset rom-offset rom-size bounds ?DO
	I ram@ I dbg!
    2 +LOOP b16-run  r> to record-dbg ;

\ read processor status

16 Constant stack-depth
Create regs  5 2* allot
here stack-depth 4* allot
Constant stack

also forth

: load-regs ( -- )
  DBG_P regs 4 dbg@s
  DBG_STATE dbg@ regs 8 + w!
  0 DBG_I dbg! \ set instruction register to 0 to read stacks
  stack stack-depth 4* bounds DO  DBG_S[] I 2 dbg@s  4 +LOOP
  regs 6 + w@ DBG_I dbg! ;

: .regs ( -- ) base @ >r hex
    ." P: " regs w@ 4 0.r ."  I: " regs 6 + w@ 4 0.r ."  S: " regs 8 + w@ 4 0.r cr
    ." T: " regs 2 + w@ 4 0.r
    stack stack-depth 4* bounds DO  I w@ space 4 0.r 4 +LOOP cr
    ." R: " regs 4 + w@ 4 0.r
    stack 2+ stack-depth 4* bounds DO  I w@ space 4 0.r 4 +LOOP cr r> base ! ;

: exec ( addr -- )  drop ( tbd ) ;

previous b16-asm also Forth

: prog ( >defs -- )  also b16-asm interpret previous inst, ;
: comp ( >defs -- )
    hier >r prog r@ RAM + hier r@ - r> dbg!s ;
: eval ( >defs -- )
    hier >r comp r@ exec r> org &20 wait ?in ;
: sim  ( >defs -- )
    hier >r prog r@ P ! 0 rp ! 4 slot ! ['] run catch drop r> org ;

Forth
[ELSE]
b16-asm also Forth
[THEN]

[IFUNDEF] f+ import float also float
[ELSE] : f-init ; [THEN]

: asm-load ( -- )
    s" " listing $! float also f-init b16-asm definitions include previous forth definitions ;

: asm-included ( addr u -- )
    s" " listing $! float also f-init b16-asm definitions included previous forth definitions ;

previous Forth
\ asm-load boot.asm

[IFDEF] b16-debug
    b16-debug ptr b16d
[THEN]

[THEN]
