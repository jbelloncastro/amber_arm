//////////////////////////////////////////////////////////////////
//                                                              //
//  ECC error detector and corrector                            //
//                                                              //
//                                                              //
//  Description                                                 //
//  Validates the correctness of the read data.                 //
//  If the data is corrupted, it either corrects it or it       //
//  specifies that the output data is not valid.                //
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
parameter WB_DWIDTH = 32
// end parameters
)
(
input                               i_clk, // may not be necessary
input                               i_request,
input      [WB_DWIDTH-1:0]          i_data, // data to be checked (coming from memory)
input      [ECC_WIDTH-1:0]          i_ecc,  // data coming from ecc memory
output                              o_done, // indicates that the verification has been completed
output                              o_error,// indicates that the data is not usable (is invalid)
output     [WB_DWIDTH-1:0]          o_data  // output data. only valid when o_error is inactive
);

    // INTERNAL VARIABLES
    parameter IDLE  = 2'd0, // waiting for a new request
              WAIT  = 2'd1, // waiting for generated ecc
              CHECK = 2'd2; // checking data
    wire [ECC_WIDTH-1:0] generated_ecc;
    reg [1:0] status;
    reg error;
    //reg [WB_DWIDTH-1:0] o_data; // We hold here the valid/corrected data. 
                                 // For the moment we cannot correct data (should be reg type instead).
    
    // COMBINATIONAL LOGIC
    
    // Sub-module instances:
    // Encoder
    // An additional encoder is needed here in order to encode data read from memory 
    // and compare it to the previously computed ecc.
    // In a future the main encoder can be reused because only one will be used at the same time
    ecc_encoder #(
                .ECC_WIDTH             ( ECC_WIDTH          )
                )
    encoder (    
                .i_clk                 ( i_clk              ),
                .i_request             ( i_request          ),
                .i_data                ( i_data             ),
                .o_ecc_code            ( generated_ecc      )
            );
    
    // SEQUENTIAL LOGIC
    always @ ( posedge i_clk )
    begin
      case( status )
        IDLE:
          if ( i_request ) begin
            status <= WAIT;
            error <= 1'b0;
          end
        WAIT: begin
            // we may need to wait for the 2nd ecc to be generated
            status <= CHECK;
          end
        CHECK: begin
            status <= IDLE;
            if ( i_ecc != generated_ecc ) begin
              error <= 1'b1;
            end
          end
        default: begin
            status <= IDLE;
          end
      endcase
    end
    
    // OUTPUT LOGIC
    // We are done meanwhile we remain in idle state.
    assign o_done = status == IDLE;
    assign o_data = i_data;
    assign o_error = error;
endmodule