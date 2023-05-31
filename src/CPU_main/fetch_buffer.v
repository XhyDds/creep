module fetch_buffer (
    input clk,rstn,
    input if0,if1,
    input [63:0]irin,
    input flag,
    output [31:0]buffer0,buffer1
);
    //是否需要改用循环队列？head+tail。for循环赋值对性能影响大吗？
    reg [31:0]buffer[0:31];
    reg [127:0]ir_reg;
    reg [4:0]pointer;
    wire new;
    wire [31:0]ir[0:3];
    assign buffer1=buffer[0];
    assign buffer0=buffer[1];
    assign ir[0]=irin[31:0];
    assign ir[1]=irin[63:32];
    // assign ir[2]=irin[95:64];
    // assign ir[3]=irin[127:96];
    assign new=(ir_reg!=irin);//是否传入的数据不变就不进入队列？
    always @(posedge clk,negedge rstn) begin
        if(!rstn) ir_reg<=0;
        else ir_reg<=irin;
    end
    always @(posedge clk,negedge rstn) begin:fetch_buffer
        integer i;
        if(!rstn) begin
            for (i=0;i<32;i=i+1)begin
                    buffer[i]<=0;
            end
            pointer<=0;
        end
        case ({if0,if1,new})//if1是优先级高的通道，即pc小的一侧
        //是否会出现if0&!if1的情况？
            000: ;
            001: begin 
                pointer<=pointer+4;
                for (i=0;i<4;i=i+1)begin
                    buffer[pointer+i]<=ir[i];
                end
            end
            010: begin 
                if(pointer>0) begin
                    pointer<=pointer-1;
                    for (i=0;i<pointer-1;i=i+1)begin
                        buffer[i]<=buffer[i+1];
                    end
                    buffer[pointer-1]<=0;
                end
            end
            011: begin 
                if(pointer>0) begin
                    pointer<=pointer+3;
                    for (i=0;i<pointer-1;i=i+1)begin
                        buffer[i]<=buffer[i+1];
                    end
                    for (i=0;i<4;i=i+1)begin
                        buffer[pointer-1+i]<=ir[i];
                    end
                end
                else begin
                    pointer<=pointer+4;
                    for (i=0;i<4;i=i+1)begin
                        buffer[pointer+i]<=ir[i];
                    end
                end
            end
            100: begin 
                if(pointer>1) begin
                    pointer<=pointer-1;
                    for (i=1;i<pointer-1;i=i+1)begin
                        buffer[i]<=buffer[i+1];
                    end
                    buffer[pointer-1]<=0;
                end
            end
            101: begin 
                if(pointer>1) begin
                    pointer<=pointer+3;
                    for (i=1;i<pointer-1;i=i+1)begin
                        buffer[i]<=buffer[i+1];
                    end
                    for (i=0;i<4;i=i+1)begin
                        buffer[pointer-1+i]<=ir[i];
                    end
                end
                else begin
                    pointer<=pointer+4;
                    for (i=0;i<4;i=i+1)begin
                        buffer[pointer+i]<=ir[i];
                    end
                end
            end
            110: begin 
                if(pointer>1) begin
                    pointer<=pointer-2;
                    for (i=0;i<pointer-2;i=i+1)begin
                        buffer[i]<=buffer[i+2];
                    end
                    buffer[pointer-1]<=0;
                    buffer[pointer-2]<=0;
                end
                else if(pointer==1) begin
                    pointer<=pointer-1;
                    for (i=0;i<pointer-1;i=i+1)begin
                        buffer[i]<=buffer[i+1];
                    end
                    buffer[pointer-1]<=0;
                end
            end
            111: begin 
                if(pointer>1) begin
                    pointer<=pointer+2;
                    for (i=0;i<pointer-2;i=i+1)begin
                        buffer[i]<=buffer[i+2];
                    end
                    // buffer[pointer-1]<=0;
                    buffer[pointer-2]<=0;
                    for (i=0;i<4;i=i+1)begin
                        buffer[pointer-1+i]<=ir[i];
                    end
                end
                else if(pointer==1) begin
                    pointer<=pointer+3;
                    for (i=0;i<pointer-1;i=i+1)begin
                        buffer[i]<=buffer[i+1];
                    end
                    for (i=0;i<4;i=i+1)begin
                        buffer[pointer-1+i]<=ir[i];
                    end
                end
                else begin
                    pointer=pointer+4;
                    for (i=0;i<4;i=i+1)begin
                        buffer[pointer+i]<=ir[i];
                    end
                end
            end
            default: ;
        endcase
    end

endmodule