module cache_myreg #(
    parameter width = 1
)(
    input clk,rstn,
    input [width-1 : 0]in,
    output reg [width-1 : 0]out,
    input we,
    input clear
);
always @(posedge clk) begin
    if(!rstn)out <= {(width){1'b0}};
    else if(we)out <= in;
    else if(clear)out <= {(width){1'b0}};
    else out <= 0;
end
endmodule