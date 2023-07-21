with open('config.txt','r') as file:
    config=file.read()
for line in config.split('\n'):
    if line.startswith('ghr_len'):
        len=int(line.split('=')[1])
        break
code='''module ghr#(
    parameter   gh_width = 14,
                queue_len= '''+str(len)+'''       //取决于流水线中同时存在的最大指令数
)(
    input   clk,
    input   rstn,               
    output  reg [gh_width-1:0]gh,   
    input   taken_pdc,              //预测得到的是否跳转

    input   mis_pdc,                //是否预测错误
    input   is_jump_pdc,            //当前指令是否是跳转指令（当前只考虑跳转指令）
    input   is_jump_ex              //ex段的指令曾经判断是否是跳转指令
    );
    //恢复队列
    reg     [gh_width-1:0]  chkpt_q[0:queue_len-1];//check_point queue
    reg     [3:0]pointer;

    always @(posedge clk,negedge rstn) begin
        if(!rstn) begin'''
for i in range(len):
    code+='''
            chkpt_q[4'd'''+str(i)+''']<=0;'''
code+='''
        end
        else if(is_jump_pdc) begin
            chkpt_q[4'd0]<={gh[gh_width-2:0],~taken_pdc};'''
for i in range(len-1):
    code+='''
            chkpt_q[4'd'''+str(i+1)+''']<=chkpt_q[4'd'''+str(i)+'''];'''
code+='''
        end
    end

    always @(posedge clk,negedge rstn) begin
        if(!rstn) begin
            pointer<=0;
        end
        else begin
            if(is_jump_ex) begin
                if(is_jump_pdc) ;
                else pointer<=pointer-1;
            end
            else if(is_jump_pdc) begin
                pointer<=pointer+1;
            end
        end
    end

    always @(posedge clk,negedge rstn) begin
        if(!rstn) begin
            gh<=0;
        end
        else if(mis_pdc) begin
            gh<=chkpt_q[pointer];
        end
        else if(is_jump_pdc) begin
            gh<={gh[gh_width-2:0],taken_pdc};
        end
    end
endmodule
'''
# print(code)
with open('ghr.v','w+') as f:
    f.write(code)