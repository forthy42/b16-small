/*
 * PWM module
 */

`define hb [15:8]
`define lb [7:0]
`define hb1 [31:24]
`define lb1 [23:16]

module pwm(clk, nreset, drun, sel, addr, r, w, dwrite, pwm_data,
	   pwm);
   parameter pwms=2;
   
   input clk, nreset, drun, sel, r;
   input [5:0] addr;
   input [15:0] dwrite;
   input [1:0] 	w;
   output [pwms:0] pwm;
   output [15:0]   pwm_data;

   reg [pwms:0]    pwm;
   reg [15:0] 	   pwm_data;
   reg [31:0] 	   tmr[pwms:0];
   reg [31:0] 	   thres[pwms:0];
   reg [31:0] 	   cycle[pwms:0];
   integer 	   i;

   always @(posedge clk or negedge nreset)
     if(!nreset) begin
	for(i=0; i<=pwms; i=i+1) begin
	   tmr[i] <= 0;
	   thres[i] <= 0;
	   cycle[i] <= 32'hffff_ffff;
	   pwm[i] <= 0;
	end
     end else begin
	for(i=0; i<=pwms; i=i+1) begin
	   tmr[i] <= (tmr[i] >= cycle[i]) ? 0 : tmr[i] + 1;
	   pwm[i] <= tmr[i] < thres[i];
	end
	if(sel) begin
	   if(w[1]) begin
	      case({ addr[5:4], addr[1] })
		3'h2: thres[addr[3:2]]`hb1 <= dwrite`hb;
		3'h3: thres[addr[3:2]]`hb  <= dwrite`hb;
		3'h4: cycle[addr[3:2]]`hb1 <= dwrite`hb;
		3'h5: cycle[addr[3:2]]`hb  <= dwrite`hb;
	      endcase
	   end
	   if(w[0]) begin
	      case({ addr[5:4], addr[1] })
		3'h2: thres[addr[3:2]]`lb1 <= dwrite`lb;
		3'h3: thres[addr[3:2]]`lb  <= dwrite`lb;
		3'h4: cycle[addr[3:2]]`lb1 <= dwrite`lb;
		3'h5: cycle[addr[3:2]]`lb  <= dwrite`lb;
	      endcase
	   end
	end // if (sel)
     end // else: !if(!nreset)
   
   always @(*)
     if(r & sel)
       case({ addr[5:4], addr[1] })
	 3'h0: pwm_data <= tmr[addr[3:2]][31:16];
	 3'h1: pwm_data <= tmr[addr[3:2]][15:0];
	 3'h2: pwm_data <= thres[addr[3:2]][31:16];
	 3'h3: pwm_data <= thres[addr[3:2]][15:0];
	 3'h4: pwm_data <= cycle[addr[3:2]][31:16];
	 3'h5: pwm_data <= cycle[addr[3:2]][15:0];
	 default pwm_data <= 0;
       endcase else pwm_data <= 0;
   
endmodule // pwm
