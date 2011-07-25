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
   reg [7:0] 		     bootraml[0:4095] /* synthesis ramstyle="no_rw_check" */;
   reg [7:0] 		     bootramh[0:4095] /* synthesis ramstyle="no_rw_check" */;
   reg [12:1] 		     addr_i;

   always @(posedge clk or negedge nreset)
     if(!nreset) begin
	addr_i <= 0;
     end else begin
	addr_i <= addr;
	if(sel & !r) begin
	   if(w[1]) bootramh[addr[12:1]] <= din[15:8];
	   if(w[0]) bootraml[addr[12:1]] <= din[ 7:0];
	end
     end

   assign dout = { bootramh[addr_i], bootraml[addr_i] };

   initial
     begin
	$readmemh("b16l.hex", bootraml);
	$readmemh("b16h.hex", bootramh);
     end
   
endmodule // bootram
