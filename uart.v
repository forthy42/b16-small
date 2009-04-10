/*
 * $Id$
 * 
 * Uart module
 */

module uart(clk, nreset, rx, tx, id, od, dix, dox, rate);
   input clk, nreset, rx, dox;
   input [7:0] od;
   output [7:0] id;
   output [7:0] rate;
   output 	dix, tx;

   reg [9:0] 	disr, dosr;
   reg 		dix, srset, tx;
   reg [1:0] 	lastrx;
   reg [10:0] 	cnt, cnto, cntmax;
   reg [3:0] 	bitcnt, bitcnto;

   assign id = disr[8:1];
   assign rate = cntmax[10:3];
   
   always @(posedge clk or negedge nreset)
     if(!nreset) begin
	cnt <= 0;
	cnto <= 0;
	cntmax <= 434;
	dix <= 0;
	disr <= 0;
	dosr <= 0;
	srset <= 0;
	lastrx <= 1;
	bitcnt <= 0;
	bitcnto <= 0;
     end else begin
	lastrx <= { lastrx[0], rx };
	if(srset) begin
	   // receve part
	   dix <= 0;
	   if(!bitcnt) begin
	      if(lastrx= 2'b10)) begin
		 bitcnt <= 1;
		 cnt <= cntmax >> 1;
	      end
	   end else begin
	      cnt <= cnt - 1;
	      if(cnt == 0) begin
		 cnt <= cntmax;
		 bitcnt <= bitcnt + 1;
		 disr <= { disr[8:0], lastrx[0] };
		 if(bitcnt == 11) begin
		    bitcnt <= 0;
		    dix <= 1;
		 end
	      end
	   end // else: !if(!bitcnt)
	   // send part
	   if(|bitcnto) begin
	      if(!cnto) begin
		 { tx, dosr } <= { dosr, 1'b0 };
		 bitcnto <= bitcnto + 1;
		 cnto <= cntmax;
		 if(bitcnto == 11) begin
		    bitcnt <= 0;
		 end
	      end else begin
		 cnto <= cnto - 1;
	      end
	   end else if(dox) begin
	      bitcnto <= 1;
	      dosr <= { 1'b0, od, 1'b1 };
	   end
	end else begin // auto baud rate detection
	   if(lastrx == 2'b10) begin
	      cnt <= 0;
	   end else begin
	      cnt <= cnt + 1;
	      if(lastrx == 2'b01) begin
		 cntmax <= cnt;
		 srset <= 1;
		 cnt <= cnt >> 1;
	      end
	   end
	end
     end // else: !if(!nreset)

endmodule // uart
