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
parameter ECC_WIDTH = 8,
parameter DATA_WIDTH = 32
// end parameters
)
(
// Read / Write requests from core
input                               i_request,
input      [DATA_WIDTH-1:0]         i_data,
output                              o_done,
output     [ECC_WIDTH-1:0]          o_ecc_code
);

assign o_done = 1'b1;

// IMPORTANT NOTE: it is supposed that the parity_check_matrix is in systematic form
// Reference: Error-Correcting Codes for Semiconductor Memory Applications: A State-of-the-Art Review
//wire [0:DATA_WIDTH+ECC_WIDTH-1]parity_check_matrix[0:ECC_WIDTH-1];
wire [39:0]parity_check_matrix[0:7];

genvar r,c;
// For the matrix-vector multiply: http://stackoverflow.com/questions/19165181/multiplying-2d-arrays-in-verilog
// Initialize values
generate
  // Parity check matrix
  assign parity_check_matrix[0] = 40'b10101010_10101010_11000000_11000000_10000000;
  assign parity_check_matrix[1] = 40'b01010101_01010101_00110000_00110000_01000000;
  assign parity_check_matrix[2] = 40'b11111111_00000000_00001100_00001100_00100000;
  assign parity_check_matrix[3] = 40'b00000000_11111111_00000011_00000011_00010000;
  assign parity_check_matrix[4] = 40'b11000000_11000000_11111111_00000000_00001000;
  assign parity_check_matrix[5] = 40'b00110000_00110000_00000000_11111111_00000100;
  assign parity_check_matrix[6] = 40'b00001100_00001100_10101010_10101010_00000010;
  assign parity_check_matrix[7] = 40'b00000011_00000011_01010101_01010101_00000001;
endgenerate

generate
  for (r=0; r<ECC_WIDTH; r=r+1) begin
    //assign o_ecc_code[r] = 1'b0;
    //for (c=0; c<DATA_WIDTH; c=c+1) begin
    //  assign o_ecc_code[r] = o_ecc_code[r] | (parity_check_matrix[r][c]==1'b1 & i_data[c]);
    //end
    assign o_ecc_code[r] = | ( parity_check_matrix[r] & i_data );
  end  
endgenerate

endmodule