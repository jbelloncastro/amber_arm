//////////////////////////////////////////////////////////////////
//                                                              //
//  Error Detector and Corrector module.                        //
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


module edc_mod#(

parameter WB_DWIDTH  = 32,
parameter WB_SWIDTH  = 4

)(

input                          edc_clk,
input                          edc_mem_ctrl,  // 0=128MB, 1=32MB

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

wire main_mem_err;
wire main_mem_ack;

wire [WB_DWIDTH-1:0] umain_read_data;

// ======================================
// Instantiate Main Memory
// ======================================

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
  .o_wb_dat               ( umain_read_data             ), // To Corrector
  .i_wb_dat               ( edc_wb_dat_w                ), // From Wishbone
  .i_wb_cyc               ( edc_wb_cyc                  ),
  .i_wb_stb               ( edc_wb_stb                  ),
  .o_wb_ack               ( main_mem_ack                ),
  .o_wb_err               ( main_mem_err                )
);


// ======================================
// Instantiate EDC Generator
// ======================================
reg [31:0] generator_data_in[0:3];
wire [7:0] syndrome_ecc[0:3];


always@(edc_wb_we or edc_wb_dat_w or umain_read_data) 
begin
  case(edc_wb_we)
      'b1: begin
          generator_data_in[0] = edc_wb_dat_w[31:0];// From Wishbone
          generator_data_in[1] = edc_wb_dat_w[63:32];// From Wishbone
          generator_data_in[2] = edc_wb_dat_w[95:64];// From Wishbone
          generator_data_in[3] = edc_wb_dat_w[127:96];// From Wishbone
    end
      default: begin
          generator_data_in[0] = umain_read_data[31:0];// From Main Memory
          generator_data_in[1] = umain_read_data[63:32];// From Main Memory
          generator_data_in[2] = umain_read_data[95:64];// From Main Memory
          generator_data_in[3] = umain_read_data[127:96];// From Main Memory
    end
  endcase
end


wire [31:0] ecc_mem_data;

edcg_mod generator0 (
  .S                      ( syndrome_ecc[0]         ),  // To Corrector and ECC Memory
  .WE                     ( edc_wb_we               ),  
  .IC                     ( ecc_mem_data[7:0]       ),  // From ECC Memory
  .ID                     ( generator_data_in[0]    )   // From multiplexor
);

edcg_mod generator1 (
  .S                      ( syndrome_ecc[1]         ),  // To Corrector and ECC Memory
  .WE                     ( edc_wb_we               ),  
  .IC                     ( ecc_mem_data[15:8]      ),  // From ECC Memory
  .ID                     ( generator_data_in[1]    )   // From multiplexor
);

edcg_mod generator2 (
  .S                      ( syndrome_ecc[2]          ),  // To Corrector and ECC Memory
  .WE                     ( edc_wb_we                ),  
  .IC                     ( ecc_mem_data[23:16]      ),  // From ECC Memory
  .ID                     ( generator_data_in[2]     )   // From multiplexor
);

edcg_mod generator3 (
  .S                      ( syndrome_ecc[3]          ),  // To Corrector and ECC Memory
  .WE                     ( edc_wb_we                ),  
  .IC                     ( ecc_mem_data[31:24]      ),  // From ECC Memory
  .ID                     ( generator_data_in[3]     )   // From multiplexor
);

// ======================================
// Instantiate ECC Memory
// ======================================
wire [31:0] ecc_mem_code_in;

assign ecc_mem_code_in[7:0] = syndrome_ecc[0];
assign ecc_mem_code_in[15:8] = syndrome_ecc[1];
assign ecc_mem_code_in[23:16] = syndrome_ecc[2];
assign ecc_mem_code_in[31:24] = syndrome_ecc[3];

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

// ======================================
// Instantiate EDC Corrector
// ======================================
wire [3:0]uncorrected_error;

assign edc_wb_ack = main_mem_ack;
assign edc_wb_err = main_mem_ack & ( main_mem_err | (| uncorrected_error));

edcc_mod corrector0 (
  .OD                      ( edc_wb_dat_r[31:0]       ),  // To Wishbone
  .UE                      ( uncorrected_error[0]     ), 
  .ED                      (                          ),  // Discarded
  .S                       ( syndrome_ecc[0]          ),  // From Generator
  .ID                      ( umain_read_data[31:0]    )   // From Main Memory
); 

edcc_mod corrector1 (
  .OD                      ( edc_wb_dat_r[63:32]      ),  // To Wishbone
  .UE                      ( uncorrected_error[1]     ),  // To Wishbone
  .ED                      (                          ),  // Discarded
  .S                       ( syndrome_ecc[1]          ),  // From Generator
  .ID                      ( umain_read_data[63:32]   )   // From Main Memory
); 

edcc_mod corrector2 (
  .OD                      ( edc_wb_dat_r[95:64]      ),  // To Wishbone
  .UE                      ( uncorrected_error[2]     ),  // To Wishbone
  .ED                      (                          ),  // Discarded
  .S                       ( syndrome_ecc[2]          ),  // From Generator
  .ID                      ( umain_read_data[95:64]   )   // From Main Memory
); 

edcc_mod corrector3 (
  .OD                      ( edc_wb_dat_r[127:96]      ),  // To Wishbone
  .UE                      ( uncorrected_error[3]      ),  // To Wishbone
  .ED                      (                           ),  // Discarded
  .S                       ( syndrome_ecc[3]           ),  // From Generator
  .ID                      ( umain_read_data[127:96]   )   // From Main Memory
); 

endmodule