module alu (
    input [31:0]alu1,alu2,ctr,
    output reg [31:0]aluresult,
    output zero
);
    wire [3:0]type1=ctr[3:0];
    wire [3:0]aluop=ctr[21:18];
    always @(*) begin
        aluresult=0;
        if(type1==0|type1==8|type1==1)
        case (aluop)
            0:aluresult=alu1&alu2;
            1:aluresult=alu1|alu2;
            2:aluresult=~(alu1|alu2);
            3:aluresult=alu1^alu2;
            4:aluresult=alu1+alu2;
            5:aluresult=alu1-alu2;6:aluresult=alu1<<alu2;
            7:aluresult=alu1>>alu2;
            8:aluresult=alu1>>>alu2;
            9:aluresult=$signed(alu1)<$signed(alu2)?0:1;
            10:aluresult=alu1<alu2?0:1;
            11:aluresult=alu1;
            12:aluresult=alu2;
            13:aluresult=alu1+4;
        endcase
    end
    assign zero=(aluresult==0?1:0);
endmodule
