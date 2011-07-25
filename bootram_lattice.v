/*
 * RAM for boot program
 * 
 * Isolated to allow alternative implementations
 */

module bootram(input clk,
	       input nreset,
	       input sel,
	       input r,
	       input [1:0] w,
	       input [12:1] addr,
	       input [15:0] din,
	       output [15:0] dout);

	bootramh ramh(.Data(din[15:8]),
	.Address(addr),
	.Clock(clk),
	.ClockEn(sel & |{r, w}),
	.WE(w[1]),
	.Reset(!nreset),
	.Q(dout[15:8])
	);
	bootraml raml(.Data(din[7:0]),
	.Address(addr),
	.Clock(clk),
	.ClockEn(sel & |{r, w}),
	.WE(w[0]),
	.Reset(!nreset),
	.Q(dout[7:0])
	);

endmodule // bootram
