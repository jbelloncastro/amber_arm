//////////////////////////////////////////////////////////////////
//                                                              //
//  Erasure computation and hard error correction controller.   //
//                                                              //
//  Description                                                 //
//  This module is able to correct one hard error in case two   //
//  errors were produced in the same word.                      //
//  With this module, the EDC  device will be able to correct   //
//  up to two failures meanwhile at least one of them is a hard //
//  error (i.e. it is not able to correct two soft errors).     //
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

module edc_erasure (
  input                  i_clk,
  input                  i_rst, // (from bus) reset signal
  input                  i_sel, // (from bus) select signal
  input                  i_we,  // (from bus) write enabled
  input                  i_err, // (from corrector) error detected
  input                  i_ue,  // (from corrector) uncorrected error signal
  input [31:0]           i_addr,// (from bus)
  input [31:0]           i_bus_data,// (from bus) 
  input [31:0]           i_mem_data,// (from data mem)
  input                  i_mem_ack, // ( AND(data mem ack, ecc mem ack) )
  output reg [31:0]      o_bus_data,//(to bus) 
  output reg [31:0]      o_mem_data,//(to data mem)
  output reg             o_mem_sel, //(to data mem)
  output reg             o_mem_we,  //(to data mem)
  output reg [7:0]       o_mem_ecc, // maybe unused
  output reg             o_err,     //(to bus)
  output reg             o_ack      //(to bus)
);

parameter SIZE                  = 4;
parameter IDLE                  = 4'd0;
parameter WRITE                 = 4'd1;
parameter READ                  = 4'd2;
parameter WRITE_COMPLEMENT      = 4'd3;
parameter WRITE_COMPLEMENT_DONE = 4'd4;// we need another step to bring o_mem_sel down and up again
parameter READ_COMPLEMENT       = 4'd5;
parameter READ_COMPLEMENT_DONE  = 4'd6;// we need another step to bring o_mem_sel down and up again
parameter WRITE_CORRECTED       = 4'd7;
parameter WRITE_DONE            = 4'd8;
parameter READ_DONE             = 4'd9;
parameter ERROR                 = 4'd10;

//--------- Internal variables ---------
reg [SIZE-1:0] current_state;
wire [SIZE-1:0] next_state;
//---------  Code starts here  ---------
assign next_state = fsm_function(current_state, i_sel, o_mem_sel, i_we, i_mem_ack, i_err, i_ue);
//--------- State combinational logic ---------
function [SIZE-1:0] fsm_function;
  input [SIZE-1:0] state;
  input i_start;
  input i_done;
  input i_we;
  input i_ack;
  input i_err;
  input i_ue;

  case(state)
    // 0
    IDLE: if (i_start == 1'b1) begin
        if (i_we == 1'b1) begin
            fsm_function = WRITE;
          end else begin
            fsm_function = READ;
          end
      end else begin
        fsm_function = IDLE;    
      end

    // 1
    WRITE: if (i_ack == 1'b1) begin
        fsm_function = WRITE_DONE;// go back to idle when finished
      end else begin // still waiting for memory...
        fsm_function = WRITE;
      end

    // 2
    READ: if (i_ack == 1'b1) begin
        if (i_ue == 1'b0) begin// meanwhile no errors... go back to idle
          fsm_function = READ_DONE;
        end else begin
          fsm_function = WRITE_COMPLEMENT;
        end
      end else begin // still waiting...
        fsm_function = READ;
      end

    // 3
    WRITE_COMPLEMENT: if (i_ack == 1'b1) begin
        fsm_function = WRITE_COMPLEMENT_DONE;
      end else begin // still waiting...
        fsm_function = WRITE_COMPLEMENT;
      end

    // 4
    WRITE_COMPLEMENT_DONE: if (i_done == 1'b0 ) begin
        fsm_function = READ_COMPLEMENT;
      end else begin
        fsm_function = WRITE_COMPLEMENT_DONE;
      end

    // 5
    READ_COMPLEMENT: if (i_ack == 1'b1) begin
        if (i_ue == 1'b1) begin
          fsm_function = ERROR;// uncorrectable error
        end else begin
          fsm_function = READ_COMPLEMENT_DONE;
        end
      end else begin // still waiting...
        fsm_function = READ_COMPLEMENT;
      end

    // 6
    READ_COMPLEMENT_DONE:  if (i_done == 1'b0 ) begin
        fsm_function = WRITE_CORRECTED;
      end else begin
        fsm_function = READ_COMPLEMENT_DONE;
      end

    // 7      
    WRITE_CORRECTED: if (i_ack == 1'b1) begin
        fsm_function = READ_DONE;
      end else begin // still waiting...
        fsm_function = WRITE_CORRECTED;
      end

    // 8
    WRITE_DONE:
      fsm_function = IDLE;

    // 9
    READ_DONE:
      fsm_function = IDLE;

    // 10
    ERROR:
        fsm_function = ERROR; // hangs until controller is reset

    default:
        fsm_function = IDLE;
  endcase
endfunction

//--------- Sequential logic ---------
always @ (posedge i_clk)
begin : FSM_SEQ
  if(i_rst == 1'b1) begin
    current_state <= IDLE;
  end else begin
    current_state <= next_state;
  end
end

//--------- Output logic ---------

//
//reg [31:0]      o_bus_data,//(to bus) 
//reg [31:0]      o_mem_data,//(to data mem)
//reg             o_mem_sel, //(to data mem)
//wire            o_mem_we,  //(to data mem)
//reg [7:0]       o_mem_ecc, // maybe unused
//reg             o_err,     //(to bus)
//reg             o_ack      //(to bus)

reg [31:0] word;

always @ (posedge i_clk)
begin : OUTPUT_LOGIC
  if (i_rst == 1'b1) begin
    o_bus_data <= 'b0;
    o_mem_data <= 'b0;
    o_mem_sel  <= 'b0;
    o_mem_we   <= 'b0;
    o_mem_ecc  <= 'b0;
    o_err      <= 'b0;
    o_ack      <= 'b0;
  end else begin
    case(current_state)
    IDLE: begin
        o_err  <= 'b0;
      end
    WRITE: begin      
        o_ack      <= 'b0;
        o_mem_sel  <= 1'b1;
        o_mem_we   <= 1'b1;
        o_mem_data <= i_bus_data;
      end
    READ: begin
        o_ack     <= 'b0;
        o_mem_sel <= 1'b1;
        o_mem_we  <= 1'b0;
        word      <= i_mem_data;// save data in a temp register
      end
    WRITE_COMPLEMENT: begin
        o_mem_sel  <= 1'b1;
        o_mem_we   <= 1'b1;
        o_mem_data <= ~word;// write the complement of the data in memory
        //o_mem_ecc = ~ecc;// our parity check matrix ECC doesnt change with complemented words
      end
    WRITE_COMPLEMENT_DONE: begin
        o_mem_sel = 1'b0;
      end
    READ_COMPLEMENT: begin
        o_mem_sel  <= 1'b1;
        o_mem_we   <= 1'b0;
        word       <= ~i_mem_data;// write the complement of the data in memory
        //ecc_compl <= ~i_mem_ecc;// our parity check matrix ECC doesnt change with complemented words
      end
    READ_COMPLEMENT_DONE: begin
        o_mem_sel = 1'b0;
      end
    WRITE_CORRECTED: begin
        o_mem_sel  <= 1'b1;
        o_mem_we   <= 1'b1;
        o_mem_data <= word;
      end
    WRITE_DONE: begin
        o_mem_sel = 1'b0;
      end
    READ_DONE: begin
        o_mem_sel  = 1'b0;
        o_bus_data <= word;
        o_ack      <= 1'b1;
      end
    endcase
  end
end // End Of Block OUTPUT_LOGIC

endmodule