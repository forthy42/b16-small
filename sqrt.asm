macro: swap ( a b -- b a ) over >r nip r> end-macro
macro: ! ( a b -- )  !. drop  end-macro
include regmap.asm
$2000 org

macro: r@ r> dup >r end-macro
macro: 2* dup + end-macro
macro: 2*c dup +c end-macro
: t4*
    >r >r 2* r> 2*c r> 2*c
    >r >r 2* r> 2*c r> 2*c ;
: sqr- 2* >r t4* r@ 2* 1 # + com +c dup
    cIF  r> 1 # + >r  ELSE  r@ 2* 1 # + +  THEN
r> ;
: sqrt 0 # dup
    sqr- sqr- sqr- sqr-
    sqr- sqr- sqr- sqr-
    sqr- sqr- sqr- sqr-
    sqr- sqr- sqr- sqr-
    nip nip nip ;
: boot
    BEGIN
        4 # 0 # sqrt
        drop
        16 # 0 # sqrt
        drop
        $5678 # $1234 # sqrt
        drop
    AGAIN ;
$3FFE org
     boot ;;


