module fetch_buffer_v2 (
    input [31:0]pc,npc,
    input clk,rstn,flush,stall,
    input if0,if1,icache_valid,
    input [1:0]plv,
    input [63:0]irin,
    input [73:0]pre,
    // input [63:0]
    input flag,
    input [15:0]excp_arg,
    //flag==1表示2个有效，flag==0表示1个有效
    //[0:31]为pc小，0-后一条指令（[63:32]）无效 1-有效
    output [31:0]ir0,ir1,pc0,pc1,
    output stall_fetch_buffer,valid0,valid1,
    output [1:0]plv0,plv1,
    output [73:0]pre0,pre1,
    output [15:0]excp_arg0,excp_arg1,
    output [31:0]npc0,npc1
);
    reg [31:0]buffer[0:15];//15为0，14最新，0最旧，是否会溢出？
    reg [31:0]bufferpc[0:15];
    reg [76:0]pre_and_valid_and_plv[0:15];
    reg [15:0]buffer_excp_arg[0:15];
    reg [31:0]buffer_npc[0:15];
    (* EQUIVALENT_REGISTER_REMOVAL="NO" ,MAX_FANOUT = 3 *) reg [3:0] pointer0;
    (* EQUIVALENT_REGISTER_REMOVAL="NO" ,MAX_FANOUT = 3 *) reg [3:0] pointer1;
    (* EQUIVALENT_REGISTER_REMOVAL="NO" ,MAX_FANOUT = 3 *) reg [3:0] pointer2;
    (* EQUIVALENT_REGISTER_REMOVAL="NO" ,MAX_FANOUT = 3 *) reg [3:0] pointer3;
    (* EQUIVALENT_REGISTER_REMOVAL="NO" ,MAX_FANOUT = 3 *) reg [3:0] pointer4;
    (* EQUIVALENT_REGISTER_REMOVAL="NO" ,MAX_FANOUT = 3 *) reg [3:0] pointer5;
    (* EQUIVALENT_REGISTER_REMOVAL="NO" ,MAX_FANOUT = 3 *) reg [3:0] pointer6;
    (* EQUIVALENT_REGISTER_REMOVAL="NO" ,MAX_FANOUT = 3 *) reg [3:0] pointer7;
    (* EQUIVALENT_REGISTER_REMOVAL="NO" ,MAX_FANOUT = 3 *) reg [3:0] npointer0;
    (* EQUIVALENT_REGISTER_REMOVAL="NO" ,MAX_FANOUT = 3 *) reg [3:0] npointer1;
    (* EQUIVALENT_REGISTER_REMOVAL="NO" ,MAX_FANOUT = 3 *) reg [3:0] npointer2;
    (* EQUIVALENT_REGISTER_REMOVAL="NO" ,MAX_FANOUT = 3 *) reg [3:0] npointer3;
    (* EQUIVALENT_REGISTER_REMOVAL="NO" ,MAX_FANOUT = 3 *) reg [3:0] npointer4;
    (* EQUIVALENT_REGISTER_REMOVAL="NO" ,MAX_FANOUT = 3 *) reg [3:0] npointer5;
    (* EQUIVALENT_REGISTER_REMOVAL="NO" ,MAX_FANOUT = 3 *) reg [3:0] npointer6;
    (* EQUIVALENT_REGISTER_REMOVAL="NO" ,MAX_FANOUT = 3 *) reg [3:0] npointer7;
    wire [31:0]ir[0:1];
    assign ir[0]=irin[31:0];
    assign ir[1]=irin[63:32];
    assign ir0=buffer[&pointer1?15:pointer1+1];
    assign ir1=buffer[pointer1];
    assign pc0=bufferpc[&pointer2?15:pointer2+1];
    assign pc1=bufferpc[pointer2];
    assign stall_fetch_buffer=(pointer0<=1);
    assign valid0=pre_and_valid_and_plv[&pointer3?15:pointer3+1][2];
    assign valid1=pre_and_valid_and_plv[pointer3][2];
    assign plv0=pre_and_valid_and_plv[&pointer4?15:pointer4+1][1:0];
    assign plv1=pre_and_valid_and_plv[pointer4][1:0];
    assign pre0=pre_and_valid_and_plv[&pointer5?15:pointer5+1][76:3];
    assign pre1=pre_and_valid_and_plv[pointer5][76:3];
    assign excp_arg0=buffer_excp_arg[&pointer6?15:pointer6+1];
    assign excp_arg1=buffer_excp_arg[pointer6];
    assign npc0=buffer_npc[&pointer7?15:pointer7+1];
    assign npc1=buffer_npc[pointer7];
    wire [3:0]flag4p=(icache_valid&~stall_fetch_buffer)?(flag?4'b0010:4'b0001):4'b0000;
    wire [3:0]flag4=(icache_valid&~stall_fetch_buffer)?(flag?4'b0001:4'b0000):4'b1111;
    wire [3:0]flag4m=(icache_valid&~stall_fetch_buffer)?(flag?4'b0000:4'b1111):4'b1110;
    
    always @(posedge clk)begin:fetch_buffer
        integer i;
        if(!rstn|flush) 
            begin
                for (i=0;i<16;i=i+1) begin
                        buffer[i]<=0;
                        bufferpc[i]<=0;
                        pre_and_valid_and_plv[i]<=0;
                        buffer_excp_arg[i]<=0;
                        buffer_npc[i]<=0;
                end
            end
        else if(!(stall_fetch_buffer|stall))
            begin
                if(icache_valid)
                    if (flag) 
                        begin
                            buffer[0]<=buffer[2];
                            bufferpc[0]<=bufferpc[2];
                            pre_and_valid_and_plv[0]<=pre_and_valid_and_plv[2];
                            buffer_excp_arg[0]<=buffer_excp_arg[2];
                            buffer_npc[0]<=buffer_npc[2];
                            buffer[1]<=buffer[3];
                            bufferpc[1]<=bufferpc[3];
                            pre_and_valid_and_plv[1]<=pre_and_valid_and_plv[3];
                            buffer_excp_arg[1]<=buffer_excp_arg[3];
                            buffer_npc[1]<=buffer_npc[3];
                            buffer[2]<=buffer[4];
                            bufferpc[2]<=bufferpc[4];
                            pre_and_valid_and_plv[2]<=pre_and_valid_and_plv[4];
                            buffer_excp_arg[2]<=buffer_excp_arg[4];
                            buffer_npc[2]<=buffer_npc[4];
                            buffer[3]<=buffer[5];
                            bufferpc[3]<=bufferpc[5];
                            pre_and_valid_and_plv[3]<=pre_and_valid_and_plv[5];
                            buffer_excp_arg[3]<=buffer_excp_arg[5];
                            buffer_npc[3]<=buffer_npc[5];
                            buffer[4]<=buffer[6];
                            bufferpc[4]<=bufferpc[6];
                            pre_and_valid_and_plv[4]<=pre_and_valid_and_plv[6];
                            buffer_excp_arg[4]<=buffer_excp_arg[6];
                            buffer_npc[4]<=buffer_npc[6];
                            buffer[5]<=buffer[7];
                            bufferpc[5]<=bufferpc[7];
                            pre_and_valid_and_plv[5]<=pre_and_valid_and_plv[7];
                            buffer_excp_arg[5]<=buffer_excp_arg[7];
                            buffer_npc[5]<=buffer_npc[7];
                            buffer[6]<=buffer[8];
                            bufferpc[6]<=bufferpc[8];
                            pre_and_valid_and_plv[6]<=pre_and_valid_and_plv[8];
                            buffer_excp_arg[6]<=buffer_excp_arg[8];
                            buffer_npc[6]<=buffer_npc[8];
                            buffer[7]<=buffer[9];
                            bufferpc[7]<=bufferpc[9];
                            pre_and_valid_and_plv[7]<=pre_and_valid_and_plv[9];
                            buffer_excp_arg[7]<=buffer_excp_arg[9];
                            buffer_npc[7]<=buffer_npc[9];
                            buffer[8]<=buffer[10];
                            bufferpc[8]<=bufferpc[10];
                            pre_and_valid_and_plv[8]<=pre_and_valid_and_plv[10];
                            buffer_excp_arg[8]<=buffer_excp_arg[10];
                            buffer_npc[8]<=buffer_npc[10];
                            buffer[9]<=buffer[11];
                            bufferpc[9]<=bufferpc[11];
                            pre_and_valid_and_plv[9]<=pre_and_valid_and_plv[11];
                            buffer_excp_arg[9]<=buffer_excp_arg[11];
                            buffer_npc[9]<=buffer_npc[11];
                            buffer[10]<=buffer[12];
                            bufferpc[10]<=bufferpc[12];
                            pre_and_valid_and_plv[10]<=pre_and_valid_and_plv[12];
                            buffer_excp_arg[10]<=buffer_excp_arg[12];
                            buffer_npc[10]<=buffer_npc[12];
                            buffer[11]<=buffer[13];
                            bufferpc[11]<=bufferpc[13];
                            pre_and_valid_and_plv[11]<=pre_and_valid_and_plv[13];
                            buffer_excp_arg[11]<=buffer_excp_arg[13];
                            buffer_npc[11]<=buffer_npc[13];
                            buffer[12]<=buffer[14];
                            bufferpc[12]<=bufferpc[14];
                            pre_and_valid_and_plv[12]<=pre_and_valid_and_plv[14];
                            buffer_excp_arg[12]<=buffer_excp_arg[14];
                            buffer_npc[12]<=buffer_npc[14];
                            buffer[13]<=ir[0];
                            bufferpc[13]<=pc;
                            pre_and_valid_and_plv[13]<={pre[73:40],1'b1,1'b1,pre[37:0],1'b1,plv};
                            buffer_excp_arg[13]<=excp_arg;
                            buffer_npc[13]<=npc;
                            buffer[14]<=ir[1];
                            bufferpc[14]<=pc+4;
                            pre_and_valid_and_plv[14]<={pre[73:40],1'b1,pre[38:0],1'b1,plv};
                            buffer_excp_arg[14]<=0;
                            buffer_npc[14]<=npc;
                        end
                    else 
                        begin
                            buffer[0]<=buffer[1];
                            bufferpc[0]<=bufferpc[1];
                            pre_and_valid_and_plv[0]<=pre_and_valid_and_plv[1];
                            buffer_excp_arg[0]<=buffer_excp_arg[1];
                            buffer_npc[0]<=buffer_npc[1];
                            buffer[1]<=buffer[2];
                            bufferpc[1]<=bufferpc[2];
                            pre_and_valid_and_plv[1]<=pre_and_valid_and_plv[2];
                            buffer_excp_arg[1]<=buffer_excp_arg[2];
                            buffer_npc[1]<=buffer_npc[2];
                            buffer[2]<=buffer[3];
                            bufferpc[2]<=bufferpc[3];
                            pre_and_valid_and_plv[2]<=pre_and_valid_and_plv[3];
                            buffer_excp_arg[2]<=buffer_excp_arg[3];
                            buffer_npc[2]<=buffer_npc[3];
                            buffer[3]<=buffer[4];
                            bufferpc[3]<=bufferpc[4];
                            pre_and_valid_and_plv[3]<=pre_and_valid_and_plv[4];
                            buffer_excp_arg[3]<=buffer_excp_arg[4];
                            buffer_npc[3]<=buffer_npc[4];
                            buffer[4]<=buffer[5];
                            bufferpc[4]<=bufferpc[5];
                            pre_and_valid_and_plv[4]<=pre_and_valid_and_plv[5];
                            buffer_excp_arg[4]<=buffer_excp_arg[5];
                            buffer_npc[4]<=buffer_npc[5];
                            buffer[5]<=buffer[6];
                            bufferpc[5]<=bufferpc[6];
                            pre_and_valid_and_plv[5]<=pre_and_valid_and_plv[6];
                            buffer_excp_arg[5]<=buffer_excp_arg[6];
                            buffer_npc[5]<=buffer_npc[6];
                            buffer[6]<=buffer[7];
                            bufferpc[6]<=bufferpc[7];
                            pre_and_valid_and_plv[6]<=pre_and_valid_and_plv[7];
                            buffer_excp_arg[6]<=buffer_excp_arg[7];
                            buffer_npc[6]<=buffer_npc[7];
                            buffer[7]<=buffer[8];
                            bufferpc[7]<=bufferpc[8];
                            pre_and_valid_and_plv[7]<=pre_and_valid_and_plv[8];
                            buffer_excp_arg[7]<=buffer_excp_arg[8];
                            buffer_npc[7]<=buffer_npc[8];
                            buffer[8]<=buffer[9];
                            bufferpc[8]<=bufferpc[9];
                            pre_and_valid_and_plv[8]<=pre_and_valid_and_plv[9];
                            buffer_excp_arg[8]<=buffer_excp_arg[9];
                            buffer_npc[8]<=buffer_npc[9];
                            buffer[9]<=buffer[10];
                            bufferpc[9]<=bufferpc[10];
                            pre_and_valid_and_plv[9]<=pre_and_valid_and_plv[10];
                            buffer_excp_arg[9]<=buffer_excp_arg[10];
                            buffer_npc[9]<=buffer_npc[10];
                            buffer[10]<=buffer[11];
                            bufferpc[10]<=bufferpc[11];
                            pre_and_valid_and_plv[10]<=pre_and_valid_and_plv[11];
                            buffer_excp_arg[10]<=buffer_excp_arg[11];
                            buffer_npc[10]<=buffer_npc[11];
                            buffer[11]<=buffer[12];
                            bufferpc[11]<=bufferpc[12];
                            pre_and_valid_and_plv[11]<=pre_and_valid_and_plv[12];
                            buffer_excp_arg[11]<=buffer_excp_arg[12];
                            buffer_npc[11]<=buffer_npc[12];
                            buffer[12]<=buffer[13];
                            bufferpc[12]<=bufferpc[13];
                            pre_and_valid_and_plv[12]<=pre_and_valid_and_plv[13];
                            buffer_excp_arg[12]<=buffer_excp_arg[13];
                            buffer_npc[12]<=buffer_npc[13];
                            buffer[13]<=buffer[14];
                            bufferpc[13]<=bufferpc[14];
                            pre_and_valid_and_plv[13]<=pre_and_valid_and_plv[14];
                            buffer_excp_arg[13]<=buffer_excp_arg[14];
                            buffer_npc[13]<=buffer_npc[14];
                            buffer[14]<=ir[0];
                            bufferpc[14]<=pc;
                            pre_and_valid_and_plv[14]<={pre[73:40],1'b0,pre[38:0],1'b1,plv};
                            buffer_excp_arg[14]<=excp_arg;
                            buffer_npc[14]<=npc;
                        end
            end
    end
    always @(posedge clk) begin
        if(!rstn|flush) begin 
            pointer0<=15;
            pointer1<=15;
            pointer2<=15;
            pointer3<=15;
            pointer4<=15;
            pointer5<=15;
            pointer6<=15;
            pointer7<=15;
        end
        else if(!stall) begin 
            pointer0<=npointer0;
            pointer1<=npointer1;
            pointer2<=npointer2;
            pointer3<=npointer3;
            pointer4<=npointer4;
            pointer5<=npointer5;
            pointer6<=npointer6;
            pointer7<=npointer7;
        end
    end
    always @(*) begin
        if(if1&if0) begin
            npointer0=(&pointer0[3:1])?(15-flag4p):(pointer0-flag4m);//取两个
            npointer1=(&pointer1[3:1])?(15-flag4p):(pointer1-flag4m);//取两个
            npointer2=(&pointer2[3:1])?(15-flag4p):(pointer2-flag4m);//取两个
            npointer3=(&pointer3[3:1])?(15-flag4p):(pointer3-flag4m);//取两个
            npointer4=(&pointer4[3:1])?(15-flag4p):(pointer4-flag4m);//取两个
            npointer5=(&pointer5[3:1])?(15-flag4p):(pointer5-flag4m);//取两个
            npointer6=(&pointer6[3:1])?(15-flag4p):(pointer6-flag4m);//取两个
            npointer7=(&pointer7[3:1])?(15-flag4p):(pointer7-flag4m);//取两个
        end
        else if(if1|if0) begin
            npointer0=(&pointer0)?(15-flag4p):(pointer0-flag4);//取一个
            npointer1=(&pointer1)?(15-flag4p):(pointer1-flag4);//取一个
            npointer2=(&pointer2)?(15-flag4p):(pointer2-flag4);//取一个
            npointer3=(&pointer3)?(15-flag4p):(pointer3-flag4);//取一个
            npointer4=(&pointer4)?(15-flag4p):(pointer4-flag4);//取一个
            npointer5=(&pointer5)?(15-flag4p):(pointer5-flag4);//取一个
            npointer6=(&pointer6)?(15-flag4p):(pointer6-flag4);//取一个
            npointer7=(&pointer7)?(15-flag4p):(pointer7-flag4);//取一个
        end
        else begin
            npointer0=pointer0-flag4p;
            npointer1=pointer1-flag4p;
            npointer2=pointer2-flag4p;
            npointer3=pointer3-flag4p;
            npointer4=pointer4-flag4p;
            npointer5=pointer5-flag4p;
            npointer6=pointer6-flag4p;
            npointer7=pointer7-flag4p;
        end
        //有下面走，上面不走的情况吗？
    end
endmodule