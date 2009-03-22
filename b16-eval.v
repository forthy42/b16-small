// Interface to elements on the evaluation board

`define L [l-1:0]

module b16_eval(clk, reset, din, dout, a, d, wr_b, rd_b, ble_b, bhe_b);
   parameter l=16;
   input clk, reset;
   input `L din;
   output `L dout, a;
   inout  `L d;
   output wr_b, rd_b, ble_b, bhe_b;
   
   wire   `L addr, dwrite, a_out;
   wire   r, waits;
   wire [1:0] w;
   reg 	      `L dout_out, data, a_old;
   reg [2:0]  sel;
   reg [1:0]  dout24;

   wire [7:0] intvec = 0;
   wire       intreq = 0;
   wire       nreset = ~reset;
   
   cpu b16(clk, 1'b1, nreset, addr, r, w, data, dwrite, 1'b1, 1'b0, 1'b0
`ifdef DEBUGGING, dr, dw, daddr, din, dout, bp`endif);

   assign d = r ? {(l){ 1'bz }} : dwrite;
   assign a_out = { 1'b0, addr[l-1:1] };

   always @(posedge clk)
      a_old <= a_out;

   assign a[0] = (a_out[0] & a_old[0]) ? 1'bz : a_out[0];
   assign a[1] = (a_out[1] & a_old[1]) ? 1'bz : a_out[1];
   assign a[2] = (a_out[2] & a_old[2]) ? 1'bz : a_out[2];
   assign a[3] = (a_out[3] & a_old[3]) ? 1'bz : a_out[3];
   assign a[4] = (a_out[4] & a_old[4]) ? 1'bz : a_out[4];
   assign a[5] = (a_out[5] & a_old[5]) ? 1'bz : a_out[5];
   assign a[6] = (a_out[6] & a_old[6]) ? 1'bz : a_out[6];
   assign a[7] = (a_out[7] & a_old[7]) ? 1'bz : a_out[7];
   assign a[8] = (a_out[8] & a_old[8]) ? 1'bz : a_out[8];
   assign a[9] = (a_out[9] & a_old[9]) ? 1'bz : a_out[9];
   assign a[10] = (a_out[10] & a_old[10]) ? 1'bz : a_out[10];
   assign a[11] = (a_out[11] & a_old[11]) ? 1'bz : a_out[11];
   assign a[12] = (a_out[12] & a_old[12]) ? 1'bz : a_out[12];
   assign a[13] = (a_out[13] & a_old[13]) ? 1'bz : a_out[13];
   assign a[14] = (a_out[14] & a_old[14]) ? 1'bz : a_out[14];
   assign a[15] = (a_out[15] & a_old[15]) ? 1'bz : a_out[15];

   assign dout[2] = (dout_out[2] & dout24[0]) ? 1'bz : dout_out[2];
   assign dout[4] = (dout_out[4] & dout24[1]) ? 1'bz : dout_out[4];
   assign { dout[15:5], dout[3], dout[1:0] } = { dout_out[15:5], dout_out[3], dout_out[1:0] };

   always @(addr)
      if(addr[15:2] == 14'h3fff) sel <= 3'b100;
      else if(addr[15:14] == 2'h1) sel <= 3'b010;
	   else sel <= 3'b001;

   always @(negedge clk or negedge nreset)
      if(!nreset)
	 begin
	    dout_out <= 16'b1010_0101_0001_0101;
	    dout24 <= 2'b11;
	 end
      else
	 begin
	    if(sel[2] & addr[1]) begin
	       if(w[1]) dout_out[15:8] <= dwrite[15:8];
	       if(w[0]) dout_out[07:0] <= dwrite[07:0];
	    end // if (sel[2] & addr[0])
	    dout24 <= { dout_out[2], dout_out[4] };
	 end
   
   reg 	      wr_b, rd_b, ble_b, bhe_b;
   
   always @(clk or nreset or r or w or sel)
      if(sel[0] & nreset) begin
	 rd_b <= ~r;
	 { wr_b, ble_b, bhe_b } <= 3'b111;
	 if(!clk) begin
	    wr_b <= ~|w;
	    { bhe_b, ble_b } <= ~w & { ~r, ~r };
	 end
      end
      else { wr_b, rd_b, ble_b, bhe_b } <= 4'b1111;

   reg [7:0] bootraml[0:4095], bootramh[0:4095];

   always @(negedge clk)
      if(sel[1]) begin
	 if(w[1]) bootramh[addr[13:1]] <= d[15:8];
	 if(w[0]) bootraml[addr[13:1]] <= d[ 7:0];
	 if(&w)   $display("bootram[%x] <= %x", { addr[13:1], 1'b0 }, d);
	 else begin
	    if(w[0]) $display("bootram[%x] <= %x", { addr[13:1], 1'b1 }, d[15:8]);
	    if(w[1]) $display("bootram[%x] <= %x", { addr[13:1], 1'b0 }, d[ 7:0]);
	 end
      end

   initial
      begin
	 $readmemh("b16l.hex", bootraml);
	 $readmemh("b16h.hex", bootramh);
      end

   integer oldtime;
   initial oldtime = 0;

   always @(sel or r or d or din or dout_out or addr)
      begin
	 casez({ r, sel })
	   4'b1100: begin
	      data <= addr[1] ? dout_out : din;
	      if(!addr[1] && (($time-oldtime) != 0)) begin
		 $display("%d: Read din %x", $time-oldtime, din);
		 oldtime = $time;
	      end
	   end
	   4'b1010: data <= { bootramh[addr[13:1]], bootraml[addr[13:1]] };
	   4'b1001: data <= d;
	   4'b????: data <= 16'h0000;
	 endcase // case(sel)
      end

endmodule
   

