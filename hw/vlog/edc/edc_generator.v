//////////////////////////////////////////////////////////////////
//                                                              //
//  EDC Generator module.                                       //
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


module edcg_mod #() (

input   [31:0]  ID,
input   [7:0]   IC,
input           R,
output  [7:0]   S

);
  
wire    [15:0]    XA;
wire    [7:0]     XB, XC, XD, XE, F, G, H;

xor XA0(XA[0], ID[0], ID[1]);
xor XA1(XA[1], ID[2], ID[3]);
xor XA2(XA[2], ID[4], ID[5]);
xor XA3(XA[3], ID[6], ID[7]);
xor XA4(XA[4], ID[8], ID[9]);
xor XA5(XA[5], ID[10], ID[11]);
xor XA6(XA[6], ID[12], ID[13]);
xor XA7(XA[7], ID[14], ID[15]);
xor XA8(XA[8], ID[16], ID[17]);
xor XA9(XA[9], ID[18], ID[19]);
xor XA10(XA[10], ID[20], ID[21]);
xor XA11(XA[11], ID[22], ID[23]);
xor XA12(XA[12], ID[24], ID[25]);
xor XA13(XA[13], ID[26], ID[27]);
xor XA14(XA[14], ID[28], ID[29]);
xor XA15(XA[15], ID[30], ID[31]);

xor F0(F[0], XA[0], XA[1]);
xor F1(F[1], XA[2], XA[3]);
xor F2(F[2], XA[4], XA[5]);
xor F3(F[3], XA[6], XA[7]);
xor F4(F[4], XA[8], XA[9]);
xor F5(F[5], XA[10], XA[11]);
xor F6(F[6], XA[12], XA[13]);
xor F7(F[7], XA[14], XA[15]);

and H0(H[0], IC[0], R);
and H1(H[1], IC[1], R);
and H2(H[2], IC[2], R);
and H3(H[3], IC[3], R);
and H4(H[4], IC[4], R);
and H5(H[5], IC[5], R);
and H6(H[6], IC[6], R);
and H7(H[7], IC[7], R);

xor XB0(XB[0], ID[0], ID[4]);
xor XB1(XB[1], ID[1], ID[5]);
xor XB2(XB[2], ID[2], ID[6]);
xor XB3(XB[3], ID[3], ID[7]);
xor XB4(XB[4], ID[16], ID[20]);
xor XB5(XB[5], ID[17], ID[21]);
xor XB6(XB[6], ID[18], ID[22]);
xor XB7(XB[7], ID[19], ID[23]);

xor XC0(XC[0], ID[8], ID[12]);
xor XC1(XC[1], ID[9], ID[13]);
xor XC2(XC[2], ID[10], ID[14]);
xor XC3(XC[3], ID[11], ID[15]);
xor XC4(XC[4], ID[24], ID[28]);
xor XC5(XC[5], ID[25], ID[29]);
xor XC6(XC[6], ID[26], ID[30]);
xor XC7(XC[7], ID[27], ID[31]);

xor XE0(XE[0], XB[0], XC[0]);
xor XE1(XE[1], XB[1], XC[1]);
xor XE2(XE[2], XB[2], XC[2]);
xor XE3(XE[3], XB[3], XC[3]);
xor XE4(XE[4], XB[4], XC[4]);
xor XE5(XE[5], XB[5], XC[5]);
xor XE6(XE[6], XB[6], XC[6]);
xor XE7(XE[7], XB[7], XC[7]);

xor G0(G[0], F[0], F[1]);
xor G1(G[1], F[2], F[3]);
xor G2(G[2], F[0], F[2]);
xor G3(G[3], F[1], F[3]);
xor G4(G[4], F[4], F[5]);
xor G5(G[5], F[6], F[7]);
xor G6(G[6], F[4], F[6]);
xor G7(G[7], F[5], F[7]);

xor XD0(XD[0], G[4], H[0]);
xor XD1(XD[1], G[5], H[1]);
xor XD2(XD[2], G[6], H[2]);
xor XD3(XD[3], G[7], H[3]);
xor XD4(XD[4], G[0], H[4]);
xor XD5(XD[5], G[1], H[5]);
xor XD6(XD[6], G[2], H[6]);
xor XD7(XD[7], G[3], H[7]);

xor S0(S[0], XD[0], XE[0]);
xor S1(S[1], XD[1], XE[1]);
xor S2(S[2], XD[2], XE[2]);
xor S3(S[3], XD[3], XE[3]);
xor S4(S[4], XD[4], XE[4]);
xor S5(S[5], XD[5], XE[5]);
xor S6(S[6], XD[6], XE[6]);
xor S7(S[7], XD[7], XE[7]);

endmodule
