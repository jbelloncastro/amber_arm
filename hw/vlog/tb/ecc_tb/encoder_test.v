module encoder_test;

reg write_enable;
  
reg [31:0] my_data;//data to test: 0xe3a02001
reg [7:0] my_ecc;// ecc for this data: 0x1d
reg [31:0] bitflip_mask;

wire [31:0] input_data;
wire [31:0] output_data;
wire [7:0] output_ecc;
wire uncorrected;

initial
begin
  my_data = 32'he0813002;
  my_ecc = 8'h1d;
  write_enable = 1'b0;
  bitflip_mask = 32'b1000;
end

genvar i;
generate
  for( i = 0; i < 32; i=i+1) begin
    assign input_data[i] = my_data[i] ^ (bitflip_mask[i] & ~write_enable);
  end
endgenerate

edc_generator generator (
  .o_ecc_syndrome         ( output_ecc      ),  // To Corrector and ECC Memory
  .i_write_enabled        ( write_enable       ),  
  .i_ecc                  ( my_ecc  ),  // From ECC Memory
  .i_data                 ( input_data )   // From multiplexor
);

edc_corrector corrector (
  .o_data                  ( output_data ),  // To Wishbone
  .o_uncorrected_error     ( uncorrected ),  // To Wishbone
  .o_error_detected        (             ),  // Discarded
  .i_syndrome              ( output_ecc  ),  // From Generator
  .i_data                  ( input_data  )   // From Main Memory
);

endmodule