\ Debugging b16

$1000 Value heap

: +l 0 # heap # @ @+ + dup >r ! r> heap # ! ;

: init-heap  
      0 # heap # 2 # + dup >r ! r> heap # ! ;

: >h dup heap # @ @+ + !
     heap # @ dup >r @ 2 # + r> ! 
     0 # heap # @ @+ + 2 # + ! ;

: stop BEGIN AGAIN ;
