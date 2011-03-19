/*
 * Special function registers
 * 
 * $Id$
 */

`define hb [15:8]
`define lb [7:0]
`define hb1 [31:24]
`define lb1 [23:16]

module sfr(clk, nreset, drun, sel, addr, r, w, dwrite, sfr_data,
	   LED7, gpio_0, gpio_1, irqrun, keys);
   input clk, nreset, drun, sel, r;
   input [7:0] addr;
   input [15:0] dwrite;
   input [1:0] 	w;
   output [15:0] sfr_data, LED7;
   inout [35:0] gpio_0, gpio_1;
   input [12:0] keys;
   output 	irqrun;

   reg [15:0] 	 sfr_data, LED7, tval0, tval1;
   reg [35:0] 	 gpio_0o, gpio_1o, gpio_0t, gpio_1t;
   reg [31:0] 	 timerval;
   reg [12:0]    keys_reg;
   reg 	 irqmask, irqact;

   assign irqrun = |{irqmask & irqact};

   genvar 	 i;
   generate for(i=0; i<36; i=i+1)
     begin : triout
	assign gpio_0[i] = gpio_0t[i] ? gpio_0o[i] : 1'bz;
	assign gpio_1[i] = gpio_1t[i] ? gpio_1o[i] : 1'bz;
     end
   endgenerate
   
   always @(posedge clk or negedge nreset)
     if(!nreset) begin
	timerval <= 0;
     end else begin
	timerval <= timerval + drun;
     end
   
   always @(negedge clk or negedge nreset)
     if(!nreset) begin
	LED7 <= 0;
	gpio_0o <= 0;
	gpio_1o <= 0;
	gpio_0t <= 0;
	gpio_1t <= 0;
	tval0 <= 0;
	tval1 <= 0;
	irqact <= 8'hff;
	irqmask <= 8'hff;
	keys_reg <= 0;
     end else begin // if (!nreset)
	keys_reg <= keys;
	if(sel) begin
	   if(w[1]) begin
	      case({ addr[7:1], 1'b0 })
		8'h00: LED7`hb <= dwrite`hb;
		8'h08: irqmask <= dwrite`hb;
		8'h10: tval0`hb <= dwrite`hb;
		8'h12: tval1`hb <= dwrite`hb;
		8'h22: gpio_0o`hb1 <= dwrite`hb;
		8'h24: gpio_0o`hb <= dwrite`hb;
		8'h2a: gpio_0t`hb1 <= dwrite`hb;
		8'h2c: gpio_0t`hb <= dwrite`hb;
		8'h32: gpio_1o`hb1 <= dwrite`hb;
		8'h34: gpio_1o`hb <= dwrite`hb;
		8'h3a: gpio_1t`hb1 <= dwrite`hb;
		8'h3c: gpio_1t`hb <= dwrite`hb;
	      endcase
	   end
           if(w[0]) begin
	      case({ addr[7:1], 1'b0 })
		8'h00: LED7`lb <= dwrite`lb;
		8'h08: irqact <= dwrite`lb;
		8'h10: tval0`lb <= dwrite`lb;
		8'h12: tval1`lb <= dwrite`lb;
		8'h20: gpio_0o[35:32] <= dwrite`lb;
		8'h22: gpio_0o`lb1 <= dwrite`lb;
		8'h24: gpio_0o`lb <= dwrite`lb;
		8'h28: gpio_0t[35:32] <= dwrite`lb;
		8'h2a: gpio_0t`lb1 <= dwrite`lb;
		8'h2c: gpio_0t`lb <= dwrite`lb;
		8'h30: gpio_1o[35:32] <= dwrite`lb;
		8'h32: gpio_1o`lb1 <= dwrite`lb;
		8'h34: gpio_1o`lb <= dwrite`lb;
		8'h38: gpio_1t[35:32] <= dwrite`lb;
		8'h3a: gpio_1t`lb1 <= dwrite`lb;
		8'h3c: gpio_1t`lb <= dwrite`lb;
	      endcase
	   end // if (w[0])
	end
	if(timerval == {tval0, tval1})
	  irqact <= 1;
     end

   always @(addr or r or sel or LED7 or tval0 or tval1 or timerval
            or gpio_0 or gpio_1 or gpio_0t or gpio_1t or irqmask or irqact or keys_reg)
     if(r & sel)
       case({ addr[7:1], 1'b0 })
	 8'h00: sfr_data <= LED7;
	 8'h08: sfr_data <= { irqmask, 7'h00, irqact };
	 8'h10: sfr_data <= tval0;
	 8'h12: sfr_data <= tval1;
	 8'h14: sfr_data <= timerval[31:16];
	 8'h16: sfr_data <= timerval[15:0];
	 8'h20: sfr_data <= gpio_0[35:32];
	 8'h22: sfr_data <= gpio_0[31:16];
	 8'h24: sfr_data <= gpio_0[15:0];
	 8'h28: sfr_data <= gpio_0t[35:32];
	 8'h2a: sfr_data <= gpio_0t[31:16];
	 8'h2c: sfr_data <= gpio_0t[15:0];
	 8'h30: sfr_data <= gpio_1[35:32];
	 8'h32: sfr_data <= gpio_1[31:16];
	 8'h34: sfr_data <= gpio_1[15:0];
	 8'h38: sfr_data <= gpio_1t[35:32];
	 8'h3a: sfr_data <= gpio_1t[31:16];
	 8'h3c: sfr_data <= gpio_1t[15:0];
	 8'h40: sfr_data <= keys_reg;
	 default sfr_data <= 0;
       endcase else sfr_data <= 0;
   
endmodule // sfr
