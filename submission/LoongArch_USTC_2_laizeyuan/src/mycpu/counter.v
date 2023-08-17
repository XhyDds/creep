module counter (
    input      clk,
    input      rstn,
    input  [31:0] ctr0,
    input  [31:0] ctr1,
    output reg [31:0] countresult0,
    output reg [31:0] countresult1,
    output reg [63:0] countresult
);
    wire [3:0] type0    = ctr0[3:0];
    wire [4:0] subtype0 = ctr0[11:7];
    wire [3:0] type1    = ctr1[3:0];
    wire [4:0] subtype1 = ctr1[11:7];

    reg [63:0] count;
    always @(posedge clk )begin
        if(!rstn) begin
            count <= 0;
        end
        else begin
            count <= count + 1;
        end
    end

    always @(*) begin
        countresult0=0;
        countresult1=0; 
        countresult=count;
        if(type0==7)
            if(subtype0==0) countresult0=count[31:0];
            else if(subtype0==1) countresult0=count[63:32];
        if(type1==7)
            if(subtype1==0) countresult1=count[31:0];
            else if(subtype1==1) countresult1=count[63:32];
    end
    
endmodule //counter
