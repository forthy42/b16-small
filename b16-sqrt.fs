\ Der auskommentierte Code laeuft auf 32b Forth
\ : sqrt ( +d -- +n )  0
\  $10 0 DO  2* >r d2* d2*
\            r@ 2* 1+ 2dup u>= IF  - r> 1+ >r  ELSE  drop  THEN
\            r> LOOP  nip nip ;

\ Dieser Code laeuft auf b16

: 48b-d4* >r >r dup + r> dup +c r> dup +c
          >r >r dup + r> dup +c r> dup +c ;

: sqr-  2* >r 48b-d4* 
        r> dup >r 2* 1+ over over u< 0= ( u>= )
        IF - r> 1+ >r ELSE drop THEN
        r> ;

: sqrt ( d -- n ) 0 # dup
    sqr- sqr- sqr- sqr-  sqr- sqr- sqr- sqr-
    sqr- sqr- sqr- sqr-  sqr- sqr- sqr- sqr-  nip nip nip ;

\    &1     # dup mul sqrt >h +l
\    &2     # dup mul sqrt >h +l
\    &3     # dup mul sqrt >h +l
\    &10    # dup mul sqrt >h +l
\    &100   # dup mul sqrt >h +l
\    &10000 # dup mul sqrt >h +l
\    &30000 # dup mul sqrt >h +l
\    $FFFE  # dup mul sqrt >h +l  \ groesst moegliche Zahl
