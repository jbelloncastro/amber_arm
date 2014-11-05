//////////////////////////////////////////////////////////////////
//                                                              //
//  ECC Encoder for error correction and detection memory       //
//                                                              //
//                                                              //
//  Description                                                 //
//  Error correction code generator                             //
//  It takes one word of data and generates the appropiate      //
//  redundant information in order to be able to later check    //
//  whether the read data has been corrupted or not.          //
//                                                              //
//  Author(s):                                                  //
//      - Jorge Bellon Castro, jorge.bellon@est.fib.upc.edu     //
//                                                              //
//////////////////////////////////////////////////////////////////
//                                                              //
// Copyright (C) 2014 Jorge Bellon Castro                       //
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

module ecc_encoder
#(
// begin parameters
parameter ECC_WIDTH = 32,
parameter DATA_WIDTH = 32
// end parameters
)
(
input                               i_clk, // may not be necessary

// Read / Write requests from core
input                               i_request,
input      [DATA_WIDTH-1:0]         i_data,
output                              o_done,
output     [ECC_WIDTH-1:0]          o_ecc_code
);

assign o_done = 1'b1;
assign o_ecc_code[DATA_WIDTH-1:0]  = i_data[ECC_WIDTH-1:0];

endmodule