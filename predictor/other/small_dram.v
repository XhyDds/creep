module small_dram#(
    parameter ADDR_WIDTH = 10,
              DATA_WIDTH = 32
    //两位宽
)(  input                   clk,   // Clock
    input [ADDR_WIDTH-1:0]  raddr, // read Address
    input [ADDR_WIDTH-1:0]  waddr, // write Address
    input [DATA_WIDTH-1:0]  din,   // Data Input
    input [DATA_WIDTH/2-1:0]we,    // Write Enable
    output [DATA_WIDTH-1:0] dout   // Data Output
); 
    reg [DATA_WIDTH-1:0] dout_r;  
    reg [DATA_WIDTH-1:0] ram [0:(1 << ADDR_WIDTH)-1];

    // initial $readmemh(INIT_FILE, ram); // initialize memory
    integer j;
    initial begin
        for (j = 0; j < (1 << ADDR_WIDTH); j = j + 1) begin
            ram[j] = 0;
        end
    end

    // always @(posedge clk) begin
    //     dout_r <= ram[raddr];
    // end
    assign dout = dout_r;
    generate
        genvar i;
        for(i = 0; i < DATA_WIDTH/2; i = i+1) begin
            always @(posedge clk) begin
                if(we[i]) ram[waddr][(i+1)*2-1:(i*2)] <= din[(i+1)*2-1:(i*2)];
            end
            always @(*) begin
                dout_r[(i+1)*2-1:(i*2)] = ram[raddr][(i+1)*2-1:(i*2)];
            end
        end
    endgenerate
endmodule