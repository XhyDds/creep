//双端口dram
module dp_dram #(
    parameter ADDR_WIDTH = 8,
              DATA_WIDTH = 2,
              INIT_NUM   = 0
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
    sp_dram#(ADDR_WIDTH,DATA_WIDTH,INIT_NUM)
    sp_a(
        .clk    (clk),
        .raddr  (araddr),
        .dout   (adout),
        .waddr  (waddr),
        .din    (din),
        .we     (we)
    );

    sp_dram#(ADDR_WIDTH,DATA_WIDTH,INIT_NUM)
    sp_b(
        .clk    (clk),
        .raddr  (braddr),
        .dout   (bdout),
        .waddr  (waddr),
        .din    (din),
        .we     (we)
    );

    // reg [DATA_WIDTH-1:0] ram [0:(1 << ADDR_WIDTH)-1];

    // integer i;
    // initial begin
    //     for (i = 0; i < (1 << ADDR_WIDTH); i = i + 1) begin
    //         ram[i] = INIT_NUM;
    //     end
    // end

    // // assign dout = (addr_r==waddr&&we)?din:ram[addr_r];//write first
    // assign adout = ram[araddr];
    // assign bdout = ram[braddr];

    // always @(posedge clk) begin
    //     if (we) ram[waddr] <= din;
    // end

endmodule
