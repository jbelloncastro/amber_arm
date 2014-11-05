//////////////////////////////////////////////////////////////////
//                                                              //
//  Main memory with error detection and correction             //
//                                                              //
//                                                              //
//  Description                                                 //
//  ...                                                         //
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

module ecc_memory
#(
parameter WB_DWIDTH  = 32,
parameter WB_SWIDTH  = 4,
parameter ECC_WIDTH  = 32
)(
input                          i_clk,
input                          i_mem_ctrl,  // 0=128MB, 1=32MB
// Wishbone Bus
input       [31:0]             i_wb_adr,
input       [WB_SWIDTH-1:0]    i_wb_sel,
input                          i_wb_we,
output      [WB_DWIDTH-1:0]    o_wb_dat,
input       [WB_DWIDTH-1:0]    i_wb_dat,
input                          i_wb_cyc,
input                          i_wb_stb,
output                         o_wb_ack,
output                         o_wb_err
);

    // ======================================
    // Instantiate non-synthesizable main memory model
    // ======================================

    assign phy_init_done = 1'd1;

    main_mem #(
                .WB_DWIDTH             ( WB_DWIDTH             ),
                .WB_SWIDTH             ( WB_SWIDTH             )
                )
    u_main_mem (
               .i_clk                  ( sys_clk            ),
               .i_mem_ctrl             ( test_mem_ctrl      ),
               .i_wb_adr               ( i_wb_adr           ),
               .i_wb_sel               ( i_wb_sel           ),
               .i_wb_we                ( i_wb_we            ),
               .o_wb_dat               ( o_wb_dat           ),
               .i_wb_dat               ( i_wb_dat           ),
               .i_wb_cyc               ( i_wb_cyc           ),
               .i_wb_stb               ( i_wb_stb           ),
               .o_wb_ack               ( o_wb_ack           ),
               .o_wb_err               ( o_wb_err           )
            );
     // Important note: we may want to use o_wb_err to signal both
     // natural memory errors AND errors detected by our module


    // ======================================
    // Instantiate ECC generator
    // ======================================
    // Additional signals used to feed generated ECC to main memory or error detection module
    wire [WB_DWIDTH-1:0] ecc_data_source; // Contains the data used to generate ECC
                                          // This can either be 
                                          // - data read from main memory or
                                          // - data 

    wire [ECC_WIDTH-1:0] generated_ecc;

// Important signals:
// i_wb_we: Input wishbone bus - Write enabled
// i_wb_stb: The strobe input [STB_I], when asserted, indicates that the SLAVE is selected. A SLAVE shall
//           respond to other WISHBONE signals only when this [STB_I] is asserted (except for the [RST_I]
//           signal which should always be responded to
    
    ecc_encoder #(
                .ECC_WIDTH             ( WB_DWIDTH          )
                )
    encoder (    
                .i_clk                 ( sys_clk            ),
                .i_enable              ( i_wb_stb           ),
                .i_read_data           ( i_wb_dat           ),
                .o_ecc_code            ( generated_ecc      )
            );

    // ======================================
    // Instantiate non-synthesizable main memory model
    // This one will store all ECC tags
    // ======================================
    // Additional signals used for reading writing ecc memory
    wire [ECC_WIDTH-1:0] read_ecc;
    wire ecc_read_ack;
    wire ecc_read_err;
         
    main_mem #(
                .WB_DWIDTH             ( ECC_WIDTH             ),
                .WB_SWIDTH             ( WB_SWIDTH             )
                )
    ecc_mem (
               .i_clk                  ( sys_clk            ),
               .i_mem_ctrl             ( test_mem_ctrl      ),
               .i_wb_adr               ( i_wb_adr           ),
               .i_wb_sel               ( i_wb_sel           ),
               .i_wb_we                ( i_wb_we            ),
               .o_wb_dat               ( read_ecc           ),
               .i_wb_dat               ( generated_ecc      ),
               .i_wb_cyc               ( i_wb_cyc           ),
               .i_wb_stb               ( i_wb_stb           ),
               .o_wb_ack               ( ecc_read_ack       ),
               .o_wb_err               ( ecc_read_err       )
            );

endmodule