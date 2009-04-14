#! /usr/local/bin/xbigforth
\ automatic generated code
\ do not edit

also editor also minos also forth

include b16.fs
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
 ( [varstart] ) cell var stopped ( [varend] ) 
how:
  : params   DF[ 0 ]DF s" b16 state" ;
class;

b16-state implements
 ( [methodstart] ) \ : assign drop ;
: update  stopped @ 0= ?EXIT  load-regs
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
  stack 14 + w@ 0 r3# assign ;
: show  '$' 0
  2dup p# keyed  2dup t# keyed  2dup r# keyed  2dup s# keyed
  2dup s0# keyed 2dup s1# keyed 2dup s2# keyed 2dup s3# keyed
  2dup r0# keyed 2dup r1# keyed 2dup r2# keyed 2dup r3# keyed
  i# keyed  super show ; ( [methodend] ) 
  : widget  ( [dumpstart] )
            #0. ]N ( MINOS ) ^^ SN[ stopped @ 0= ?EXIT  p# get drop DBG_P u! ]SN ( MINOS ) X" P" infotextfield new  ^^bind p#
            #0. ]N ( MINOS ) ^^ SN[ stopped @ 0= ?EXIT  i# get drop DBG_I u! ]SN ( MINOS ) X" I" infotextfield new  ^^bind i#
            #0. ]N ( MINOS ) ^^ SN[ stopped @ 0= ?EXIT  s# get drop DBG_STATE u! ]SN ( MINOS ) X" S" infotextfield new  ^^bind s#
          #3 hatbox new #1 hskips
            ^^ TV[ stopped ]T[ ( MINOS ) stopped @ IF  b16-stop update  ELSE  b16-run  THEN ]TV ( MINOS )  2icon" icons/stop"icons/play" toggleicon new  ^^bind stoptoggle
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
      #3 vabox new panel
    ( [dumpend] ) ;
class;

: main
  b16-state open-app
  event-loop bye ;
script? [IF]  main  [THEN]
previous previous previous
