module ras #(
    parameter   gh_width = 14,
                stack_len= 16
)(
    input   clk,
    input   rstn,               
    input   [31:0] ret_pc_ex,      //来自ex段的返回地址
    output  [31:0] ret_pc_pdc,     //预测的返回地址
    input   mis_pdc,               //地址是否预测错误
    input   is_ret                 //ex段传回的指令是否是返回指令
);
    //函数调用栈
endmodule