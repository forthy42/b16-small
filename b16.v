/*
 * b16 core: 16 bits, 
 * inspired by c18 core from Chuck Moore
 * (c) 2002-2011 by Bernd Paysan
 * 
 * This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; version 2 of the License or any later.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   This is not the source code of the program, the source code is a LyX
   literate programming style article.
 */
/*
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

module alu(res, carry, zero, T, N, c, inst);
   parameter l=16;
   input `L T, N;
   input c;
   input [2:0] inst;
   output `L res;
   output carry, zero;

   wire prop, andor, selr;

   assign { prop, selr, andor } = inst;

   wire        `L r1, r2;
   wire [l:0]  carries;

   assign r1 = T ^ N ^ carries;
   assign r2 = (T & N) | 
               (T & carries`L) | 
               (N & carries`L);
// This generates a carry *chain*, not a loop!
   assign carries = 
        prop ? { r2[l-1:0], (c | selr) & andor } 
             : { c, {(l){andor}}};
   assign res = (selr & ~prop) ? r2 : r1;
   assign carry = carries[l];
   assign zero = ~|T;
endmodule // alu
module stack(clk, sp, spdec, push, gwrite, in, out);
   parameter dep=2, l=16;
   input clk, push, gwrite;
   input [dep-1:0] sp, spdec;
   input `L in;
   output `L out;

   reg `L stackmem[0:(1<<dep)-1];

`ifndef FPGA
   reg [dep-1:0] i;

   always @(clk or push or gwrite or spdec or in)
      if(~clk)
         if(gwrite)
            for(i=0; i<(1<<dep); i=i+1)
               stackmem[i] <= in;
         else if(push) stackmem[spdec] <= in;
`else
   always @(posedge clk)
      if(push)
         stackmem[spdec] <= in;
`endif

  assign out = stackmem[sp];

endmodule // stack
module cpu(clk, latclk, run, nreset, addr, rd, wr, data, 
           dataout, gwrite
`ifdef DEBUGGING,
           dr, dw, daddr, din, dout, bp`endif);
   parameter rstaddr=16'h3FFE, show=0,
             l=16, sdep=4, rdep=4;
   input clk, latclk, run, nreset, gwrite;
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
   wire [4:0] inst, rwinst;
   reg `L jmp;

   assign inst = { 4'b0000, data[15], I[14:0] }
                 >> (5*(3-state[1:0]));
   assign rwinst = { 5'b00000, I[14:0] }
                   >> (5*(3-state[1:0]));

   always @(state or I or P or T or data)
      case(state[1:0])
        2'b00: jmp = { data[14:0], 1'b0 };
        2'b01: jmp = { P[15:11], I[9:0], 1'b0 };
        2'b10: jmp = { P[15:6], I[4:0], 1'b0 };
        2'b11: jmp = { T[15:1], 1'b0 };
      endcase // casez(state)
   wire `L res, toN, toR, N;
   wire carry, zero;

   alu #(l) alu16(.res(res), .carry(carry),
                  .zero(zero), 
                  .T(T), .N(N), .c(c),
                  .inst(inst[2:0]));
   wire `L incaddr, dataw, datas;
   wire tos2r, tos2n;
   wire incby, bswap, addrsel, access, rd;
   wire [1:0] wr;

   assign incby = (rwinst[4:2] != 3'b101);
   assign access = (rwinst[4:3]==2'b10);
   assign addrsel = rd ? 
         (access & (rwinst[1:0] != 2'b11)) : |wr;
   assign rd = (state==2'b00) || 
               (access && (rwinst[1:0]!=2'b00));
   assign wr = (access && (rwinst[1:0]==2'b00)) ?
               { ~rwinst[2] | ~T[0], 
                 ~rwinst[2] | T[0] } : 2'b00;
   assign addr = addrsel ? T : P;
   assign incaddr = addr + incby + 1;
   assign tos2n = (!rd | (rwinst[1:0] == 2'b11));
   assign toN = tos2n ? T : dataw;
   assign bswap = ~incby ^ addr[0];
   assign datas = bswap ? { data[7:0], data[l-1:8] }
                        : data;
   assign dataw = incby ? datas
                        : { 8'h00, datas[7:0] }; 
   assign dataout = bswap ? { N[7:0], N[l-1:8] }
                          : N; 
   reg dpush, rpush;

   always @(state or inst or rd or run `ifdef DEBUGGING
                                       or run or dw or daddr
                                       `endif)
     begin
        rpush = 1'b0;
        dpush = (|state[1:0] & rd) |
                (inst[4] && inst[3] && inst[1]);
        case(inst)
           5'b00001: rpush = |state[1:0] | run;
           5'b11100: rpush = 1'b1;
           default ;
        endcase // case(inst)
        `ifdef DEBUGGING
        if(!run && dw) case(daddr)
           3'h0: dpush = 1;
           3'h1: rpush = 1;
           default ;
        endcase
        `endif
     end
   wire [sdep-1:0] spdec, spinc;
   wire [rdep-1:0] rpdec, rpinc;

   stack #(sdep,l) dstack(.clk(latclk),
                          .sp(sp),
                          .spdec(spdec),
                          .push(dpush),
                          .in(toN),
                          .out(N),
                          .gwrite(gwrite));
   stack #(rdep,l) rstack(.clk(latclk),
                          .sp(rp),
                          .spdec(rpdec),
                          .push(rpush),
                          .in(R),
                          .out(toR),
                          .gwrite(gwrite));

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
   if(!dr || run) dout = 'h0;
   else case(daddr)
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

   always @(posedge clk or negedge nreset)
      if(!nreset) begin
         state <= 2'b11;
         P <= rstaddr;
         T <= 16'h0000;
         I <= 16'h0000;
         R <= 16'h0000;
         c <= 1'b0;
         sp <= 0;
         rp <= 0;
      end else if(run) begin
      `ifdef REPORT_VERBOSE
         if(show) begin
            $write("%b[%b] T=%b%x:%x[%x], ",
                   inst, state, c, T, N, sp);
            $write("P=%x, I=%x, R=%x[%x], res=%b%x\n",
                   P, I, R, rp, carry, res);
         end
      `endif
         if(~|state || 
            ({ inst[4:3], inst[1:0] } == 4'b1011))
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
         case(inst)
            5'b00001: begin // call
               rp <= rpdec;
               R <= { ~|state ? incaddr[15:1] : P[15:1], c };
               P <= jmp;
               c <= 1'b0;
               if(state == 2'b11) `DROP;
            end // case: 5'b00001
            5'b00010: begin // jmp
               P <= jmp;
               if(state == 2'b11) `DROP;
            end
            5'b00011: // ret
                      { rp, c, P, R } <= 
                      { rpinc, R[0], R[l-1:1], 1'b0, toR };
            5'b00100, 5'b00101, 5'b00110, 5'b00111:
            begin // conditional jmps
               if((inst[1] ? c : zero) ^ inst[0]) 
                  P <= jmp;
               `DROP;
            end
            5'b01001: // com
               { c, T } <= { 1'b1, ~T };
            5'b01110: // *+
               { T, R, c } <=
               { c ? { carry, res } : { 1'b0, T }, R };
            5'b01111: // /-
               { c, T, R } <=
               { (c | carry) ? res : T, R, (c | carry) };
            5'b01000, 5'b01010, 5'b01011, 5'b01100, 5'b01101:
               // xor, and, or, +, +c
               { sp, c, T } <= { spinc, carry, res };
            5'b10000, 5'b10001, 5'b10100, 5'b10101:
            begin        // !+, @+, c!+, c@+
               if(nextstate != 2'b10) T <= incaddr;
               sp <= rd ? spdec : spinc;
            end
            5'b10010, 5'b10011, 5'b10110, 5'b10111:
               T <= dataw;  // @, lit, c@, litc
            5'b11000: sp <= spinc;               // nip
            5'b11001: `DROP;                     // drop
            5'b11010: { sp, T } <= { spdec, N }; // over
            5'b11011: sp <= spdec;               // dup
            5'b11100: begin                      // >r
               R <= T; rp <= rpdec; `DROP;
            end // case: 5'b11100
            5'b11110: begin                      // r>
               { sp, T, R } <= { spdec, R, toR };
               rp <= rpinc;
            end // case: 5'b11110
            default ;                            // noop
         endcase // case(inst)
      end else begin // debug
         `ifdef DEBUGGING
         if(dw) case(daddr)
            3'h0: { sp, T } <= { spdec, din };
            3'h1: { rp, R } <= { rpdec, din };
            3'h3: { c, state, sp, rp } <= 
                    { din[10:8],
                      din[sdep+3:4], din[rdep-1:0] };
            3'h4: P <= din;
            3'h5: T <= din;
            3'h6: R <= din;
            3'h7: I <= din;
            default ;
         endcase
         if(dr) case(daddr)
            3'h0: sp <= spinc;
            3'h1: rp <= rpinc;
            default ;
         endcase
         `endif
      end // else: !if(nreset)

endmodule // cpu
`ifdef DEBUGGING
module debugger(clk, nreset, run,
                addr, data, r, w,
                cpu_addr, cpu_r,
                drun, dr, dw, bp);
parameter l=16, dbgaddr = 12'hFFE;
input clk, nreset, run, r, cpu_r;
input [1:0] w;
input [l-1:1] addr;
input `L data, cpu_addr;
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
   if(cpu_addr == bp && cpu_r)
      { drun, drun1 } <= 0;
   else if(run) drun <= drun1;
   if((dr | dw) && (addr[3:1] == 3'h3)) begin
      drun <= !dr & dw;
      drun1 <= !dr & dw & data[12];
   end
   if(dw && addr[3:1] == 3'h2) bp <= data;
end

endmodule
`endif
