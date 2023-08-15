module IPCP_buff#(
    parameter Bufferlen=3
)(
    input clk,rstn,
    input [31:5] baseaddr,
    input [7:0] strideint,
    input [1:0] typein,
    input [6:0] IPsigin,
    
    output [6:0] CSPT_lookaddr,
    input [9:0] CSPT_datain

);
    localparam NL=0,CS=1,CPLX=2,GS=3;
    reg [Bufferlen-1:0] headp,tailp;reg [43:0] buffer[0:Bufferlen-1];
    wire [43:0] buff_din,buff_dout;
    assign buff_din={typein,IPsigin,strideint,baseaddr};
    assign buff_dout=buffer[tailp];
    //head
    always@(posedge(clk))
    begin
    if(!rstn)
        begin
        headp<=0;
        end
    else if(|typein)
        begin
        headp<=headp+1;
        end
    end
    //buffer
    always@(posedge(clk))
    begin
    if(|typein)
        buffer[headp]<=buff_din;
    end

endmodule