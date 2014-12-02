module encoder_test;
  
reg [31:0] my_data;
wire [7:0] my_ecc;
reg my_request;
wire my_done;

initial
begin
  my_data = 32'd12345;
  my_request = 1'b1;
end

ecc_encoder my_enc(
      .i_request( my_request ),
      .i_data( my_data ),
      .o_done( my_done ),
      .o_ecc_code( my_ecc )
);

endmodule