module ip_bram #(
    parameter RAM_WIDTH = 32,                  // Specify RAM data width
    parameter RAM_DEPTH = 3,                  // Specify RAM depth (number of entries)
    parameter RAM_PERFORMANCE = "LOW_LATENCY", // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    parameter INIT_FILE = ""                       // Specify name/location of RAM initializati
)(
    input [clogb2(RAM_DEPTH-1)-1:0] addra, // Write address bus, width determined from
    input [clogb2(RAM_DEPTH-1)-1:0] addrb, // Read address bus, width determined from
    input [RAM_WIDTH-1:0] dina,          // RAM input data
    input clka,                          // Clock
    input wea,                           // Write enable
    input enb,                           // Read Enable, for additional power
    output [RAM_WIDTH-1:0] doutb                  // RAM output data
);

  (*RAM_STYLE="block"*)reg [RAM_WIDTH-1:0] ram [RAM_DEPTH-1:0];
  reg [RAM_WIDTH-1:0] dout_reg = {RAM_WIDTH{1'b0}};

  // The following code either initializes the memory values to a specified file or to all zeros to match hardware
  generate
    if (INIT_FILE != "") begin: use_init_file
      initial
        $readmemh(INIT_FILE, ram, 0, RAM_DEPTH-1);
    end else begin: init_bram_to_zero
      integer ram_index;
      initial
        for (ram_index = 0; ram_index < RAM_DEPTH; ram_index = ram_index + 1)
          ram[ram_index] = {RAM_WIDTH{1'b0}};
    end
  endgenerate

  always @(posedge clka) begin
    if (wea)
      ram[addra] <= dina;
    if (enb)
      dout_reg <= ram[addrb];
  end

  assign doutb = dout_reg;

  function integer clogb2;
    input integer depth;
      for (clogb2=0; depth>0; clogb2=clogb2+1)
        depth = depth >> 1;
  endfunction
						
endmodule