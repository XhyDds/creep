module writefirst_reg #(
    parameter width = 1
)(
    input clk,
    input [width-1 : 0]in,
    output [width-1 : 0]out,
    input we,
    input clear
);
reg [width-1 : 0]out_r;
always @(clk) begin
    if(we)out_r <= in;
    else if(clear)out_r <= {(width){1'b0}};
end
assign out = we ? in : out_r;
endmodule