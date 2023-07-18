module predictor #(
    parameter bh_width = 16,
              gh_width = 16,
              ch_width = 16
)(
    input clk,
    input rstn,
    //来自ex段
    input [31:0]ex_pc,
    input [31:0]ex_npc,
    input ex_flush,
    //来自id段  //(需要沟通指令类型)
    input [31:0]id_pc,
    input [2:0]id_kind,    //0:非跳转指令 1:直接跳转指令 2:CALL 3:RET 4: 无条件跳转 5:其他跳转指令

    output [31:0]pc,
    output [2:0]kind
);
    wire predict_right=~ex_flush;
endmodule