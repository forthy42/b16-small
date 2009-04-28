/*
 * $Id$
 * 
 * Uart module
 */

module uart(clk, nreset, rx, tx, id, od, dix, dox, wip, rate, debug);
   input clk, nreset, rx, dox;
   input [7:0] od;
   output [7:0] id;
   output [15:0] rate;
   output [9:0] debug;
   output 	dix, wip, tx;

   reg [9:0] 	disr, dosr;
   reg 		dix, srset, tx;
   reg [1:0] 	lastrx;
   reg [15:0] 	cnt, cnto, cntmax;
   reg [3:0] 	bitcnt, bitcnto;

   assign id = disr[8:1];
   assign rate = cntmax;
   assign debug = { srset, lastrx, bitcnt, disr[9:7] };
   assign wip = |bitcnto;
   
   always @(posedge clk or negedge nreset)
     if(!nreset) begin
	cnt <= 0;
	cnto <= 0;
	cntmax <= 0;
	dix <= 0;
	disr <= 0;
	dosr <= 0;
	srset <= 0;
	lastrx <= 3'b11;
	bitcnt <= 0;
	bitcnto <= 0;
	tx <= 1;
     end else begin
	lastrx <= { lastrx[0], rx };
	if(srset) begin
	   // receive part
	   dix <= 0;
	   if(!bitcnt) begin
	      if(lastrx == 2'b10) begin
		 bitcnt <= 1;
		 cnt <= cntmax >> 1;
		 disr <= { lastrx[0], disr[9:1] };
	      end
	   end else begin
	      cnt <= cnt - 1;
	      if(cnt == 1) begin
		 cnt <= cntmax;
		 bitcnt <= bitcnt + 1;
		 disr <= { lastrx[0], disr[9:1] };
		 if(bitcnt == 10) begin
		    bitcnt <= 0;
		    dix <= 1;
		 end
	      end
	   end // else: !if(!bitcnt)
	   // send part
	   if(wip) begin
	      if(cnto == 1) begin
		 { dosr, tx } <= { 1'b1, dosr };
		 bitcnto <= bitcnto + 1;
		 cnto <= cntmax;
		 if(bitcnto == 10) begin
		    bitcnto <= 0;
		 end
	      end else begin
		 cnto <= cnto - 1;
	      end
	   end else if(dox) begin
	      bitcnto <= 1;
	      dosr <= { 1'b1, od, 1'b0 };
	      cnto <= 1;
	   end
	end else begin // auto baud rate detection
	   if(lastrx == 2'b10) begin
	      if(cntmax) begin
	        cntmax <= (cntmax + cnt + 1) >> 1;
	        cnt <= cnt >> 1;
	        srset <= 1;
	        bitcnt <= 3;
	        disr[9] <= 1;
	      end else begin
	        cnt <= 0;
	      end
	   end else begin
	      cnt <= cnt + 1;
	      if(lastrx == 2'b01) begin
		 cntmax <= cnt + 1;
		 cnt <= 0;
	      end
	   end
	end
     end // else: !if(!nreset)

endmodule // uart
