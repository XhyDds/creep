//尚未确定pdc周期是否正确
module ghr#(
    parameter   gh_width = 32,
                queue_len= 16       //取决于流水线中同时存在的最大指令数
)(
    input   clk,
    input   rstn,               
    input   stall,                  //因为会根据预测知识进行更新
    output  reg [gh_width-1:0]gh,   //当周期即可给出
    output  reg[gh_width-1:0] gh_ex,
    input   taken_pdc,              //预测得到的是否跳转
    input   taken_ex,               //实际是否跳转

    input   mis_pdc,                //是否预测错误
    input   is_jump_pdc,            //当前指令是否是跳转指令（当前只考虑跳转指令）
    input   is_jump_ex,             //ex段的指令曾经判断是否是跳转指令
    input   is_jump_pdc_ex,         //ex段的指令曾经预测是否是跳转指令
    input   update_en               //ex段传回的是否更新的信号
    );
    //恢复队列
    reg     [gh_width-1:0]  chkpt_q[0:queue_len-1];//check_point queue
    reg     [3:0]pointer;

    wire    is_jump_pdc_ex_=is_jump_pdc_ex&update_en;
    wire    mis_pdc_=mis_pdc&update_en;
    wire    is_jump_ex_=is_jump_ex&update_en;
    wire    is_jump_pdc_=is_jump_pdc&(~stall);

    always @(posedge clk)begin
        if(!rstn) begin
            chkpt_q[4'd0]<=0;
            chkpt_q[4'd1]<=0;
            chkpt_q[4'd2]<=0;
            chkpt_q[4'd3]<=0;
            chkpt_q[4'd4]<=0;
            chkpt_q[4'd5]<=0;
            chkpt_q[4'd6]<=0;
            chkpt_q[4'd7]<=0;
            chkpt_q[4'd8]<=0;
            chkpt_q[4'd9]<=0;
            chkpt_q[4'd10]<=0;
            chkpt_q[4'd11]<=0;
            chkpt_q[4'd12]<=0;
            chkpt_q[4'd13]<=0;
            chkpt_q[4'd14]<=0;
            chkpt_q[4'd15]<=0;
        end
        else if(mis_pdc) begin
            chkpt_q[4'd0]<=0;
            chkpt_q[4'd1]<={gh_ex[gh_width-1:1],~gh_ex[0]};
            chkpt_q[4'd2]<=chkpt_q[4'd1];
            chkpt_q[4'd3]<=chkpt_q[4'd2];
            chkpt_q[4'd4]<=chkpt_q[4'd3];
            chkpt_q[4'd5]<=chkpt_q[4'd4];
            chkpt_q[4'd6]<=chkpt_q[4'd5];
            chkpt_q[4'd7]<=chkpt_q[4'd6];
            chkpt_q[4'd8]<=chkpt_q[4'd7];
            chkpt_q[4'd9]<=chkpt_q[4'd8];
            chkpt_q[4'd10]<=chkpt_q[4'd9];
            chkpt_q[4'd11]<=chkpt_q[4'd10];
            chkpt_q[4'd12]<=chkpt_q[4'd11];
            chkpt_q[4'd13]<=chkpt_q[4'd12];
            chkpt_q[4'd14]<=chkpt_q[4'd13];
            chkpt_q[4'd15]<=chkpt_q[4'd14];
        end 
        else if(is_jump_pdc_) begin
            chkpt_q[4'd0]<=0;
            chkpt_q[4'd1]<={gh[gh_width-2:0],~taken_pdc};
            chkpt_q[4'd2]<=chkpt_q[4'd1];
            chkpt_q[4'd3]<=chkpt_q[4'd2];
            chkpt_q[4'd4]<=chkpt_q[4'd3];
            chkpt_q[4'd5]<=chkpt_q[4'd4];
            chkpt_q[4'd6]<=chkpt_q[4'd5];
            chkpt_q[4'd7]<=chkpt_q[4'd6];
            chkpt_q[4'd8]<=chkpt_q[4'd7];
            chkpt_q[4'd9]<=chkpt_q[4'd8];
            chkpt_q[4'd10]<=chkpt_q[4'd9];
            chkpt_q[4'd11]<=chkpt_q[4'd10];
            chkpt_q[4'd12]<=chkpt_q[4'd11];
            chkpt_q[4'd13]<=chkpt_q[4'd12];
            chkpt_q[4'd14]<=chkpt_q[4'd13];
            chkpt_q[4'd15]<=chkpt_q[4'd14];
        end
    end

    always @(posedge clk)begin
        if(!rstn) begin
            pointer<=0;
        end
        else begin
            if(is_jump_ex_) begin
                if(mis_pdc_) pointer<=0;
                else if(is_jump_pdc_) ;
                else pointer<=pointer-1;
            end
            else if(is_jump_pdc_) begin
                pointer<=pointer+1;
            end
        end
    end

    always @(posedge clk)begin
        if(!rstn) begin
            gh<=0;
        end
        if(mis_pdc_&&is_jump_ex_) begin
            if(is_jump_pdc_ex) begin
                    gh<=chkpt_q[pointer];
            end
            else    gh<={chkpt_q[pointer+1][gh_width-2:0],taken_ex};
        end
        else if(is_jump_pdc_) begin
            gh<={gh[gh_width-2:0],taken_pdc};
        end
    end

    always @(*) begin
        if(is_jump_ex_)
             gh_ex={chkpt_q[pointer+1][gh_width-1:1],~chkpt_q[pointer+1][0]};
        else gh_ex={chkpt_q[pointer][gh_width-1:1],~chkpt_q[pointer][0]};
        // gh_ex=0;
        // if(mis_pdc_&&is_jump_ex_) begin
        //     if(is_jump_pdc_ex) begin
        //             gh_ex=chkpt_q[pointer];
        //     end
        //     else    gh_ex={chkpt_q[pointer+1][gh_width-2:0],taken_ex};
        // end
        // else ;
    end


    // wire ghisffff=(gh_ex==32'hffffffff)&update_en&is_jump_ex;(用于检查发生的miss是否是由于历史较长引起的)
endmodule