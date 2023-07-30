module cache_myreg #(
    parameter width = 1
)(
    input clk,
    input [width-1 : 0]in,
    output reg [width-1 : 0]out,
    input we,
    input clear
);
always @(clk) begin
    if(we)out <= in;
    else if(clear)out <= {(width){1'b0}};
end
endmodule