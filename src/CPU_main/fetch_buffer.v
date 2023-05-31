module fetch_buffer (
    input [31:0]pc,
    input clk,rstn,
    input if0,if1,
    input [63:0]irin,
    input flag,//flag==1表示2个有效，==0表示1个有效
    output [31:0]ir0,ir1,pc0,pc1
);
    //是否需要改用循环队列？head+tail。for循环赋值对性能影响大吗？
    reg [31:0]buffer[0:15];//是否会溢出？
    reg [31:0]bufferpc[0:15];
    reg [3:0]pointer;
    reg new=1;
    wire [31:0]ir[0:1];
    assign ir0=buffer[1];
    assign ir1=buffer[0];
    assign ir[1]=irin[31:0];
    assign ir[0]=irin[63:32];
    assign pc0=bufferpc[1];
    assign pc1=bufferpc[0];
    // reg [127:0]ir_reg;
    // assign ir[2]=irin[95:64];
    // assign ir[3]=irin[127:96];
    // assign new=(ir_reg!=irin);
    // always @(posedge clk,negedge rstn) begin
    //     if(!rstn) ir_reg<=0;
    //     else ir_reg<=irin;
    // end
    always @(posedge clk,negedge rstn) begin:fetch_buffer
        integer i;
        if(!rstn) 
            begin
                pointer<=0;
                for (i=0;i<32;i=i+1) begin
                        buffer[i]<=0;
                        bufferpc[i]<=0;
                end
            end
        else 
            case ({if0,if1,new})//if1是优先级高的通道，即pc小的一侧
            //是否会出现if0&!if1的情况？
                'b000: ;
                'b001: begin 
                    pointer<=pointer+flag+1;
                    for (i=0;i<flag+1;i=i+1)begin
                        buffer[pointer+i]<=ir[i];
                        bufferpc[pointer+i]<=pc+i;
                    end
                end
                'b010: begin 
                    if(pointer>0) begin
                        pointer<=pointer-1;
                        for (i=0;i<pointer-1;i=i+1)begin
                            buffer[i]<=buffer[i+1];
                            bufferpc[i]<=bufferpc[i+1];
                        end
                        buffer[pointer-1]<=0;
                        bufferpc[pointer-1]<=0;
                    end
                end
                'b011: begin 
                    if(pointer>0) begin
                        pointer<=pointer+flag;
                        for (i=0;i<pointer-1;i=i+1)begin
                            buffer[i]<=buffer[i+1];
                            bufferpc[i]<=bufferpc[i+1];
                        end
                        for (i=0;i<flag+1;i=i+1)begin
                            buffer[pointer-1+i]<=ir[i];
                            bufferpc[pointer-1+i]<=pc+i;
                        end
                    end
                    else begin
                        pointer<=pointer+flag+1;
                        for (i=0;i<flag+1;i=i+1)begin
                            buffer[pointer+i]<=ir[i];
                            bufferpc[pointer+i]<=pc+i;
                        end
                    end
                end
                'b100: begin 
                    if(pointer>1) begin
                        pointer<=pointer-1;
                        for (i=1;i<pointer-1;i=i+1)begin
                            buffer[i]<=buffer[i+1];
                            bufferpc[i]<=bufferpc[i+1];
                        end
                        buffer[pointer-1]<=0;
                        bufferpc[pointer-1]<=0;
                    end
                end
                'b101: begin 
                    if(pointer>1) begin
                        pointer<=pointer+flag;
                        for (i=1;i<pointer-1;i=i+1)begin
                            buffer[i]<=buffer[i+1];
                            bufferpc[i]<=bufferpc[i+1];
                        end
                        for (i=0;i<flag+1;i=i+1)begin
                            buffer[pointer-1+i]<=ir[i];
                            bufferpc[pointer-1+i]<=pc+i;
                        end
                    end
                    else begin
                        pointer<=pointer+flag+1;
                        for (i=0;i<flag+1;i=i+1)begin
                            buffer[pointer+i]<=ir[i];
                            bufferpc[pointer+i]<=pc+i;
                        end
                    end
                end
                'b110: begin 
                    if(pointer>1) begin
                        pointer<=pointer-2;
                        for (i=0;i<pointer-2;i=i+1)begin
                            buffer[i]<=buffer[i+2];
                            bufferpc[i]<=bufferpc[i+2];
                        end
                        buffer[pointer-1]<=0;
                        buffer[pointer-2]<=0;
                        bufferpc[pointer-1]<=0;
                        bufferpc[pointer-2]<=0;
                    end
                    else if(pointer==1) begin
                        pointer<=pointer-1;
                        // for (i=0;i<pointer-1;i=i+1)begin
                        //     buffer[i]<=buffer[i+1];
                        // end
                        buffer[0]<=0;
                        bufferpc[0]<=0;
                    end
                end
                'b111: begin 
                    if(pointer>1) begin
                        pointer<=pointer+flag-1;
                        for (i=0;i<pointer-2;i=i+1)begin
                            buffer[i]<=buffer[i+2];
                            bufferpc[i]<=bufferpc[i+2];
                        end
                        for (i=0;i<flag+1;i=i+1)begin
                            buffer[pointer-2+i]<=ir[i];
                            bufferpc[pointer-2+i]<=pc+i;
                        end
                    end
                    else begin
                        pointer<=pointer+flag+1;
                        for (i=0;i<flag+1;i=i+1)begin
                            buffer[i]<=ir[i];
                            bufferpc[i]<=pc+i;
                        end
                    end
                end
                default: ;
            endcase
    end

endmodule