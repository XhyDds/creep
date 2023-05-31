module dispatcher (
    input [31:0]imm0,imm1,control0,control1,
    input [4:0]rk0,rk1,rj0,rj1,rd0,rd1,
    input [15:0]excp_arg0,excp_arg1,
    input INE0,INE1,
    output reg [4:0]rk00,rk11,rj00,rj11,rd00,rd11,
    output reg [31:0]imm00,imm11,control00,control11,
    output reg [15:0]excp_arg00,excp_arg11,
    output reg INE00,INE11,
    output reg if0,if1
);
    //上方alu div mul，下方全功能
    //可同时发射：不相关且有一条是算术指令
    //如果3000是alu，3004是dcache，是否可交换？
    wire xiangguan=(rd0==rd1|rd0==rk1|rd0==rj1|rd1==rk0|rd1==rj0);
    wire suanshu0=(control0[3:0]==0|control0[3:0]==2|control0[3:0]==4);
    wire suanshu1=(control1[3:0]==0|control1[3:0]==2|control1[3:0]==4);
    wire jiaohuan=(control0[3:0]==5)&suanshu1;//3000是alu，3004是dcache
    always @(*) begin
        if(!xiangguan&suanshu0)begin//不相关且第二条指令为算术指令
            rk00=rk0;
            rk11=rk1;
            rj00=rj0;
            rj11=rj1;
            rd00=rd0;
            rd11=rd1;
            imm00=imm0;
            imm11=imm1;
            control00=control0;
            control11=control1;
            excp_arg00=excp_arg0;
            excp_arg11=excp_arg1;
            INE00=INE0;
            INE11=INE1;
            if0=1;
            if1=1;
        end
        else if(!xiangguan&jiaohuan) begin//特殊情况：算数在前访存在后，交换后发射
            rk00=rk1;
            rk11=rk0;
            rj00=rj1;
            rj11=rj0;
            rd00=rd1;
            rd11=rd0;
            imm00=imm1;
            imm11=imm0;
            control00=control1;
            control11=control0;
            excp_arg00=excp_arg1;
            excp_arg11=excp_arg0;
            INE00=INE1;
            INE11=INE0;
            if0=1;
            if1=1;
        end
        else begin
            rk00=0;
            rk11=rk1;
            rj00=0;
            rj11=rj1;
            rd00=0;
            rd11=rd1;
            imm00=0;
            imm11=imm1;
            control00=0;
            control11=control1;
            excp_arg00=0;
            excp_arg11=excp_arg1;
            INE00=0;
            INE11=INE1;
            if0=0;
            if1=1;
        end
    end


endmodule