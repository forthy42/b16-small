/*
 * $Id$
 * 
 * Debugger memory access using the UART
 * 
 * Commands are letters:
 * 
 * i - read status, response is one status byte
 * a - address, followed by two bytes, big endian
 * w - write data, followed by one byte data, addr++
 * r - read data, response is one byte data, addr++
 * 
 * Communication must start with either i or a, for baut rate detection
 */

module dbg_uart(clk, nreset, dix, dox, id, od,
		csu, addru, ru, wru, data, datau);
   input clk, nreset, dix;
   input [7:0] id;
   input [15:0] data;
   output 	dox, csu, ru;
   output [7:0] od;
   output [15:0] addru, datau;
   output [1:0]  wru;

   reg 		 dox, ru;
   reg [1:0] 	 state;
   reg [7:0] 	 od;
   reg [15:0] 	 addru, datau;
   reg [1:0] 	 wru;
   wire 	 csu = |{wru, ru};
   wire [7:0] 	 status = 0;

   always @(posedge clk or negedge nreset)
     if(!nreset) begin
	dox <= 0;
	ru <= 0;
	wru <= 0;
	addru <= 0;
	datau <= 0;
     end else begin
	dox <= 0;
	if(csu) begin
	   addru <= addru + 1;
	   r <= 0;
	   wr <= 0;
	   if(r)
	     { dox, od } <= { 1'b1, addru[0] ? data[15:8] : data[7:0] };
	end else if(dix) begin
	   case(state)
	     2'b00: casez(id)
		      "a": state <= 2;
		      "i": { dox, od } <= { 1'b1, status };
		      "w": state <= 1;
		      "r": r <= 1;
		    endcase // casez (id)
	     2'b01: begin
		if(addru[0])
		  datau[15:8] <= id;
		else
		  datau[7:0] <= id;
		wr <= addru[0] ? 2'b10 : 2'b01;
		state <= 0;
	     end
	     2'b10: begin
		addru[15:8] <= id;
		state <= 3;
	     end
	     2'b11: begin
		addru[7:0] <= id;
		state <= 0;
	     end
	   endcase // case (state)
	end // if (dix)
     end // else: !if(!nreset)
	  
endmodule // dbg_uart
