module ip_bytewrite #(
  parameter NB_COL = 8,                       // Specify number of columns (number of bytes)
  parameter COL_WIDTH = 4,                  // Specify column width (byte 
  parameter RAM_DEPTH = 32,                  // Specify RAM depth (number of entries)
  parameter RAM_PERFORMANCE = "HIGH_PERFORMANCE", // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
  parameter INIT_FILE = ""    
)(
  input [clogb2(RAM_DEPTH-1)-1:0] addra, // Write address bus, wi
  input [clogb2(RAM_DEPTH-1)-1:0] addrb, // Read address bus, 
  input [(NB_COL*COL_WIDTH)-1:0] dina, // RAM input data
  input clka,                          // Clock
  input [NB_COL-1:0] wea,              // Byte-write enable
  input enb,                           // Read Enable, for ad
  output [(NB_COL*COL_WIDTH)-1:0] doutb         // RAM output data
);

  (*RAM_STYLE="block"*)reg [(NB_COL*COL_WIDTH)-1:0] ram [RAM_DEPTH-1:0];
  reg [(NB_COL*COL_WIDTH)-1:0] dout_reg = {(NB_COL*COL_WIDTH){1'b0}};

  // The following code either initializes the memory values to a specified file or to all zeros to match hardware
  generate
    if (INIT_FILE != "") begin: use_init_file
      initial
        $readmemh(INIT_FILE, ram, 0, RAM_DEPTH-1);
    end else begin: init_bram_to_zero
      integer ram_index;
      initial
        for (ram_index = 0; ram_index < RAM_DEPTH; ram_index = ram_index + 1)
          ram[ram_index] = {(NB_COL*COL_WIDTH){1'b0}};
    end
  endgenerate

  always @(posedge clka)
    if (enb)
      dout_reg <= ram[addrb];

  generate
  genvar i;
     for (i = 0; i < NB_COL; i = i+1) begin: byte_write
       always @(posedge clka)
         if (wea[i])
           ram[addra][(i+1)*COL_WIDTH-1:i*COL_WIDTH] <= dina[(i+1)*COL_WIDTH-1:i*COL_WIDTH];
      end
  endgenerate

       assign doutb = dout_reg;

  function integer clogb2;
    input integer depth;
      for (clogb2=0; depth>0; clogb2=clogb2+1)
        depth = depth >> 1;
  endfunction
						
						
endmodule