
//////////////////////////////////////////////////////////////////
//                                                              //
//  EDC Corrector module.                                     //
//                                                              //
//  This file is part of the Amber project                      //
//  http://www.opencores.org/project,amber                      //
//                                                              //
//  Description                                                 //
//  Non-synthesizable main memory. Holds 128MBytes              //
//  The memory path in this module is purely combinational.     //
//  Addresses and write_cmd_req data are registered as          //
//  the leave the execute module and read data is registered    //
//  as it enters the instruction_decode module.                 //
//                                                              //
//  Author(s):                                                  //
//      - Jorge Bellon Castro, jorge.bellon@est.fib.upc.edu     //
//      - Carlos Diaz Suarez, carlos.diaz@bsc.es                //
//                                                              //
//////////////////////////////////////////////////////////////////
//                                                              //
// Copyright (C) 2010 Authors and OPENCORES.ORG                 //
//                                                              //
// This source file may be used and distributed without         //
// restriction provided that this copyright statement is not    //
// removed from the file and that any derivative work contains  //
// the original copyright notice and the associated disclaimer. //
//                                                              //
// This source file is free software; you can redistribute it   //
// and/or modify it under the terms of the GNU Lesser General   //
// Public License as published by the Free Software Foundation; //
// either version 2.1 of the License, or (at your option) any   //
// later version.                                               //
//                                                              //
// This source is distributed in the hope that it will be       //
// useful, but WITHOUT ANY WARRANTY; without even the implied   //
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      //
// PURPOSE.  See the GNU Lesser General Public License for more //
// details.                                                     //
//                                                              //
// You should have received a copy of the GNU Lesser General    //
// Public License along with this source; if not, download it   //
// from http://www.opencores.org/lgpl.shtml                     //
//                                                              //
//////////////////////////////////////////////////////////////////

module edcc_mod (
  
input   [31:0]  ID,
input   [7:0]   S,
output  [31:0]  OD,
output          UE,
output          ED

);

wire  [31:0]  E;
wire          NC; // No correction
wire  [7:0]   T, W;
wire  [4:0]   S0B, S1B, S2B, S3B, S4B, S5B, S6B, S7B;
wire  [1:0]   U;

or ED0(ED, S[0], S[1], S[2], S[3], S[4], S[5], S[6], S[7]);

nor NC0(NC, E[0], E[1], E[2], E[3], E[4], E[5], E[6], E[7],
 E[8], E[9], E[10], E[11], E[12], E[13], E[14], E[15],
 E[16], E[17], E[18], E[19], E[20], E[21], E[22], E[23],
 E[24], E[25], E[26], E[27], E[28], E[29], E[30], E[31]);
 
and UE0(UE, ED, NC);

not S0B0(S0B[0], S[0]);
not S0B1(S0B[1], S[0]);
not S0B2(S0B[2], S[0]);
not S0B3(S0B[3], S[0]);
not S0B4(S0B[4], S[0]);
not S1B0(S1B[0], S[1]);
not S1B1(S1B[1], S[1]);
not S1B2(S1B[2], S[1]);
not S1B3(S1B[3], S[1]);
not S1B4(S1B[4], S[1]);
not S2B0(S2B[0], S[2]);
not S2B1(S2B[1], S[2]);
not S2B2(S2B[2], S[2]);
not S2B3(S2B[3], S[2]);
not S2B4(S2B[4], S[2]);
not S3B0(S3B[0], S[3]);
not S3B1(S3B[1], S[3]);
not S3B2(S3B[2], S[3]);
not S3B3(S3B[3], S[3]);
not S3B4(S3B[4], S[3]);
not S4B0(S4B[0], S[4]);
not S4B1(S4B[1], S[4]);
not S4B2(S4B[2], S[4]);
not S4B3(S4B[3], S[4]);
not S4B4(S4B[4], S[4]);
not S5B0(S5B[0], S[5]);
not S5B1(S5B[1], S[5]);
not S5B2(S5B[2], S[5]);
not S5B3(S5B[3], S[5]);
not S5B4(S5B[4], S[5]);
not S6B0(S6B[0], S[6]);
not S6B1(S6B[1], S[6]);
not S6B2(S6B[2], S[6]);
not S6B3(S6B[3], S[6]);
not S6B4(S6B[4], S[6]);
not S7B0(S7B[0], S[7]);
not S7B1(S7B[1], S[7]);
not S7B2(S7B[2], S[7]);
not S7B3(S7B[3], S[7]);
not S7B4(S7B[4], S[7]);

and T0(T[0], S0B[0], S1B[0], S2B[0], S[3]);
and T1(T[1], S0B[1], S1B[1], S[2], S3B[0]);
and T2(T[2], S0B[2], S[1],   S2B[1], S3B[1]);
and T3(T[3], S[0],   S1B[2], S2B[2], S3B[2]);
and T4(T[4], S4B[0], S5B[0], S6B[0], S[7]);
and T5(T[5], S4B[1], S5B[1], S[6], S7B[0]);
and T6(T[6], S4B[2], S[5],   S6B[1], S7B[1]);
and T7(T[7], S[4],   S5B[2], S6B[2], S7B[2]);

or U0(U[0], T[0], T[1], T[2], T[3]);
or U1(U[1], T[4], T[5], T[6], T[7]);

and W0(W[0], S[4], S5B[3], S[6], S7B[3], U[0]);
and W1(W[1], S[4], S5B[4], S6B[3], S[7], U[0]);
and W2(W[2], S4B[3], S[5], S[6], S7B[4], U[0]);
and W3(W[3], S4B[4], S[5], S6B[4], S[7], U[0]);
and W4(W[4], S[0], S1B[3], S[2], S3B[3], U[1]);
and W5(W[5], S[0], S1B[4], S2B[3], S[3], U[1]);
and W6(W[6], S0B[3], S[1], S[2], S3B[4], U[1]);
and W7(W[7], S0B[4], S[1], S2B[4], S[3], U[1]);

and E0(E[0], W[0], S[0]);
and E1(E[1], W[0], S[1]);
and E2(E[2], W[0], S[2]);
and E3(E[3], W[0], S[3]);
and E4(E[4], W[1], S[0]);
and E5(E[5], W[1], S[1]);
and E6(E[6], W[1], S[2]);
and E7(E[7], W[1], S[3]);
and E8(E[8], W[2], S[0]);
and E9(E[9], W[2], S[1]);
and E10(E[10], W[2], S[2]);
and E11(E[11], W[2], S[3]);
and E12(E[12], W[3], S[0]);
and E13(E[13], W[3], S[1]);
and E14(E[14], W[3], S[2]);
and E15(E[15], W[3], S[3]);
and E16(E[16], W[4], S[4]);
and E17(E[17], W[4], S[5]);
and E18(E[18], W[4], S[6]);
and E19(E[19], W[4], S[7]);
and E20(E[20], W[5], S[4]);
and E21(E[21], W[5], S[5]);
and E22(E[22], W[5], S[6]);
and E23(E[23], W[5], S[7]);
and E24(E[24], W[6], S[4]);
and E25(E[25], W[6], S[5]);
and E26(E[26], W[6], S[6]);
and E27(E[27], W[6], S[7]);
and E28(E[28], W[7], S[4]);
and E29(E[29], W[7], S[5]);
and E30(E[30], W[7], S[6]);
and E31(E[31], W[7], S[7]);

xor OD0(OD[0], ID[0], E[0]);
xor OD1(OD[1], ID[1], E[1]);
xor OD2(OD[2], ID[2], E[2]);
xor OD3(OD[3], ID[3], E[3]);
xor OD4(OD[4], ID[4], E[4]);
xor OD5(OD[5], ID[5], E[5]);
xor OD6(OD[6], ID[6], E[6]);
xor OD7(OD[7], ID[7], E[7]);
xor OD8(OD[8], ID[8], E[8]);
xor OD9(OD[9], ID[9], E[9]);
xor OD10(OD[10], ID[10], E[10]);
xor OD11(OD[11], ID[11], E[11]);
xor OD12(OD[12], ID[12], E[12]);
xor OD13(OD[13], ID[13], E[13]);
xor OD14(OD[14], ID[14], E[14]);
xor OD15(OD[15], ID[15], E[15]);
xor OD16(OD[16], ID[16], E[16]);
xor OD17(OD[17], ID[17], E[17]);
xor OD18(OD[18], ID[18], E[18]);
xor OD19(OD[19], ID[19], E[19]);
xor OD20(OD[20], ID[20], E[20]);
xor OD21(OD[21], ID[21], E[21]);
xor OD22(OD[22], ID[22], E[22]);
xor OD23(OD[23], ID[23], E[23]);
xor OD24(OD[24], ID[24], E[24]);
xor OD25(OD[25], ID[25], E[25]);
xor OD26(OD[26], ID[26], E[26]);
xor OD27(OD[27], ID[27], E[27]);
xor OD28(OD[28], ID[28], E[28]);
xor OD29(OD[29], ID[29], E[29]);
xor OD30(OD[30], ID[30], E[30]);
xor OD31(OD[31], ID[31], E[31]);

endmodule

