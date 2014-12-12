module encoder_test;
  
reg [31:0] my_data;
wire [7:0] my_ecc;
reg my_request;
wire my_done;

initial
begin
  my_data = 32'he3a02001;
  my_request = 1'b1;
end

edcg_mod generator (
  .S                      ( my_ecc      ),  // To Corrector and ECC Memory
  .R                      ( 1'b0       ),  
  .IC                     ( 8'b0  ),  // From ECC Memory
  .ID                     ( my_data )   // From multiplexor
);

//data to test: 0xe3a02001

endmodule