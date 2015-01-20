//////////////////////////////////////////////////////////////////
//                                                              //
// ECC Encoder for error correction and detection memory        //
//                                                              //
//                                                              //
// Description                                                  //
// Error correcting code generator                              //
// This module takes one word of data as input and generates    //
// an error correcting code (ECC).                              //
// The ECC allows error detection and correction depending on   //
// how it was generated and its size.                           //
// A write_enabled flag and an ECC are also taken as input so   //
// that we can reuse this module for WRITE operations (only ECC //
// generation) and READ operations (compute difference between  //
// the ECC coming from memory and the generated, aka syndrome). //
//                                                              //
// This module implements the (40,32) parity check matrix used  //
// for IBM 8130.                                                //
// Notes: this module is not parameterized because the parity   //
// check matrix varies depending on input data width and        //
// desired ECC width and must be 'hardcoded'.                   //
// Reference: Error-Correcting Codes for Semiconductor Memory   //
// Applications: A State-of-the-Art Review                      //
//                                                              //
// Author(s):                                                   //
// - Jorge Bellon Castro, jorge.bellon@est.fib.upc.edu          //
// - Carlos Diaz Suarez, carlos.diaz@bsc.es                     //
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
// PURPOSE. See the GNU Lesser General Public License for more  //
// details.                                                     //
//                                                              //
// You should have received a copy of the GNU Lesser General    //
// Public License along with this source; if not, download it   //
// from http://www.opencores.org/lgpl.shtml                     //
//                                                              //
//////////////////////////////////////////////////////////////////

module edc_generator #() (

input   [31:0]  i_data,                  // Input data bus
input   [7:0]   i_ecc, // Input ECC (only relevant when write_enabled_i == 0)
input           i_write_enabled,         // Write enabled flag
output  [7:0]   o_ecc_syndrome           // Generated ecc (write_enabled_i == 1) or Syndrome (write_enabled_i == 0)

);

wire [31:0] parity_check_matrix[0:7];
wire [7:0] generated_ecc;

// Parity check matrix definition
generate
// Parity check matrix
	assign parity_check_matrix[7] = 32'b10101010_10101010_11000000_11000000;//10000000;
	assign parity_check_matrix[6] = 32'b01010101_01010101_00110000_00110000;//01000000;
	assign parity_check_matrix[5] = 32'b11111111_00000000_00001100_00001100;//00100000;
	assign parity_check_matrix[4] = 32'b00000000_11111111_00000011_00000011;//00010000;
	assign parity_check_matrix[3] = 32'b11000000_11000000_11111111_00000000;//00001000;
	assign parity_check_matrix[2] = 32'b00110000_00110000_00000000_11111111;//00000100;
	assign parity_check_matrix[1] = 32'b00001100_00001100_10101010_10101010;//00000010;
	assign parity_check_matrix[0] = 32'b00000011_00000011_01010101_01010101;//00000001;
endgenerate

// ECC computation
genvar r,c;
generate
	for (r=0; r<8; r=r+1) begin
		// Compute the ECC as the 'sum-product' of all elements of the row by the elements of the word
		// Product: logic AND; Sum (mod 2): logic XOR
		assign generated_ecc[r] = ( ^ ( parity_check_matrix[r] & i_data ));

		// Return either difference (XOR) between generated ecc and input ecc or just the generated one
		// depending if we are performing a READ operation (first case) or a WRITE (second case).
		assign o_ecc_syndrome[r] = i_write_enabled ? generated_ecc[r] : generated_ecc[r] ^ i_ecc[r];
	end
endgenerate

endmodule
