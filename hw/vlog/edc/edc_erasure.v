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
  output reg [7:0]       o_mem_ecc, // maybe unused
  output reg             o_err,     //(to bus)
  output reg             o_ack      //(to bus)
);

parameter SIZE             = 3;
parameter IDLE             = 3'd0;
parameter WRITE            = 3'd1;
parameter READ             = 3'd2;
parameter WRITE_COMPLEMENT = 3'd3;
parameter READ_COMPLEMENT  = 3'd4;
parameter WRITE_CORRECTED  = 3'd5;
//--------- Internal variables ---------
reg [SIZE-1:0] current_state;
wire [SIZE-1:0] next_state;
//---------  Code starts here  ---------
assign next_state = fsm_function(current_state, i_sel, i_we, i_mem_ack, i_err, i_ue);
//--------- State combinational logic ---------
function [SIZE-1:0] fsm_function;
  input [SIZE-1:0] state;
  input i_start;
  input i_we;
  input i_ack;
  input i_err;
  input i_ue;

  case(state)
    IDLE: if (i_start == 1'b1) begin
        if (i_we == 1'b1) begin
            fsm_function = WRITE;
          end else begin
            fsm_function = READ;
          end
      end else begin
        fsm_function = IDLE;    
      end

    WRITE: if (i_ack == 1'b1) begin
        fsm_function = IDLE;// go back to idle when finished
      end else begin // still waiting for memory...
        fsm_function = WRITE;
      end

    READ: if (i_ack == 1'b1) begin
        if (i_ue == 1'b0) begin// meanwhile no errors... go back to idle
          fsm_function = IDLE;
        end else begin
          fsm_function = WRITE_COMPLEMENT;
        end
      end else begin // still waiting...
        fsm_function = READ;
      end

    WRITE_COMPLEMENT: if (i_ack == 1'b1) begin
        fsm_function = READ_COMPLEMENT;
      end else begin // still waiting...
        fsm_function = WRITE_COMPLEMENT;
      end

    READ_COMPLEMENT: if (i_ack == 1'b1) begin
        if (i_ue == 1'b1) begin
          fsm_function = IDLE;
        end else begin
          fsm_function = WRITE_CORRECTED;
        end
      end else begin // still waiting...
        fsm_function = READ_COMPLEMENT;
      end

    WRITE_CORRECTED: if (i_ack == 1'b1) begin
        fsm_function = IDLE;
      end else begin // still waiting...
        fsm_function = WRITE_CORRECTED;
      end

    default:
        fsm_function = IDLE;
  endcase
endfunction

//--------- Sequential logic ---------
always @ (posedge i_clk)
begin : FSM_SEQ
  if(i_rst == 1'b1) begin
    state <= IDLE;
  end else begin
    state <= next_state;
  end
end

//--------- Output logic ---------

// o_bus_data,//(to bus) 
// o_mem_data,//(to data mem)
// o_mem_ecc, // maybe unused
// o_err,     //(to bus)
// o_ack      //(to bus)

assign o_ack = (current_state == IDLE) & i_sel;
always @ (posedge clock)
  begin : OUTPUT_LOGIC
  if (i_rst == 1'b1) begin
    o_bus_data = 'b0;
    o_mem_data = 'b0;
    o_mem_ecc  = 'b0;
    o_err      = 'b0;
  end else begin
    case(current_state)
    default : begin
                     gnt_0 <=  #1  1'b0;
                     gnt_1 <=  #1  1'b0;
                   end
   endcase
 end
end // End Of Block OUTPUT_LOGIC