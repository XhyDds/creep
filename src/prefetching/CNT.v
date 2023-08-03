module CNT
    #(
        parameter WIDTH = 16,
        parameter RST_VLU = 0
    )(
    input                   clk,
    input                   rstn,   //异步复位使能
    input                   pe,     //同步置数使能
    input                   ce,     //计数使能
    input [WIDTH-1:0]       d,

    output reg [WIDTH-1:0]  q 
    );

    always @(posedge clk) begin
        if(!rstn)   q<=RST_VLU;
        else if(pe) q<=d;
        else if(ce) q<=q-1;
    end
endmodule
