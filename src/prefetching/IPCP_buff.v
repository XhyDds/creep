module IPCP_buff#(
    parameter Bufferlen=3
)(
    input clk,rstn,
    input [31:5] baseaddr,
    input [7:0] strideint,
    input [1:0] typein,
    input [6:0] IPsigin,
    
    output [6:0] CSPT_lookaddr,
    input [9:0] CSPT_datain,

    input visithit,
    input [2:0] hitype
);
    localparam NL=0,CS=1,CPLX=2,GS=3;
    reg [Bufferlen-1:0] headp,tailp;reg [43:0] buffer[0:Bufferlen-1];
    wire [43:0] buff_din,buff_dout;
    assign buff_din={typein,IPsigin,strideint,baseaddr};
    assign buff_dout=buffer[tailp];
    
    reg [7:0] tcoun_CS,hcoun_CS,tcoun_CPLX,hcoun_CPLX,tcoun_GS,hcoun_GS;
    
    //hit_counter
    always@(posedge(clk))
    begin
    if(!rstn)
        begin
        tcoun_CS<=0;hcoun_CS<=0;
        tcoun_CPLX<=0;hcoun_CPLX<=0;
        tcoun_GS<=0;hcoun_GS<=0;
        end
    else
        begin
        if(visithit)
            begin
            case(hitype)
                CS:
                    hcoun_CS<=hcoun_CS+{7'b0,~(&hcoun_CS)};
                CPLX:
                    hcoun_CPLX<=hcoun_CPLX+{7'b0,~(&hcoun_CPLX)};
                GS:
                    hcoun_GS<=hcoun_GS+{7'b0,~(&hcoun_GS)};
                default
                    begin
                    end
            endcase
            end
        end
    end
    
    
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