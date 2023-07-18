//双端口dram
module dp_dram #(
    parameter ADDR_WIDTH = 8,
              DATA_WIDTH = 2
            //   INIT_FILE = "C:\Users\lenovo\Desktop\data_init.coe"
)
(
    input clk,                    // Clock

    input [ADDR_WIDTH-1:0] araddr,  // Read Address
    output [DATA_WIDTH-1:0] adout,    

    input [ADDR_WIDTH-1:0] braddr,  // Read Address
    output [DATA_WIDTH-1:0] bdout,

    input [ADDR_WIDTH-1:0] waddr,
    input [DATA_WIDTH-1:0] din,   // Data Input
    input we                      // Write Enable
); 
    reg [DATA_WIDTH-1:0] ram [0:(1 << ADDR_WIDTH)-1];

    integer i;
    initial begin
        for (i = 0; i < (1 << ADDR_WIDTH); i = i + 1) begin
            ram[i] = 0;
        end
    end

    // assign dout = (addr_r==waddr&&we)?din:ram[addr_r];//write first
    assign adout = ram[araddr];
    assign bdout = ram[braddr];

    always @(posedge clk) begin
        if (we) ram[waddr] <= din;
    end

endmodule
