#! /usr/local/bin/xbigforth
\ automatic generated code
\ do not edit

also editor also minos also forth

component class b16-state
public:
  infotextfield ptr p#
  infotextfield ptr i#
  infotextfield ptr s#
  toggleicon ptr stoptoggle
  textfield ptr steps#
  infotextfield ptr t#
  infotextfield ptr s0#
  infotextfield ptr s1#
  infotextfield ptr s2#
  infotextfield ptr s3#
  infotextfield ptr r#
  infotextfield ptr r0#
  infotextfield ptr r1#
  infotextfield ptr r2#
  infotextfield ptr r3#
 ( [varstart] ) cell var stopped
method update ( [varend] ) 
how:
  : params   DF[ 0 ]DF s" b16 state" ;
class;

component class b16-ide
public:
  canvas ptr breakpoints
  stredit ptr code-source
 ( [varstart] ) cell var first-time ( [varend] ) 
how:
  : params   DF[ 0 ]DF s" b16 IDE" ;
class;

component class b16-mem
public:
  infotextfield ptr addr#
  infotextfield ptr data#
  infotextfield ptr n#
  infotextfield ptr status#
 ( [varstart] )  ( [varend] ) 
how:
  : params   DF[ 0 ]DF s" b16 load store" ;
class;

component class b16-debug
public:
  b16-state ptr state-comp
  b16-ide ptr ide-comp
 ( [varstart] )  ( [varend] ) 
how:
  : params   DF[ 0 ]DF s" b16 Debugger" ;
class;

include b16.fs
b16-debug implements
 ( [methodstart] ) : bp-watch  recursive  ^ dpy cleanup
    status@ $1 and 0= IF
      state-comp with
          stoptoggle with set draw endwith update
      endwith
    THEN
    ['] bp-watch ^ &100 after dpy schedule ;
order
: show  self F bind b16d bp-watch super show ; ( [methodend] ) 
  : widget  ( [dumpstart] )
        ^^ CP[  ]CP ( MINOS ) b16-mem new 
        ^^ CP[  ]CP ( MINOS ) b16-state new  ^^bind state-comp
        ^^ CP[  ]CP ( MINOS ) b16-ide new  ^^bind ide-comp
      #3 vabox new
    ( [dumpend] ) ;
class;

b16-mem implements
 ( [methodstart] ) : assign drop ; ( [methodend] ) 
  : widget  ( [dumpstart] )
          #0. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) X" Addr" infotextfield new  ^^bind addr#
          #0. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) X" Data" infotextfield new  ^^bind data#
            ^^ S[ addr# get drop u@ 0 data# assign ]S ( MINOS ) X" @" button new 
            ^^ S[ addr# get drop uc@ 0 data# assign ]S ( MINOS ) X" c@" button new 
            ^^ S[ data# get drop addr# get drop u! ]S ( MINOS ) X" !" button new 
            ^^ S[ data# get drop addr# get drop uc! ]S ( MINOS ) X" c!" button new 
          #4 hatbox new #1 hskips
        #3 habox new vfixbox  #1 hskips
          #0. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) X" N" infotextfield new  ^^bind n#
          ^^ S[ wini/o at? 2drop
addr# get drop n# get drop base @ >r hex
BEGIN  2dup scratch swap 2/ 8 min u@s
    cr over 0 <# # # # # #> type ." : "
    scratch over $10 umin bounds ?DO
        I c@ 0 <# # # #> type space
    LOOP
    $10 /string dup 0= UNTIL
2drop r> base !
 ]S ( MINOS ) X" Dump" button new 
          #0. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) X" status" infotextfield new  ^^bind status#
          ^^ S[ status@ 0 status# assign ]S ( MINOS ) X" status@" button new 
        #4 habox new vfixbox  #1 hskips
      #2 vabox new vfixbox  panel
    ( [dumpend] ) ;
class;

b16-ide implements
 ( [methodstart] ) : assign drop ;
: load-args
  argc @ arg# @ 1+ > IF
      argc @ arg# @ 1+ ?DO
                  I arg s" .asm" postfix? IF
                      I arg r/o open-file throw
                      code-source assign code-source resized
                      I arg asm-included
                  THEN
      LOOP
  THEN ;
: show first-time @ 0= IF load-args first-time on THEN
  super show ; ( [methodend] ) 
  : widget  ( [dumpstart] )
          ^^ S[  ]S ( MINOS )  icon" icons/load" icon-but new 
          ^^ S[  ]S ( MINOS )  icon" icons/save" icon-but new 
          ^^ S[  ]S ( MINOS )  icon" icons/run" icon-but new 
          $0 $1 *hfil $80 $1 *vfilll rule new 
        #4 vabox new hfixbox 
        1 1 viewport new  DS[ 
          CV[ 2 outer with code-source rows @ endwith
tuck 1 max steps
1 dpy xrc font@ font
1 2 textpos
hex
0 ?DO
    1 I home!
    I search-line dup -1 <> IF
       dup find-bp? nip IF  $CC $55 $55 rgb>pen
       ELSE  $55 $CC $55 rgb>pen  THEN  drawcolor
       0 <# # # # # #> text
    ELSE  drop  THEN
LOOP ]CV ( MINOS ) ^^ CK[ ( x y b n -- )
dup 1 and IF  2drop 2drop  EXIT  THEN
2drop nip
breakpoints h @ code-source rows @ / /
1+ search-line dup -1 = IF  drop  EXIT  THEN
dup find-bp? nip IF  clear-bp  ELSE  set-bp  THEN
breakpoints draw ]CK ( MINOS ) $20 $0 *hpix $0 $1 *vfilll canvas new  ^^bind breakpoints
             (straction stredit new  ^^bind code-source $40 setup-edit 
            $0 $1 *hfil $0 $1 *vfilll rule new 
          #2 vabox new
        #2 habox new ]DS ( MINOS ) 
      #2 habox new
    ( [dumpend] ) ;
class;

b16-state implements
 ( [methodstart] ) : assign drop ;
: update  stopped @ 0= ?EXIT  load-regs stopped dup @ >r off
  regs 0 + w@ 0 p# assign
  regs 2 + w@ 0 t# assign
  regs 4 + w@ 0 r# assign
  regs 6 + w@ 0 i# assign
  regs 8 + w@ 0 s# assign
  stack 0 + w@ 0 s0# assign
  stack 2 + w@ 0 r0# assign
  stack 4 + w@ 0 s1# assign
  stack 6 + w@ 0 r1# assign
  stack 8 + w@ 0 s2# assign
  stack 10 + w@ 0 r2# assign
  stack 12 + w@ 0 s3# assign
  stack 14 + w@ 0 r3# assign r> stopped !
  regs w@ regs 8 + w@ 8 rshift 3 and search-listing
  b16d ide-comp code-source at ;
: show  '$' 0
  2dup p# keyed  2dup t# keyed  2dup r# keyed  2dup s# keyed
  2dup s0# keyed 2dup s1# keyed 2dup s2# keyed 2dup s3# keyed
  2dup r0# keyed 2dup r1# keyed 2dup r2# keyed 2dup r3# keyed
  i# keyed  status@ 1 and 0= dup stopped !
  IF  update  THEN  super show ; ( [methodend] ) 
  : widget  ( [dumpstart] )
            #0. ]N ( MINOS ) ^^ SN[ stopped @ 0= ?EXIT  p# get drop DBG_P u! ]SN ( MINOS ) X" P" infotextfield new  ^^bind p#
            #0. ]N ( MINOS ) ^^ SN[ stopped @ 0= ?EXIT  i# get drop DBG_I u! ]SN ( MINOS ) X" I" infotextfield new  ^^bind i#
            #0. ]N ( MINOS ) ^^ SN[ stopped @ 0= ?EXIT  s# get drop DBG_STATE u! ]SN ( MINOS ) X" S" infotextfield new  ^^bind s#
          #3 hatbox new #1 hskips
            ^^  0 T[ stopped on b16-stop update ][ ( MINOS ) stopped off b16-run ]T ( MINOS )  2icon" icons/stop"icons/play" toggleicon new  ^^bind stoptoggle
            ^^ S[ steps# get ?DO  b16-step update I 1+ 0 steps# assign  LOOP ]S ( MINOS )  icon" icons/step" icon-but new 
            #1. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) textfield new  ^^bind steps#
          #3 habox new hfixbox  #1 hskips
        #2 habox new #1 hskips
          #0. ]N ( MINOS ) ^^ SN[ stopped @ 0= ?EXIT  t# get drop DBG_T u! ]SN ( MINOS ) X" T" infotextfield new  ^^bind t#
          #0. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) X" N" infotextfield new  ^^bind s0#
          #0. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) X" 2" infotextfield new  ^^bind s1#
          #0. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) X" 3" infotextfield new  ^^bind s2#
          #0. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) X" 4" infotextfield new  ^^bind s3#
        #5 hatbox new #1 hskips
          #0. ]N ( MINOS ) ^^ SN[ stopped @ 0= ?EXIT  r# get drop DBG_R u! ]SN ( MINOS ) X" R" infotextfield new  ^^bind r#
          #0. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) X" 1" infotextfield new  ^^bind r0#
          #0. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) X" 2" infotextfield new  ^^bind r1#
          #0. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) X" 3" infotextfield new  ^^bind r2#
          #0. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) X" 4" infotextfield new  ^^bind r3#
        #5 hatbox new #1 hskips
      #3 vabox new vfixbox  panel
    ( [dumpend] ) ;
class;

: main
  b16-debug open-app
  event-loop bye ;
script? [IF]  main  [THEN]
previous previous previous
