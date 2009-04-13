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
 * W - write data, followed by two bytes data, addr+=2
 * r - read data, response is one byte data, addr++
 * l - transfer low byte, respones is one byte data, addr++ (no read access)
 * 
 * axxrl reads a word with a single access (necessary e.g. for the stack window)
 * 
 * Communication must start with either i or a, for baut rate detection
 */

module dbg_uart(clk, nreset, dix, dox, id, od,
		csu, addru, ru, wru, data, datau, status);
   input clk, nreset, dix;
   input [7:0] id, status;
   input [15:0] data;
   output 	dox, csu, ru;
   output [7:0] od;
   output [15:0] addru, datau;
   output [1:0]  wru;

   reg 		 dox, ru;
   reg [2:0] 	 state;
   reg [7:0] 	 od, lowbyte;
   reg [15:0] 	 addru, datau;
   reg [1:0] 	 wru;
   wire 	 csu = |{wru, ru};

   always @(posedge clk or negedge nreset)
     if(!nreset) begin
	dox <= 0;
	ru <= 0;
	wru <= 0;
	addru <= 0;
	datau <= 0;
	lowbyte <= 0;
	od <= 0;
     end else begin
	dox <= 0;
	if(csu) begin
	   addru <= addru + ru + wru[0] + wru[1];
	   ru <= 0;
	   wru <= 0;
	   if(ru) begin
	     { dox, od } <= { 1'b1, ~addru[0] ? data[15:8] : data[7:0] };
	     lowbyte <= data[7:0];
	   end
	end else if(dix) begin
	   case(state)
	     3'b000: casez(id)
		      "a": state <= 2;
		      "i": { dox, od } <= { 1'b1, status };
		      "w": state <= 1;
		      "W": state <= 4;
		      "r": ru <= 1;
		      "l": { addru, dox, od } <= { addru + 1, 1'b1, lowbyte };
		    endcase // casez (id)
	     3'b001: begin
		datau <= { id, id };
		wru <= addru[0] ? 2'b01 : 2'b10;
		state <= 0;
	     end
	     3'b010: begin
		addru[15:8] <= id;
		state <= 3;
	     end
	     3'b011: begin
		addru[7:0] <= id;
		state <= 0;
	     end
	     3'b100: begin
		datau[15:8] <= id;
		state <= 5;
	     end
	     3'b101: begin
		datau[7:0] <= id;
		wru <= 2'b11;
		state <= 0;
	     end
	   endcase // case (state)
	end // if (dix)
     end // else: !if(!nreset)
	  
endmodule // dbg_uart
