module ras #(
    parameter   stack_len= 16,
                ADDR_WIDTH = 30
)(
    input   clk,
    input   rstn,
    input   update_en,
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

    always @(posedge clk)begin
        if(!rstn) begin
            ret_stk[4'd0]<=0;
            ret_stk[4'd1]<=0;
            ret_stk[4'd2]<=0;
            ret_stk[4'd3]<=0;
            ret_stk[4'd4]<=0;
            ret_stk[4'd5]<=0;
            ret_stk[4'd6]<=0;
            ret_stk[4'd7]<=0;
            ret_stk[4'd8]<=0;
            ret_stk[4'd9]<=0;
            ret_stk[4'd10]<=0;
            ret_stk[4'd11]<=0;
            ret_stk[4'd12]<=0;
            ret_stk[4'd13]<=0;
            ret_stk[4'd14]<=0;
            ret_stk[4'd15]<=0;
        end
        else if(~update_en) ;
        else if(is_call_ex) begin
            ret_stk[4'd0]<=ret_pc_ex;
            if(!is_ret_pdc) begin   //push
                ret_stk[4'd1]<=ret_stk[4'd0];
                ret_stk[4'd2]<=ret_stk[4'd1];
                ret_stk[4'd3]<=ret_stk[4'd2];
                ret_stk[4'd4]<=ret_stk[4'd3];
                ret_stk[4'd5]<=ret_stk[4'd4];
                ret_stk[4'd6]<=ret_stk[4'd5];
                ret_stk[4'd7]<=ret_stk[4'd6];
                ret_stk[4'd8]<=ret_stk[4'd7];
                ret_stk[4'd9]<=ret_stk[4'd8];
                ret_stk[4'd10]<=ret_stk[4'd9];
                ret_stk[4'd11]<=ret_stk[4'd10];
                ret_stk[4'd12]<=ret_stk[4'd11];
                ret_stk[4'd13]<=ret_stk[4'd12];
                ret_stk[4'd14]<=ret_stk[4'd13];
                ret_stk[4'd15]<=ret_stk[4'd14];
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
                    if(is_ret_pdc) begin//pop3
                        ret_stk[4'd0]<=ret_stk[4'd3];
                        ret_stk[4'd1]<=ret_stk[4'd4];
                        ret_stk[4'd2]<=ret_stk[4'd5];
                        ret_stk[4'd3]<=ret_stk[4'd6];
                        ret_stk[4'd4]<=ret_stk[4'd7];
                        ret_stk[4'd5]<=ret_stk[4'd8];
                        ret_stk[4'd6]<=ret_stk[4'd9];
                        ret_stk[4'd7]<=ret_stk[4'd10];
                        ret_stk[4'd8]<=ret_stk[4'd11];
                        ret_stk[4'd9]<=ret_stk[4'd12];
                        ret_stk[4'd10]<=ret_stk[4'd13];
                        ret_stk[4'd11]<=ret_stk[4'd14];
                        ret_stk[4'd12]<=ret_stk[4'd15];

                        ret_stk[4'd13]<=ret_stk[4'd15];
                        ret_stk[4'd14]<=ret_stk[4'd15];
                        ret_stk[4'd15]<=ret_stk[4'd15];
                    end
                    else begin//pop2
                        ret_stk[4'd0]<=ret_stk[4'd2];
                        ret_stk[4'd1]<=ret_stk[4'd3];
                        ret_stk[4'd2]<=ret_stk[4'd4];
                        ret_stk[4'd3]<=ret_stk[4'd5];
                        ret_stk[4'd4]<=ret_stk[4'd6];
                        ret_stk[4'd5]<=ret_stk[4'd7];
                        ret_stk[4'd6]<=ret_stk[4'd8];
                        ret_stk[4'd7]<=ret_stk[4'd9];
                        ret_stk[4'd8]<=ret_stk[4'd10];
                        ret_stk[4'd9]<=ret_stk[4'd11];
                        ret_stk[4'd10]<=ret_stk[4'd12];
                        ret_stk[4'd11]<=ret_stk[4'd13];
                        ret_stk[4'd12]<=ret_stk[4'd14];
                        ret_stk[4'd13]<=ret_stk[4'd15];

                        ret_stk[4'd14]<=ret_stk[4'd15];
                        ret_stk[4'd15]<=ret_stk[4'd15];
                    end
                end
                else begin
                    if(is_ret_pdc) begin//pop
                        ret_stk[4'd0]<=ret_stk[4'd1];
                        ret_stk[4'd1]<=ret_stk[4'd2];
                        ret_stk[4'd2]<=ret_stk[4'd3];
                        ret_stk[4'd3]<=ret_stk[4'd4];
                        ret_stk[4'd4]<=ret_stk[4'd5];
                        ret_stk[4'd5]<=ret_stk[4'd6];
                        ret_stk[4'd6]<=ret_stk[4'd7];
                        ret_stk[4'd7]<=ret_stk[4'd8];
                        ret_stk[4'd8]<=ret_stk[4'd9];
                        ret_stk[4'd9]<=ret_stk[4'd10];
                        ret_stk[4'd10]<=ret_stk[4'd11];
                        ret_stk[4'd11]<=ret_stk[4'd12];
                        ret_stk[4'd12]<=ret_stk[4'd13];
                        ret_stk[4'd13]<=ret_stk[4'd14];
                        ret_stk[4'd14]<=ret_stk[4'd15];

                        ret_stk[4'd15]<=ret_stk[4'd15];
                    end
                    else ;//-
                end
            end
            //正确预测
            else begin
                error_crt<=0;

                if(is_ret_pdc) begin    //pop
                    ret_stk[4'd0]<=ret_stk[4'd1];
                    ret_stk[4'd1]<=ret_stk[4'd2];
                    ret_stk[4'd2]<=ret_stk[4'd3];
                    ret_stk[4'd3]<=ret_stk[4'd4];
                    ret_stk[4'd4]<=ret_stk[4'd5];
                    ret_stk[4'd5]<=ret_stk[4'd6];
                    ret_stk[4'd6]<=ret_stk[4'd7];
                    ret_stk[4'd7]<=ret_stk[4'd8];
                    ret_stk[4'd8]<=ret_stk[4'd9];
                    ret_stk[4'd9]<=ret_stk[4'd10];
                    ret_stk[4'd10]<=ret_stk[4'd11];
                    ret_stk[4'd11]<=ret_stk[4'd12];
                    ret_stk[4'd12]<=ret_stk[4'd13];
                    ret_stk[4'd13]<=ret_stk[4'd14];
                    ret_stk[4'd14]<=ret_stk[4'd15];

                    ret_stk[4'd15]<=ret_stk[4'd15];
                end
            end
        end
        else if(is_ret_pdc) begin   //pop
            ret_stk[4'd0]<=ret_stk[4'd1];
            ret_stk[4'd1]<=ret_stk[4'd2];
            ret_stk[4'd2]<=ret_stk[4'd3];
            ret_stk[4'd3]<=ret_stk[4'd4];
            ret_stk[4'd4]<=ret_stk[4'd5];
            ret_stk[4'd5]<=ret_stk[4'd6];
            ret_stk[4'd6]<=ret_stk[4'd7];
            ret_stk[4'd7]<=ret_stk[4'd8];
            ret_stk[4'd8]<=ret_stk[4'd9];
            ret_stk[4'd9]<=ret_stk[4'd10];
            ret_stk[4'd10]<=ret_stk[4'd11];
            ret_stk[4'd11]<=ret_stk[4'd12];
            ret_stk[4'd12]<=ret_stk[4'd13];
            ret_stk[4'd13]<=ret_stk[4'd14];
            ret_stk[4'd14]<=ret_stk[4'd15];

            ret_stk[4'd15]<=ret_stk[4'd15];
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
