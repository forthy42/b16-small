#! /usr/local/bin/xbigforth
\ automatic generated code
\ do not edit

also editor also minos also forth

component class b16-state
public:
  tableinfotextfield ptr p#
  tableinfotextfield ptr i#
  tableinfotextfield ptr s#
  toggleicon ptr stoptoggle
  textfield ptr steps#
  tableinfotextfield ptr t#
  tableinfotextfield ptr s0#
  tableinfotextfield ptr s1#
  tableinfotextfield ptr s2#
  tableinfotextfield ptr s3#
  tableinfotextfield ptr s4#
  tableinfotextfield ptr s5#
  tableinfotextfield ptr s6#
  tableinfotextfield ptr s7#
  tableinfotextfield ptr r#
  tableinfotextfield ptr r0#
  tableinfotextfield ptr r1#
  tableinfotextfield ptr r2#
  tableinfotextfield ptr r3#
  tableinfotextfield ptr r4#
  tableinfotextfield ptr r5#
  tableinfotextfield ptr r6#
  tableinfotextfield ptr r7#
 ( [varstart] ) cell var stopped
method update ( [varend] ) 
how:
  : params   DF[ 0 ]DF s" b16 state" ;
class;

component class b16-ide
public:
  vabox ptr error-box
  text-label ptr error-msg
  canvas ptr breakpoints
  stredit ptr code-source
 ( [varstart] ) cell var first-time
cell var filename
Cell var source-path ( [varend] ) 
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
 ( [methodstart] ) : show  self F bind b16d super show ; ( [methodend] ) 
  : widget  ( [dumpstart] )
          ^^ CP[  ]CP ( MINOS ) b16-mem new 
          ^^ CP[  ]CP ( MINOS ) b16-state new  ^^bind state-comp
          $0 $1 *hfill $0 $1 *vfil rule new 
        #3 habox new
        ^^ CP[  ]CP ( MINOS ) b16-ide new  ^^bind ide-comp
      #2 vabox new
    ( [dumpend] ) ;
class;

b16-mem implements
 ( [methodstart] ) : assign drop ; ( [methodend] ) 
  : widget  ( [dumpstart] )
          #0. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) X" Addr" infotextfield new  ^^bind addr#
          #0. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) X" Data" infotextfield new  ^^bind data#
              ^^ S[ addr# get drop dbg@ 0 data# assign ]S ( MINOS ) X" @" button new 
              ^^ S[ addr# get drop dbgc@ 0 data# assign ]S ( MINOS ) X" c@" button new 
            #2 hatbox new #1 hskips
              ^^ S[ data# get drop addr# get drop dbg! ]S ( MINOS ) X" !" button new 
              ^^ S[ data# get drop addr# get drop dbgc! ]S ( MINOS ) X" c!" button new 
            #2 hatbox new #1 hskips
          #2 vatbox new #1 vskips
          $60 $1 *hfil $0 $1 *vfill rule new 
        #4 vabox new #1 vskips
          #0. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) X" N" infotextfield new  ^^bind n#
          ^^ S[ wini/o at? 2drop
addr# get drop n# get drop base @ >r hex
BEGIN  2dup scratch swap 2/ 8 min dbg@s
    cr over 0 <# # # # # #> type ." : "
    scratch over $10 umin bounds ?DO
        I c@ 0 <# # # #> type space
    LOOP
    $10 /string dup 0= UNTIL
2drop r> base !
 ]S ( MINOS ) X" Dump" button new 
          #0. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) X" status" infotextfield new  ^^bind status#
          ^^ S[ status@ 0 status# assign ]S ( MINOS ) X" status@" button new 
          $10 $1 *hfil $10 $1 *vfill rule new 
        #5 vabox new #1 vskips
      #2 habox new panel #-1 borderbox
    ( [dumpend] ) ;
class;

b16-ide implements
 ( [methodstart] ) : assign drop ;
: reload
    error-box -flip  loaderr off
    filename $@ ['] asm-included catch
    IF
	2drop
	scr @ 1- r# @ code-source at
	error-box +flip
	"error @ count error-msg assign
    THEN
    breakpoints draw ;
: load-file ( -- )
  filename $@ r/o open-file throw
  code-source assign
  code-source edifile dup @ close-file swap off throw
  code-source resized  reload ;
: load-args
  argc @ arg# @ 1+ > IF
      argc @ arg# @ 1+ ?DO
                  I arg s" .asm" postfix? IF
                      I arg filename $! load-file
                  THEN
      LOOP
  THEN ;
: save-file ( -- )
  filename $@ r/w create-file throw isfile !
  :[ isfile@ write-line throw ]: code-source dump
  isfile@ close-file throw  isfile off
  reload ;
: show  first-time @ 0= IF load-args first-time on THEN
  super show ; ( [methodend] ) 
  : widget  ( [dumpstart] )
          X" Error Message" text-label new  ^^bind error-msg
        #1 vabox new ^^bind error-box flipbox 
            ^^ S[ s" Load assembler source" s" " source-path @
IF  source-path $@  ELSE  s" *.asm"  THEN
^ S[ 2over source-path $!
     path+file filename $! load-file ]S fsel-action ]S ( MINOS )  icon" icons/load" icon-but new 
            ^^ S[ save-file ]S ( MINOS )  icon" icons/save" icon-but new 
            ^^ S[ save-file upload ]S ( MINOS )  icon" icons/run" icon-but new 
            $0 $1 *hfil $100 $1 *vfilll rule new 
          #4 vabox new hfixbox 
          1 1 vviewport new  DS[ 
                CV[ 2 outer with code-source rows @ endwith
tuck 1 max steps  1 backcolor clear
1 dpy xrc font@ font
1 2 textpos
hex
0 ?DO
    1 I home!
    I search-line dup -1 <> IF
       dup find-bp? nip IF  $CC $00 $00 rgb>pen
       ELSE  $00 $CC $00 rgb>pen  THEN  drawcolor
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
              #2 habox new
              $0 $1 *hfil $0 $1 *vfilll rule new 
            #2 vabox new
          #1 habox new ]DS ( MINOS ) 
        #2 habox new
      #2 vabox new
    ( [dumpend] ) ;
class;

b16-state implements
 ( [methodstart] ) : assign drop ;
: bp-watch  recursive  ^ dpy cleanup
    status@ $1 and 0= IF
       stoptoggle with set draw endwith update
    ELSE
       ['] bp-watch ^ &100 after dpy schedule
    THEN ;
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
  stack 14 + w@ 0 r3# assign
  stack 16 + w@ 0 s4# assign
  stack 18 + w@ 0 r4# assign
  stack 20 + w@ 0 s5# assign
  stack 22 + w@ 0 r5# assign
  stack 24 + w@ 0 s6# assign
  stack 26 + w@ 0 r6# assign
  stack 28 + w@ 0 s7# assign
  stack 30 + w@ 0 r7# assign
  r> stopped !
  regs w@ regs 8 + w@ 8 rshift 3 and search-listing
  2dup d0= 0= IF  b16d ide-comp code-source at
  ELSE  2drop  THEN ;
: show  '$' 0
  2dup p# keyed  2dup t# keyed  2dup r# keyed  2dup s# keyed
  2dup s0# keyed 2dup s1# keyed 2dup s2# keyed 2dup s3# keyed
  2dup s4# keyed 2dup s5# keyed 2dup s6# keyed 2dup s7# keyed
  2dup r0# keyed 2dup r1# keyed 2dup r2# keyed 2dup r3# keyed
  2dup r4# keyed 2dup r5# keyed 2dup r6# keyed 2dup r7# keyed
  i# keyed  status@ 1 and 0= dup stopped !
  IF  update  ELSE  bp-watch  THEN  super show ; ( [methodend] ) 
  : widget  ( [dumpstart] )
            #0. ]N ( MINOS ) ^^ SN[ stopped @ 0= ?EXIT  p# get drop DBG_P dbg! ]SN ( MINOS ) X" P" tableinfotextfield new  ^^bind p#
            #0. ]N ( MINOS ) ^^ SN[ stopped @ 0= ?EXIT  i# get drop DBG_I dbg! ]SN ( MINOS ) X" I" tableinfotextfield new  ^^bind i#
            #0. ]N ( MINOS ) ^^ SN[ stopped @ 0= ?EXIT  s# get drop DBG_STATE dbg! ]SN ( MINOS ) X" S" tableinfotextfield new  ^^bind s#
          #3 vatbox new vfixbox 
              ^^  0 T[ stopped on b16-stop update ][ ( MINOS ) stopped off b16-run bp-watch ]T ( MINOS )  2icon" icons/stop"icons/play" toggleicon new  ^^bind stoptoggle
              ^^ S[ steps# get ?DO  b16-step update I 1+ 0 steps# assign  LOOP ]S ( MINOS )  icon" icons/step" icon-but new 
            #2 habox new vfixbox  #1 hskips
            #1. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) textfield new  ^^bind steps#
            ^^ S[ b16-reset update ]S ( MINOS ) X" Reset" button new 
          #3 vabox new vfixbox 
          $50 $1 *hfil $0 $1 *vfil rule new 
        #3 vabox new #1 vskips
          #0. ]N ( MINOS ) ^^ SN[ stopped @ 0= ?EXIT  t# get drop DBG_T dbg! ]SN ( MINOS ) X" T" tableinfotextfield new  ^^bind t#
          #0. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) X" N" tableinfotextfield new  ^^bind s0#
          #0. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) X" 2" tableinfotextfield new  ^^bind s1#
          #0. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) X" 3" tableinfotextfield new  ^^bind s2#
          #0. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) X" 4" tableinfotextfield new  ^^bind s3#
          #0. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) X" 5" tableinfotextfield new  ^^bind s4#
          #0. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) X" 6" tableinfotextfield new  ^^bind s5#
          #0. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) X" 7" tableinfotextfield new  ^^bind s6#
          #0. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) X" 8" tableinfotextfield new  ^^bind s7#
          $50 $1 *hfil $0 $0 *vpix rule new 
        #10 vatbox new
          #0. ]N ( MINOS ) ^^ SN[ stopped @ 0= ?EXIT  r# get drop DBG_R dbg! ]SN ( MINOS ) X" R" tableinfotextfield new  ^^bind r#
          #0. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) X" 1" tableinfotextfield new  ^^bind r0#
          #0. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) X" 2" tableinfotextfield new  ^^bind r1#
          #0. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) X" 3" tableinfotextfield new  ^^bind r2#
          #0. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) X" 4" tableinfotextfield new  ^^bind r3#
          #0. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) X" 5" tableinfotextfield new  ^^bind r4#
          #0. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) X" 6" tableinfotextfield new  ^^bind r5#
          #0. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) X" 7" tableinfotextfield new  ^^bind r6#
          #0. ]N ( MINOS ) ^^ SN[  ]SN ( MINOS ) X" 8" tableinfotextfield new  ^^bind r7#
          $50 $1 *hfil $0 $0 *vpix rule new 
        #10 vatbox new
      #3 habox new vfixbox  panel #-1 borderbox
    ( [dumpend] ) ;
class;

: main
  b16-debug open-app
  event-loop bye ;
script? [IF]  main  [THEN]
previous previous previous
