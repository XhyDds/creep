module counter (
    input      clk,
    input      rstn,
    
);
    reg [63:0] count;
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            count <= 0;
        end
        else begin
            count <= count + 1;
        end
    end
    
endmodule //counter
