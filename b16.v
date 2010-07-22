/*
 * b16 core: 16 bits, 
 * inspired by c18 core from Chuck Moore
 *
 * Instruction set:
 * 1, 5, 5, 5 bits
 *     0    1    2    3    4    5    6    7
 *  0: nop  call jmp  ret  jz   jnz  jc   jnc
 *  /3      exec goto ret  gz   gnz  gc   gnc
 *  8: xor  com  and  or   +    +c   *+   /-
 * 10: !+   @+   @    lit  c!+  c@+  c@   litc
 *  /1 !.   @.   @    lit  c!.  c@.  c@   litc
 * 18: nip  drop over dup  >r        r>
 */
 
`define L [l-1:0]
`define DROP { sp, T } <= { spinc, N } 
`define DEBUGGING
`define FPGA
// `define BUSTRI
`timescale 1ns / 1ns

module alu(res, carry, zero, T, N, c, inst);
   parameter l=16;
   input `L T, N;
   input c;
   input [2:0] inst;
   output `L res;
   output carry, zero;

   wire prop, andor, selr;

   assign #1 { prop, selr, andor } = inst;

   wire        `L r1, r2;
   wire [l:0]  carries;

   assign #1 r1 = T ^ N ^ carries;
   assign #1 r2 = (T & N) | 
                  (T & carries`L) | 
                  (N & carries`L);
   assign #1 carries = 
        prop ? { r2[l-1:0], (c | selr) & andor } 
             : { c, {(l){andor}}};
   assign #1 res = (selr & ~prop) ? r2 : r1;
   assign #1 carry = carries[l];
   assign #1 zero = ~|T;
endmodule // alu
module stack(clk, sp, spdec, push, scan, in, out);
   parameter dep=2, l=16;
   input clk, push, scan;
   input [dep-1:0] sp, spdec; 
   input `L in;
   output `L out; 
`ifdef SYNCSTACK
// ugly hack to have the same code running
// on a Cyclone and an Apex
   reg `L sm0, sm1, sm2, sm3; 
   always @(posedge clk)
     if(push) 
       case(spdec) 
         2'b00: sm0 <= in; 
         2'b01: sm1 <= in; 
         2'b10: sm2 <= in; 
         2'b11: sm3 <= in; 
       endcase 

   assign out = sp[1] ? (sp[0] ? sm3 : sm2) 
                      : (sp[0] ? sm1 : sm0);
`else 
   wire [dep-1:0] #1 spset = spdec;
   wire #1 write = push & ~clk;
   wire `L #1 ind = in;
   reg `L stackmem[0:(1<<dep)-1];

`ifndef FPGA
  always @(write or spset or ind or scan)
     if(scan) begin
        stackmem[0] <= ind;
        stackmem[1] <= ind;
        stackmem[2] <= ind;
        stackmem[3] <= ind;
     end else if(write) stackmem[spset] <= ind;
`else
  always @(posedge clk)
     if(push)
        stackmem[spset] <= #1 ind; 
`endif

  assign #1 out = stackmem[sp]; 
`endif
endmodule // stack
module mux(out, sel, atpg, in1, in0); 
   parameter l=16; 
   input `L in1, in0; 
   input sel, atpg; 
   output `L out;

   assign out = (sel | atpg) ? in1 : in0; 
endmodule // mux
module cpu(clk, run, reset, addr, rd, wr, data, 
           dataout, scanning, atpg 
`ifdef DEBUGGING,
           dr, dw, daddr, din, dout, bp`endif);
   parameter rstaddr=16'h3FFE, show=0,
             l=16, sdep=4, rdep=4;
   input clk, run, reset, scanning, atpg;
   output `L addr;
   output rd;
   output [1:0] wr;
   input  `L data;
   output `L dataout;
   `ifdef DEBUGGING
      input [2:0] daddr;
      input dr, dw;
      input `L din, bp;
      output `L dout;
   `endif
   reg [sdep-1:0] sp;
   reg [rdep-1:0] rp;

   reg `L T, I, P, R;

   reg [1:0] state;
   reg c;
   // instruction and branch target selection   
   reg [4:0] inst;
   reg `L jmp;

   always @(state or I or data or atpg)
      case(state[1:0])
        2'b00: inst = { 4'b0000, data[15] & !atpg };
        2'b01: inst =   I[14:10];
        2'b10: inst =   I[9:5];
        2'b11: inst =   I[4:0];
      endcase // casez(state)

   always @(state or I or P or T or data)
      case(state[1:0])
        2'b00: jmp = { data[14:0], 1'b0 };
        2'b01: jmp = { P[15:11], I[9:0], 1'b0 };
        2'b10: jmp = { P[15:6], I[4:0], 1'b0 };
        2'b11: jmp = { T[15:1], 1'b0 };
      endcase // casez(state)
   wire `L res, toN, toR, N;
   wire carry, zero;

   alu #(l) alu16(res, carry, zero, 
                  T, N, c, inst[2:0]);
   wire `L incaddr, dataw, datas;
   wire tos2r, tos2n;
   wire incby, bswap, addrsel, access, rd;
   wire [1:0] wr;

   assign incby = (inst[4:2] != 3'b101);
   assign access = (inst[4:3]==2'b10);
   assign addrsel = rd ? 
         (access & (inst[1:0] != 2'b11)) : |wr;
   assign rd = (state==2'b00) || 
               (access && (inst[1:0]!=2'b00));
   assign wr = (access && (inst[1:0]==2'b00)) ?
               { ~inst[2] | ~T[0], 
                 ~inst[2] | T[0] } : 2'b00;
   mux #(l) addrmux(addr, addrsel, 1'b0, T, P);
   assign incaddr = addr + incby + 1;
   assign tos2n = (!rd | (inst[1:0] == 2'b11));
   mux #(l) toNmux(toN, tos2n, atpg, T, dataw);
   assign bswap = incby ^ addr[0];
   assign datas = bswap ? data : { data[7:0], data[l-1:8] };
   assign dataw = incby ? datas : { 8'h00, datas[7:0] }; 
   assign dataout = { bswap ? N[15:8] : N[7:0], 
                      bswap ? N[7:0]  : N[15:8] }; 
   reg dpush, rpush;

   always @(state or inst or rd or run `ifdef DEBUGGING
                                       or run or dw or daddr
                                       `endif)
     begin
        rpush = 1'b0;
        dpush = (|state[1:0] & rd) |
                (inst[4] && inst[3] && inst[1]);
        casez(inst)
           5'b00001: rpush = |state[1:0] | run;
           5'b11100: rpush = 1'b1;
        endcase // case(inst)
        `ifdef DEBUGGING
        if(!run && dw) casez(daddr)
           3'h0: dpush = 1;
           3'h1: rpush = 1;
        endcase
        `endif
     end
   wire [sdep-1:0] spdec, spinc;
   wire [rdep-1:0] rpdec, rpinc;

   stack #(sdep,l) dstack(clk, sp, spdec, 
                          dpush, scanning, toN, N);
   stack #(rdep,l) rstack(clk, rp, rpdec, 
                          rpush, scanning, R, toR);

   assign spdec = sp-{{(sdep-1){1'b0}}, 1'b1};
   assign spinc = sp+{{(sdep-1){1'b0}}, 1'b1};
   assign rpdec = rp-{{(rdep-1){1'b0}}, 1'b1};
   assign rpinc = rp+{{(rdep-1){1'b0}}, 1'b1};
   wire [1:0] nextstate;

   assign nextstate = ((~|inst) || (|inst[4:3])) ?
                      state[1:0] + 2'b01 : 2'b00;
   `ifdef DEBUGGING
   reg `L dout;

   always @(daddr or dr or run or P or T or R or I or
            state or sp or rp or c or N or toR or bp)
   `ifdef BUSTRI
   if(!dr || run) dout = 'hz;
   `else
   if(!dr || run) dout = 'h0;
   `endif
   else casez(daddr)
      3'h0: dout = N;
      3'h1: dout = toR;
      3'h2: dout = bp;
      3'h3: dout = { run, 4'h0, c, state,
                     {4-sdep{1'b0}}, sp,
                     {4-rdep{1'b0}}, rp };
      3'h4: dout = P;
      3'h5: dout = T;
      3'h6: dout = R;
      3'h7: dout = I;
   endcase
   `endif

   always @(posedge clk or negedge reset)
      if(!reset) begin
         state <= 2'b11;
         P <= rstaddr;
         T <= 16'h0000;
         I <= 16'h0000;
         R <= 16'h0000;
         c <= 1'b0;
         sp <= 0;
         rp <= 0;
      end else if(run) begin
         if(show) begin
            $write("%b[%b] T=%b%x:%x[%x], ",
                   inst, state, c, T, N, sp);
            $write("P=%x, I=%x, R=%x[%x], res=%b%x\n",
                   P, I, R, rp, carry, res);
         end
         if(~|state[1:0] || 
            ((inst[4:3] == 2'b10) && (inst[1:0] == 2'b11))) 
            P <= incaddr;
         if(|state[1:0]) begin 
            if(rd && { inst[4:3], inst[1:0] } != 4'b1010) 
               sp <= spdec;
            if(|wr) sp <= spinc;
         end else begin 
            I <= data; 
            if(!data[15]) state[1:0] <= 2'b01;
         end
         state <= nextstate;
         casez(inst)
            5'b00001: begin
               rp <= rpdec;
               R <= { state == 2'b00 ? incaddr[15:1] : P[15:1], c };
               P <= jmp;
               c <= 1'b0;
               if(state == 2'b11) `DROP;
            end // case: 5'b00001
            5'b00010: begin
               P <= jmp;
               if(state == 2'b11) `DROP;
            end
            5'b00011: { rp, c, P, R } <= 
                      { rpinc, R[0], R[l-1:1], 1'b0, toR };
            5'b001??: begin
               if((inst[1] ? c : zero) ^ inst[0]) 
                  P <= jmp;
               `DROP;
            end
            5'b01001: { c, T } <= { 1'b1, ~T };
            5'b01110: { T, R, c } <= 
               { c ? { carry, res } : { 1'b0, T }, R };
            5'b01111: { c, T, R } <= 
               { (c | carry) ? res : T, R, (c | carry) };
            `ifndef FPGA
            5'b01???: { sp, c, T } <= { spinc, carry, res }; 
            `else
            5'b01000: { sp, c, T } <= { spinc, carry, res };
            5'b01010: { sp, c, T } <= { spinc, carry, res };
            5'b01011: { sp, c, T } <= { spinc, carry, res };
            5'b01100: { sp, c, T } <= { spinc, carry, res };
            5'b01101: { sp, c, T } <= { spinc, carry, res }; 
            `endif
            5'b10?0?: begin
               if(nextstate != 2'b10) T <= incaddr;
               sp <= rd ? spdec : spinc;
            end
            5'b10?1?: T <= dataw;
            5'b11000: sp <= spinc;
            5'b11001: `DROP;
            5'b11010: { sp, T } <= { spdec, N };
            5'b11011: sp <= spdec;
            5'b11100: begin
               R <= T; rp <= rpdec; `DROP;
            end // case: 5'b11100
            5'b11110: begin
               { sp, T, R } <= { spdec, R, toR };
               rp <= rpinc;
            end // case: 5'b11110
         endcase // case(inst)
      end else begin // debug
         `ifdef DEBUGGING
         if(dw) casez(daddr)
            3'h0: { sp, T } <= { spdec, din };
            3'h1: { rp, R } <= { rpdec, din };
            3'h3: { c, state, sp, rp } <= 
                    { din[10:8],
                      din[sdep+3:4], din[rdep-1:0] };
            3'h4: P <= din;
            3'h5: T <= din;
            3'h6: R <= din;
            3'h7: I <= din;
         endcase
         if(dr) casez(daddr)
            3'h0: sp <= spinc;
            3'h1: rp <= rpinc;
         endcase
         `endif
      end // else: !if(reset)

endmodule // cpu
`ifdef DEBUGGING
module debugger(clk, nreset, run,
                addr, data, r, w,
                cpu_addr, cpu_r,
                drun, dr, dw, bp);
parameter l=16, dbgaddr = 12'hFFE;
input clk, nreset, run, r, cpu_r;
input [1:0] w;
input `L addr, data, cpu_addr;
output drun, dr, dw;
output `L bp;

reg drun, drun1;
reg `L bp;
wire dsel = (addr[l-1:4] == dbgaddr);
assign dr = dsel & r;
assign dw = dsel & |w;

always @(posedge clk or negedge nreset)
if(!nreset) begin
   drun <= 1;
   drun1 <= 1;
   bp <= 16'hffff;
end else begin
   if(cpu_addr == bp && cpu_r) { drun, drun1 } <= 0;
   else if(run) drun <= drun1;
   if((dr | dw) && (addr[3:1] == 3'h3)) begin
      drun <= !dr & dw;
      drun1 <= !dr & dw & data[12];
   end
   if(dw && addr[3:1] == 3'h2) bp <= data;
end

endmodule
`endif
