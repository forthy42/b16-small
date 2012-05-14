\ Erweiterungen für b16-small

macro: error  BEGIN  AGAIN  end-macro
macro: swap ( a b -- b a ) over >r nip r> end-macro
macro: ! ( a b -- )  !* drop  end-macro

macro: cell   2 #    end-macro
macro: cell+  2 #  + end-macro
macro: 2cell+ 4 #  + end-macro
macro: cells  dup  + end-macro

macro: r@ r> dup >r end-macro

macro: EXIT ; end-macro

macro: ?EXIT IF ; THEN end-macro

macro: - com +c end-macro

macro: negate com 0 # +c end-macro

: rot ( n1 n2 n3 -- n2 n3 n1 ) >r swap r> swap ;

macro: 2drop drop drop end-macro

: 0=  ( n -- flg ) 
   IF 0 # ELSE -1 # THEN ;

: 0<  ( n -- flg )
   $8000 # and IF -1 # ELSE 0 # THEN ;

macro: <   ( n1 n2 -- flag )
   - 0< end-macro

macro: >   ( n1 n2 -- flag )
   swap - 0< end-macro

macro: =   ( n1 n2 -- flag )
   xor 0= end-macro

: u<  ( u1 u2 -- flag )
   com +c cIF 0 # ELSE -1 # THEN ;

: ?dup ( n -- n n | 0 )
   dup IF dup THEN ;

: abs ( n -- u )
   dup 0< IF com 0 # +c THEN ;

: max ( n1 n2 -- n1 | n2 )
   over over - 0<
   IF nip ELSE drop THEN ;

: min ( n1 n2 -- n1 | n2 )
   over over - 0<
   IF drop ELSE nip THEN ;

macro: 1- 1 # - end-macro
macro: 2- 2 # - end-macro

macro: 1+ 1 # + end-macro
macro: 2+ 2 # + end-macro

macro: +! ( n adr -- )
       dup >r @ + r> ! end-macro

: within ( n low high -- flag )
   over - >r - r> u< ;

macro: d+ ( d1 d2 - d3 )  >r rot + swap r> +c end-macro

macro: d- ( d1 d2 - d3 )  >r com rot + swap r> com +c end-macro

macro: 2* ( n1 -- 2*n1 )  dup + end-macro

macro: d2* ( d -- 2*d )   over over d+ end-macro

macro: 2dup over over end-macro
macro: under swap over end-macro

: u2/ >r $0000 # *+ drop r> $7FFF # and ;
: 2/  u2/ dup $4000 # and dup + + ;

: mul ( u1 u2 -- ud )   \ unsigned expanding multiplication
    >r                  \ move multiplicant to register R
    0 # dup +           \ put zero on top of stack and clear carry flag
    *+ *+ *+ *+ *+ *+ *+ *+ *+ *+ *+ *+ *+ *+ *+ *+ *+
                        \ 17 mul-step instructions
    nip r> swap         \ drop second multiplicant, reorder results
;                       \ return to caller

: usmul ( u1 s2 -- d )  \ unsigned by signed mul
    dup $8000 # and IF  over >r  ELSE  0 # >r  THEN
    mul r> - ;

: div ( ud udiv -- uqout umod ) \ unsigned division with remainder
    com                 \ invert divider
    >r over r> over >r nip >r nip r>    \ move low part of divident to A
    over 0 # +          \ copy high part of divider to top, clear carry
    /-  /- /- /- /-  /- /- /- /-  /- /- /- /-  /- /- /- /-
                        \ 17 div-step instructions
    nip nip r> over >r nip      \ reorder results
    0 # dup +c *+ drop r>       \ insert carry
;                       \ return to caller

: lshift ( n1 rs -- n2 )
    BEGIN dup WHILE >r 2* r> 1- REPEAT drop ;

