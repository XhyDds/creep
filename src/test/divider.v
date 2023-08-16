module divider #(parameter WIDTH=32)
(
    input clk,rstn,                         
    input [3:0] pipeline_divider_type,      
    input [4:0] pipeline_divider_subtype,   
    input pipeline_divider_stall1,          
    input pipeline_divider_flush1,          
    input pipeline_divider_stall2,          
    input pipeline_divider_flush2,          
    input [WIDTH-1:0] pipeline_divider_din1,
    input [WIDTH-1:0] pipeline_divider_din2,
    output divider_pipeline_stall,          
    output reg [WIDTH-1:0] divider_pipeline_dout
);
    wire [3:0]type=pipeline_divider_type;
    wire [4:0]subtype=pipeline_divider_subtype;
    wire [31:0] rj=pipeline_divider_din1;
    wire[31:0] rk=pipeline_divider_din2;
    reg [31:0] divresult;
    assign divider_pipeline_stall=0;
    always@(posedge(clk))
    begin
    if(!rstn)
        divider_pipeline_dout<=0;
    else
        divider_pipeline_dout<=divresult;
    end
    always @(*) begin
        divresult=0;
        if(type==2)
            case (subtype)
                0: divresult=$signed(rj)/$signed(rk);
                1: divresult=$signed(rj)%$signed(rk);
                2: divresult=$unsigned(rj)/$unsigned(rk);
                3: divresult=$unsigned(rj)&$unsigned(rk);
            endcase
    end
endmodule