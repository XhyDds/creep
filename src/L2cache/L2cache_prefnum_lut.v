module L2cache_prefnum_lut #(
    parameter DATA_WIDTH = 32,
            //   INIT_FILE = "C:\Users\lenovo\Desktop\data_init.coe"
              ADDR_WIDTH = 8
            //   INIT_FILE = "C:\Users\lenovo\Desktop\data_init.coe"
)
(
    input clk,rstn,                    // Clock
    input [ADDR_WIDTH-1:0] raddr,  // Read Address
    input [ADDR_WIDTH-1:0] waddr,
    input [DATA_WIDTH-1:0] din,   // Data Input
    input we,                     // Write Enable
    output [DATA_WIDTH-1:0] dout,
    input clear
); 
    reg [DATA_WIDTH-1:0] dout_r;
    reg [DATA_WIDTH-1:0] ram [0:(1 << ADDR_WIDTH)-1];

    integer i;
    initial begin
        for (i = 0; i < (1 << ADDR_WIDTH); i = i + 1) begin
            ram[i] = 0;
        end
    end

    assign dout = dout_r;

    always @(posedge clk) begin
        if(!rstn)dout_r <= 0;
        else dout_r <= (waddr == raddr && we) ? din : ram[raddr];
        if (we) ram[waddr] <= din;
        else if(clear) ram[waddr] <= {DATA_WIDTH{1'b0}};
    end

endmodule