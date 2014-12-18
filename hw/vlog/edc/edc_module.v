//////////////////////////////////////////////////////////////////
//                                                              //
//  ECC protected memory module.                                //
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


module edc_mod#(

parameter WB_DWIDTH  = 32,
parameter WB_SWIDTH  = 4

)(

input                          edc_clk,
input                          edc_mem_ctrl,

// Wishbone Bus
input       [31:0]             edc_wb_adr,
input       [WB_SWIDTH-1:0]    edc_wb_sel,
input                          edc_wb_we,
output      [WB_DWIDTH-1:0]    edc_wb_dat_r,  // To Wishbone
input       [WB_DWIDTH-1:0]    edc_wb_dat_w,  // From Wishbone
input                          edc_wb_cyc,
input                          edc_wb_stb,
output                         edc_wb_ack,
output                         edc_wb_err
);
//=====================================
// Declarations
//=====================================
// Variables used in 'generate' blocks
//genvar i, // Used to iterate in loops
//       b, // Bus' least significant bit
//       e; // Bus' most significant bit (plus one)

// Buses and wires used to interconnect all the elements of the module
wire main_mem_err; // Drives the main memory error flag
wire main_mem_ack; // Drives the main memory ACK flag

wire [WB_DWIDTH-1:0] umain_read_data; // Data read from main memory
wire [31:0] ecc_mem_code_in; // Generated ECC that will be written into ECC memory

reg [31:0] generator_data_in[0:3]; // Data introduced in generator (from bus/main mem)
wire [7:0] syndrome_ecc[0:3]; // Diff between generated and read ECC
wire [31:0] ecc_mem_data; // Data read from ECC memory

wire [3:0]uncorrected_error; // Result from each of the correctors

//=====================================
// Instantiations
//=====================================

// Main memory
main_mem #(
  .WB_DWIDTH             ( WB_DWIDTH             ),
  .WB_SWIDTH             ( WB_SWIDTH             )
)
u_main_mem (
  .i_clk                  ( edc_clk                     ),
  .i_mem_ctrl             ( edc_mem_ctrl                ),
  .i_wb_adr               ( edc_wb_adr                  ),
  .i_wb_sel               ( edc_wb_sel                  ),
  .i_wb_we                ( edc_wb_we                   ),
  .o_wb_dat               ( /*umain_read_data*/         ), // To Corrector
  .i_wb_dat               ( edc_wb_dat_w                ), // From Wishbone
  .i_wb_cyc               ( edc_wb_cyc                  ),
  .i_wb_stb               ( edc_wb_stb                  ),
  .o_wb_ack               ( main_mem_ack                ),
  .o_wb_err               ( main_mem_err                )
);

//  ECC memory
generic_sram_line_en
#(
    .DATA_WIDTH          ( 32             ),
    .ADDRESS_WIDTH       ( 28             ),
    .INITIALIZE_TO_ZERO  ( 0              )
)
ecc_mem
(
    .i_clk          ( edc_clk              ),
    .i_write_enable ( edc_wb_we            ),
    .i_address      ( edc_wb_adr[31:4]     ),
    .o_read_data    ( ecc_mem_data         ),
    .i_write_data   ( ecc_mem_code_in      )
);

/*
main_mem #(
  .WB_DWIDTH             ( 32                    ),// 4x ecc width
  .WB_SWIDTH             ( WB_SWIDTH             )
)
ecc_mem (
  .i_clk                  ( edc_clk                   ),
  .i_mem_ctrl             ( edc_mem_ctrl              ),
  .i_wb_adr               ( edc_wb_adr                ),
  .i_wb_sel               ( edc_wb_sel                ),
  .i_wb_we                ( edc_wb_we                 ),
  .o_wb_dat               ( ecc_mem_data              ),  // To Generator   
  .i_wb_dat               ( ecc_mem_code_in           ),  // From Generator
  .i_wb_cyc               ( edc_wb_cyc                ),
  .i_wb_stb               ( edc_wb_stb                ),
  .o_wb_ack               (                           ),
  .o_wb_err               ( ecc_mem_err               )
);
*/

genvar i;
generate  
  localparam ecc_width = 8;
  localparam data_width = 32;
  
  // Error code generators
  for(i=0; i<4; i=i+1) begin    
    edc_generator gen (
      .i_data          ( generator_data_in[i]   ),                  // From multiplexor
      .i_ecc           ( ecc_mem_data[ecc_width*i+:ecc_width]    ), // From ECC memory
      .i_write_enabled ( edc_wb_we              ),                  // Write enabled flag (from bus)
      .o_ecc_syndrome  ( ecc_mem_code_in[ecc_width*i+:ecc_width] )  // To corrector/ECC memory
    );
  end
  
  // Error detection and correction modules
  for(i=0; i<4; i=i+1) begin
    edc_corrector cor (
      .i_data              ( umain_read_data[data_width*i+:data_width] ), // From main memory
      .i_syndrome          ( syndrome_ecc[i] ),                           // From generator[i]
      .o_data              ( edc_wb_dat_r[data_width*i+:data_width] ),    // Data output to bus
      .o_error_detected    ( ),
      .o_uncorrected_error ( uncorrected_error[i] )
    );
  end
endgenerate

//=====================================
// Interconections
//=====================================
// Multiplexor: select data source to feed the ECC generator
always@(edc_wb_we or edc_wb_dat_w or umain_read_data) 
begin
  case(edc_wb_we)
      'b1: begin// Wishbone
          generator_data_in[0] = edc_wb_dat_w[31:0];
          generator_data_in[1] = edc_wb_dat_w[63:32];
          generator_data_in[2] = edc_wb_dat_w[95:64];
          generator_data_in[3] = edc_wb_dat_w[127:96];
    end
      default: begin// From Main Memory
          generator_data_in[0] = umain_read_data[31:0];
          generator_data_in[1] = umain_read_data[63:32];
          generator_data_in[2] = umain_read_data[95:64];
          generator_data_in[3] = umain_read_data[127:96];
    end
  endcase
end

// Bus output synchronization flags
// ACK: simply use main memory's
assign edc_wb_ack = main_mem_ack;
// Error: Must be set either when the memory has an error
//                        or when an uncorrected error has been found.
// Activate only when the operation has finished (ACK active)
assign edc_wb_err = main_mem_ack & ( main_mem_err | ( ~edc_wb_we & (| uncorrected_error)));

endmodule