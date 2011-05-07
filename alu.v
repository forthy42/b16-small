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
