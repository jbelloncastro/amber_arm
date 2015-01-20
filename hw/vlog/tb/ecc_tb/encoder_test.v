module encoder_test;

reg write_enable;  
reg [31:0] my_data;//data to test: 0xe3a02001
reg [7:0] my_ecc;// ecc for this data: 0xf7
reg [31:0] bitflip_mask;

wire [31:0] input_data;
wire [31:0] output_data;
wire [7:0] ecc_syndrome;
wire uncorrected;

initial
begin
  // Simulation test values.
  my_data = 32'he3a02001;
  my_ecc = 8'hf7;
  write_enable = 1'b0;
  bitflip_mask = 32'd75;
end

genvar i;
generate
  // Flip my_data bit values using bitflip_mask (only on read operations)
  for( i = 0; i < 32; i=i+1) begin
    assign input_data[i] = my_data[i] ^ (bitflip_mask[i] & ~write_enable);
  end
endgenerate

edc_generator generator (
  .o_ecc_syndrome         ( ecc_syndrome               ),  // To Corrector and ECC Memory
  .i_write_enabled        ( write_enable               ),  
  .i_ecc                  ( my_ecc                     ),  // From ECC Memory
  .i_data                 ( input_data                 )   // From multiplexor
);

edc_corrector corrector (
  .o_data                  ( output_data               ),
  .o_uncorrected_error     ( uncorrected               ),
  .o_error_detected        (                           ),
  .i_syndrome              ( generator.o_ecc_syndrome  ),  // From generator
  .i_data                  ( input_data                )   // From "main memory"
);

endmodule