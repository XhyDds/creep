module dispatcher (
    input clk,rstn,
    input [31:0]imm0,imm1,control0,control1,pc0,pc1,
    input [4:0]rk0,rk1,rj0,rj1,rd0,rd1,
    input [15:0]excp_arg0,excp_arg1,
    // input INE0,INE1,
    output reg [4:0]rk00,rk11,rj00,rj11,rd00,rd11,
    output reg [31:0]imm00,imm11,control00,control11,pc00,pc11,
    output reg [15:0]excp_arg00,excp_arg11,
    // output reg INE00,INE11,
    output reg if0,if1
);
    //上方alu div mul，下方全功能
    //可同时发射：不相关且有一条是算术指令
    //如果3000是alu，3004是dcache，是否可交换？
    reg [4:0]rd0_reg,rd1_reg;
    reg muldecache0_reg,muldecache1_reg;
    wire [3:0]type0=control0[3:0];
    wire [3:0]type1=control1[3:0];
    //0:alu, 1:br, 2:div, 3:priv, 4:mul, 5:dcache, 6:priv+dcache, 7:RDCNT, 8:alu+br
    wire xiangguan=(/*rd0==rd1|*/rd0==rk1|rd0==rj1|rd1==rk0|rd1==rj0);
    wire suanshubr0=(type0==0|type0==1|type0==2|type0==4|type0==8);
    wire suanshu1=(type1==0|type1==2|type1==4);
    wire suanshubr1=(suanshu1|type1==1|type1==8);
    // wire jiaohuan=(type0==5)&suanshu1;//3000是alu，3004是dcache
    wire muldecache0=(type0==4|type0==5);
    wire muldecache1=(type1==4|type1==5);
    wire stall1=(muldecache0_reg&(rd0_reg==rk1|rd0_reg==rj1))|(muldecache1_reg&(rd1_reg==rk1|rd1_reg==rj1));
    wire stall0=(muldecache0_reg&(rd0_reg==rk0|rd0_reg==rj0))|(muldecache1_reg&(rd1_reg==rk0|rd1_reg==rj0));

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            muldecache0_reg <= 0;
            muldecache1_reg <= 0;
            rd0_reg <= 0;
            rd1_reg <= 0;
        end
        else begin
            muldecache0_reg <= if0 ? muldecache0:0;
            rd0_reg <= rd0; 
            muldecache1_reg <= if1 ? muldecache1:0;
            rd1_reg <= rd1; 
        end
    end

    always @(*) begin
        if (stall1) begin
            rk00=0;
            rk11=0;
            rj00=0;
            rj11=0;
            rd00=0;
            rd11=0;
            imm00=0;
            imm11=0;
            control00=0;
            control11=0;
            excp_arg00=0;
            excp_arg11=0;
            if0=0;
            if1=0;
            pc00=0;
            pc11=0;
        end
        else if(!xiangguan&suanshubr0&!stall0)begin//不相关且第二条指令为算术指令
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
            if0=1;
            if1=1;
            pc00=pc0;
            pc11=pc1;
        end
        // else if(!xiangguan&jiaohuan) begin//特殊情况：算数在前访存在后，交换后发射
        //     rk00=rk1;
        //     rk11=rk0;
        //     rj00=rj1;
        //     rj11=rj0;
        //     rd00=rd1;
        //     rd11=rd0;
        //     imm00=imm1;
        //     imm11=imm0;
        //     control00=control1;
        //     control11=control0;
        //     excp_arg00=excp_arg1;
        //     excp_arg11=excp_arg0;
        //     if0=1;
        //     if1=1;
        //     pc00=pc1;
        //     pc11=pc0;
        // end
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
            // INE00=0;
            // INE11=INE1;
            if0=0;
            if1=1;
            pc00=0;
            pc11=pc1;
        end
    end


endmodule