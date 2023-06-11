module dcache_testonly (
    input      clk,rstn,
    input      [31:0]addr,
    output reg [31:0]data_reg
);
    wire [31:0]data;
    always @(posedge clk,negedge rstn) begin
        if(!rstn) data_reg<=0;
        else data_reg<=data;
    end
    assign data = addr+'b0000_0000_0000_0000_0000_0000_1000_0000;
endmodule //dcache_testonly
