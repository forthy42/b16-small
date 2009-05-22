\ b16 FPGA board regmap
$FF00 org
| LED7 0 ,
$FF08 org
| IRQMASK 0 c,
| IRQACT 0 c,
$FF10 org
| TVAL0 0 ,
| TVAL1 0 ,
| TIMERVAL0 0 ,
| TIMERVAL1 0 ,
$FF20 org
| GPIO00 0 ,
| GPIO01 0 ,
| GPIO02 0 ,
$FF28 org
| GPIO00t 0 ,
| GPIO01t 0 ,
| GPIO02t 0 ,
$FF30 org
| GPIO10 0 ,
| GPIO11 0 ,
| GPIO12 0 ,
$FF38 org
| GPIO10t 0 ,
| GPIO11t 0 ,
| GPIO12t 0 ,

