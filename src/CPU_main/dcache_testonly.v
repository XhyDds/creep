module dcache (
    input      clk,rstn,
    input      [31:0]addr,
    output reg [31:0]data_reg
);
    reg [31:0]data;
    always @(posedge clk,negedge rstn) begin
        if(!rstn) data_reg<=0;
        else data_reg<=data;
    end
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            data <= 0;
        end
        else begin
            data<=addr+'b1000_0000_0000_0000_0000_0000_0000_0000;
        end
    end
endmodule //dcache
