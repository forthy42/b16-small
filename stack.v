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
`include "b16-defines.v"
module stack(clk, sp, spdec, push, gwrite, in, out);
   parameter dep=2, l=16;
   input clk, push, gwrite;
   input [dep-1:0] sp, spdec;
   input `L in;
   output `L out;

   reg `L stackmem[0:(1<<dep)-1];

`ifndef FPGA
   reg [dep:0] i;

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
