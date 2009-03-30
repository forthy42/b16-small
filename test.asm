#! /usr/bin/gforth b16-asm.fs
\ -*- forth-mode -*-
\ $Log: test.asm,v $
\ Revision 1.2  2004/02/18 16:11:25  berndp
\ Mostly working version (excluding SFRs to analog part)
\
\ Revision 1.1  2004/02/06 14:59:16  berndp
\ Self test first checkin
\
macro: swap ( a b -- b a ) over >r nip r> end-macro
$2000 org
	$AA56 ,
: error  BEGIN  AGAIN
: stack			\ stack test
    1 #c 2 #c 3 #	\ fill stack with 1 2 3 4 5 6 7 8 9 A B
    4 #c 5 #c
    + + + +
    $0f # xor IF  error  THEN \ !!! this checks stack depth, too !!!
;			\ return to caller
: alu			\ test ALU
    $1234 # $5678 # +	\ add two literals
    dup $68AC # xor IF  error  THEN
    $1234 # com +c	\ complement and add with carry = subtract
    $5678 # xor IF  error  THEN
    $1234 # $5678 # or	\ OR two literals
    dup $567C # xor IF  error  THEN
    $1234 # $5678 # and	\ AND two literals
    dup $1230 # xor IF  error  THEN
    xor	\ XOR the two results from above, and drop results
    $444C # xor IF  error  THEN
;			\ return to caller
: mul ( u1 u2 -- ud )	\ unsigned expanding multiplication
    >r			\ move multiplicant to register R
    0 # dup +		\ put zero on top of stack and clear carry flag
    *+ *+ *+ *+ *+ *+ *+ *+ *+ *+ *+ *+ *+ *+ *+ *+ *+
    			\ 17 mul-step instructions
    nip r> swap		\ drop second multiplicant, reorder results
;			\ return to caller
: div ( ud udiv -- uqout umod )	\ unsigned division with remainder
    com			\ invert divider
    >r over r> over >r nip >r nip r>	\ move low part of divident to A
    over 0 # +		\ copy high part of divider to top, clear carry
    /-  /- /- /- /-  /- /- /- /-  /- /- /- /-  /- /- /- /-
    			\ 17 div-step instructions
    nip nip r> over >r nip	\ reorder results
    0 # dup +c *+ drop r>	\ insert carry
;			\ return to caller
: muldiv
	$1234 # $5678 # mul
	$0626 # xor IF  error  THEN
	$0060 # xor IF  error  THEN
	$45C7 # $0626 # $0678 # div
	$042F # xor IF  error  THEN
	$F35D # xor IF  error  THEN 
	$45C7 # $0626 # $1678 # div
	$0E47 # xor IF  error  THEN
	$4610 # xor IF  error  THEN 
	$45C7 # $0626 # $2678 # div
	$0F27 # xor IF  error  THEN
	$28EC # xor IF  error  THEN 
	$45C7 # $0626 # $3678 # div
	$35F7 # xor IF  error  THEN
	$1CE6 # xor IF  error  THEN 
	$45C7 # $0626 # $4678 # div
	$02FF # xor IF  error  THEN
	$1657 # xor IF  error  THEN 
	$45C7 # $0626 # $5678 # div
	$4567 # xor IF  error  THEN
	$1234 # xor IF  error  THEN 
	$45C7 # $0626 # $6678 # div
	$042F # xor IF  error  THEN
	$0F5D # xor IF  error  THEN 
	$45C7 # $0626 # $7678 # div
	$658F # xor IF  error  THEN
	$0D49 # xor IF  error  THEN 
	$45C7 # $0626 # $8678 # div
	$0AEF # xor IF  error  THEN
	$0BB5 # xor IF  error  THEN 
	$45C7 # $0626 # $9678 # div
	$3A77 # xor IF  error  THEN
	$0A76 # xor IF  error  THEN 
	$45C7 # $0626 # $A678 # div
	$9F67 # xor IF  error  THEN
	$0974 # xor IF  error  THEN 
	$45C7 # $0626 # $B678 # div
	$7AC7 # xor IF  error  THEN
	$08A0 # xor IF  error  THEN 
	$45C7 # $0626 # $C678 # div
	$7A37 # xor IF  error  THEN
	$07EE # xor IF  error  THEN 
	$45C7 # $0626 # $D678 # div
	$1AFF # xor IF  error  THEN
	$0757 # xor IF  error  THEN 
	$45C7 # $0626 # $E678 # div
	$9A67 # xor IF  error  THEN
	$06D4 # xor IF  error  THEN 
	$45C7 # $0626 # $F678 # div
	$255F # xor IF  error  THEN
	$0663 # xor IF  error  THEN 
	\ multiply 1234 with 5678 (hex)
	$0123 # $0626 # $a987 # div
	$942b # xor IF  error  THEN
	$0948 # xor IF  error  THEN ;
: jumps			\ test a few jumps
    0 #c 1 #c    -IF  drop 3 # + THEN  drop \ jump if non-zero
    0 #c 0 #c     IF  drop 4 # + THEN  drop \ jump if zero
    0 # com     -cIF  drop 5 # + THEN  drop \ jump if carry
    0 #c 0 #c +  cIF  drop 6 # + THEN  drop \ jump if no carry
;			\ return to caller
: -jumps		\ test a few jumps the other way round
    0 #c 1 #c     IF  drop 3 # + THEN
    0 #c 0 #c    -IF  drop 4 # + THEN
    0 # com      cIF  drop 5 # + THEN
    0 #c 0 #c + -cIF  drop 6 # + THEN
;			\ return to caller
: stackop
    1 #c 2 #c dup >r over >r over over + >r
    r> + r> + r> + +
    9 # xor IF  error  THEN ;
: loadstore
    $5678 # $1234 # 0 # !+ !+ drop
    0 # @+ @+ drop +
    dup $68AC # xor IF  error  THEN
\    1 # @+ @+ drop +
\    dup $AC68 # xor IF  error  THEN
\    $5678 # $1234 # 1 # !+ !+ drop
\    0 # @+ @+ drop +
\    dup $AC68 # xor IF  error  THEN
\    1 # @+ @+ drop +
\    dup $68AC # xor IF  error  THEN
    $1234 # 4 # !+ drop
    4 # c@+ c@+ drop +
    dup $46 # xor  IF error  THEN
;
: boot
	$0 # $10 # !* drop
	$0 # $42E # !* drop
    BEGIN stack		\ call stack test
	alu			\ call ALU test
	muldiv		\ call muldiv tests
	jumps -jumps	\ call jump tests
	loadstore           \ call load store tests
	stackop
	$F000 # $0102 # !* drop
	$0000 # $0100 # !* drop
	$10 # @ 1 # + $10 # !* drop
    AGAIN ;
$3FFE org
     boot ;;
$2000 $2000 .hex b16.hex	\ print verilog hex for $2000 bytes
$2000 $2000 .hexb b16b.hex	\ print verilog hex for $2000 bytes
.mif test.mif
$21FE org
     boot ;;
$2000 $200 .hexb b16b.ee8
.end			\ end of test program
