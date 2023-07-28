with open('config.txt','r') as file:
    config=file.read()
for line in config.split('\n'):
    if line.startswith('ras_len'):
        len=int(line.split('=')[1])
        break
code='''module ras #(
    parameter   stack_len= '''+str(len)+''',
                ADDR_WIDTH = 30
)(
    input   clk,
    input   rstn,
    input   is_call_ex,            //来自ex段的指令是否为函数调用
    input   [ADDR_WIDTH-1:0] ret_pc_ex,      //来自ex段的返回地址
    output  reg [ADDR_WIDTH-1:0] ret_pc_pdc, //预测的返回地址
    input   mis_pdc,               //地址是否预测错误
    input   is_ret_ex,             //ex段传回的指令是否是返回指令
    input   is_ret_pdc             //预测是否是返回指令
);
    //函数调用栈
    reg [ADDR_WIDTH-1:0] ret_stk[0:stack_len-1];//return stack

    reg error_crt;

    always @(posedge clk,negedge rstn) begin
        if(!rstn) begin'''
for i in range(len):
    code+='''
            ret_stk[4'd'''+str(i)+''']<=0;'''
code+='''
        end
        else if(is_call_ex) begin
            ret_stk[4'd0]<=ret_pc_ex;
            if(!is_ret_pdc) begin   //push'''
for i in range(len-1):
    code+='''
                ret_stk[4'd'''+str(i+1)+''']<=ret_stk[4'd'''+str(i)+'''];'''
code+='''
            end
        end
        else if(is_ret_ex) begin
            if(mis_pdc) begin
                //错误恢复
                case (error_crt)
                    1'b0: error_crt<=1'b1;
                    1'b1: error_crt<=1'b0;
                endcase

                if(error_crt==1'b0)begin
                    if(is_ret_pdc) begin//pop3'''
for i in range(len-3):
    code+='''
                        ret_stk[4'd'''+str(i)+''']<=ret_stk[4'd'''+str(i+3)+'''];'''
for i in range(len-3,len):
    code+='''
                        ret_stk[4'd'''+str(i)+''']<=0;'''
code+='''
                    end
                    else begin//pop2'''
for i in range(len-2):
    code+='''
                        ret_stk[4'd'''+str(i)+''']<=ret_stk[4'd'''+str(i+2)+'''];'''
for i in range(len-2,len):
    code+='''
                        ret_stk[4'd'''+str(i)+''']<=0;'''
code+='''
                    end
                end
                else if(error_crt==1'b1)begin
                    if(is_ret_pdc) begin//pop'''
for i in range(len-1):
    code+='''
                        ret_stk[4'd'''+str(i)+''']<=ret_stk[4'd'''+str(i+1)+'''];'''
for i in range(len-1,len):
    code+='''
                        ret_stk[4'd'''+str(i)+''']<=0;'''
code+='''
                    end
                    else ;//-
                end
            end
            //正确预测
            else begin
                error_crt<=0;

                if(is_ret_pdc) begin    //pop'''
for i in range(len-1):
    code+='''
                    ret_stk[4'd'''+str(i)+''']<=ret_stk[4'd'''+str(i+1)+'''];'''
for i in range(len-1,len):
    code+='''
                    ret_stk[4'd'''+str(i)+''']<=0;'''
code+='''
                end
            end
        end
        else if(is_ret_pdc) begin   //pop'''
for i in range(len-1):
    code+='''
            ret_stk[4'd'''+str(i)+''']<=ret_stk[4'd'''+str(i+1)+'''];'''
for i in range(len-1,len):
    code+='''
            ret_stk[4'd'''+str(i)+''']<=0;'''
code+='''
        end
    end

    always @(*) begin
        ret_pc_pdc=0;
        if(is_ret_pdc) begin
            ret_pc_pdc=ret_stk[4'd0];
            if(is_call_ex) begin
                ret_pc_pdc=ret_pc_ex;
            end
        end
    end
endmodule
'''
# print(code)
with open('ras.v','w+') as f:
    f.write(code)