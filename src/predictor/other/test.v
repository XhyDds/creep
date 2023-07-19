module test#(
    parameter   k_width   = 14,
                h_width   = 14,
                stack_len = 16,
                queue_len = 16,
                ADDR_WIDTH= 30
)(
    input clk,
    input rstn,
    //来自ex段
    input [ADDR_WIDTH-1:0]pc_ex,
    input [ADDR_WIDTH-1:0]npc_ex,
    input [2:0]kind_ex,
    input taken_real,
    //需要处理的接线
    output [2:0]mis_pdc,         //2:npc 1:kind 0:taken
    output [1:0]choice_real,     //1:btb/ras  0:g/h
    //曾经的预测段
    input [ADDR_WIDTH-1:0]npc_pdc,
    input [2:0]kind_pdc,
    input taken_pdc,
    input [1:0]choice_pdc,     //1:btb/ras  0:g/h
    //曾经的当前地址
    input [ADDR_WIDTH-1:0]pc
);
    parameter NOT_JUMP = 3'd0,DIRECT_JUMP = 3'd1,CALL = 3'd2,RET = 3'd3,INDIRECT_JUMP = 3'd4,OTHER_JUMP = 3'd5;

    wire try_to_pdc=(kind_ex==DIRECT_JUMP||kind_ex==INDIRECT_JUMP||kind_ex==OTHER_JUMP);

    assign mis_pdc={(npc_ex!=npc_pdc),(kind_ex!=kind_pdc),(taken_real!=taken_pdc)};

    // assign choice_real={choice_real_btb_ras,choice_real_g_h};
endmodule
