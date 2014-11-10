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
wire ecc_mem_err;
wire corrector_err;

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
  .o_wb_dat               ( corrector.edcc_main_dat_w   ), // To Corrector input
  .i_wb_dat               ( edc_wb_dat_w                ), // From Wishbone
  .i_wb_cyc               ( edc_wb_cyc                  ),
  .i_wb_stb               ( edc_wb_stb                  ),
  .o_wb_ack               ( edc_wb_ack                  ),
  .o_wb_err               ( main_mem_err                )
);


// ======================================
// Instantiate EDC Generator
// ======================================

edcg_mod #(
  .WB_DWIDTH             ( WB_DWIDTH             ),
  .WB_SWIDTH             ( WB_SWIDTH             )
)
generator (
  .edcg_dat_r               ( ecc_mem.i_wb_dat        ), // To ECC Memory input
  .edcg_dat_w               ( edc_wb_dat_w            )  // From Wishbone
);


// ======================================
// Instantiate ECC Memory
// ======================================

main_mem #(
  .WB_DWIDTH             ( WB_DWIDTH             ),
  .WB_SWIDTH             ( WB_SWIDTH             )
)
ecc_mem (
  .i_clk                  ( edc_clk                   ),
  .i_mem_ctrl             ( edc_mem_ctrl              ),
  .i_wb_adr               ( edc_wb_adr                ),
  .i_wb_sel               ( edc_wb_sel                ),
  .i_wb_we                ( edc_wb_we                 ),
  .o_wb_dat               ( corrector.edcc_ecc_dat_w  ),  // To Corrector input
  .i_wb_dat               ( generator.edcg_dat_r      ),  // From Generator output
  .i_wb_cyc               ( edc_wb_cyc                ),
  .i_wb_stb               ( edc_wb_stb                ),
  .o_wb_ack               ( /*edc_wb_ack*/            ),
  .o_wb_err               ( ecc_mem_err                )
);


// ======================================
// Instantiate EDC Corrector
// ======================================

edcc_mod #(
  .WB_DWIDTH             ( WB_DWIDTH             ),
  .WB_SWIDTH             ( WB_SWIDTH             )
)
corrector (
  .edcc_dat_r               ( edc_wb_dat_r            ),  // To Wishbone
  .error                    ( corrector_err           ),
  .edcc_main_dat_w          ( u_main_mem.o_wb_dat     ),  // From Main Memory output
  .edcc_ecc_dat_w           ( ecc_mem.o_wb_dat        )   // From ECC Memory output
);
 
begin

assign edc_wb_err = corrector_err | ecc_mem_err | main_mem_err;

end

endmodule