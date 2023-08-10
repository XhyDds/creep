module npc_predictor#(
    parameter   bh_width   = 16,
                gh_width   = 16,
                h_width   = 8,
                k_width   = 12,
                stack_len  = 16,
                ADDR_WIDTH = 30
)(
    input clk,
    input rstn,
    input stall,
    input update_en,
    input taken_ex,
    //ex
    input [ADDR_WIDTH-1:0] npc_ex,
    input [ADDR_WIDTH-1:0] pc_ex,
    input [bh_width-1:0] bh_ex,
    input [2:0]kind_ex,
    input choice_real,
    input [29:0]ret_pc_ex,
    input [1:0]choice_pdch_ex,
    input mis_pdc,   //地址预测错误
    //预测
    output reg[ADDR_WIDTH-1:0] npc_pdc,
    input [2:0]kind_pdc,
    input taken_pdc,
    output choice_btb_ras,    //0:ras,1:btb
    output [1:0]choice_pdch,
    output reg[ADDR_WIDTH-1:0] npc_test,
    //当前
    input [bh_width-1:0] bh_reg,
    input [ADDR_WIDTH-1:0] pc_reg,
    input [ADDR_WIDTH-1:0] pc_reg_reg
);
    parameter   NOT_JUMP = 3'd0,
                DIRECT_JUMP = 3'd1,
                //
                RET = 3'd4,
                INDIRECT_JUMP = 3'd5,
                CALL = 3'd6,
                JUMP=3'd7;
    always @(*) begin
        if(pc_reg[0]) npc_test=pc_reg+1;
        else npc_test=pc_reg+2;
    end
    
    wire [ADDR_WIDTH-1:0]npc_btb;
    wire [ADDR_WIDTH-1:0]npc_ras;

    btb#(                   //pc_reg+bh
        .bh_width(bh_width),
        .h_width(h_width),
        .k_width(k_width),
        .ADDR_WIDTH(ADDR_WIDTH)
    )
    btb_table(
        .clk(clk),
        .stall(stall),
        .pc(pc_reg),
        .bh(bh_reg),
        .npc_pdc(npc_btb),
        .npc_real(npc_ex),
        .pc_update(pc_ex),
        .bh_update(bh_ex),
        .update_en((kind_ex!=3'd0)&&update_en&&taken_ex)
    );

    ras#(
        .stack_len(stack_len),
        .ADDR_WIDTH(ADDR_WIDTH)
    )
    ret_stack(
        .clk(clk),
        .rstn(rstn),
        .is_call_ex(kind_ex==CALL),
        .ret_pc_ex(ret_pc_ex),
        .ret_pc_pdc(npc_ras),
        .mis_pdc(mis_pdc&~choice_pdch_ex[1]),
        .is_ret_ex(kind_ex==RET),
        .is_ret_pdc(kind_pdc==RET),
        .update_en(update_en)
    );

    cpht#(              //pc_reg
        .k_width(k_width),
        .ADDR_WIDTH(ADDR_WIDTH)
    )
    cpht_btb_ras(
        .clk(clk),
        .stall(stall),
        .pc(pc_reg),
        .choice_pdc(choice_btb_ras),
        .choice_pdch(choice_pdch),
        .pc_update(pc_ex),
        .choice_real(choice_real),
        .choice_pdch_ex(choice_pdch_ex),
        .update_en((kind_ex==RET)&&update_en)
    );

    always @(*) begin
        // if(stall) npc_pdc=pc_reg;
        // else 
        if(taken_pdc) begin
            case (kind_pdc)
                NOT_JUMP:       npc_pdc=(({ADDR_WIDTH{~pc_reg_reg[0]}})&(pc_reg_reg+2))|(({ADDR_WIDTH{pc_reg_reg[0]}})&(pc_reg_reg+1));
                DIRECT_JUMP:    npc_pdc=npc_btb;
                RET:            npc_pdc=(({ADDR_WIDTH{choice_btb_ras}})&npc_btb)|(({ADDR_WIDTH{~choice_btb_ras}})&npc_ras);
                INDIRECT_JUMP:  npc_pdc=npc_btb;
                JUMP:           npc_pdc=npc_btb;
                CALL:           npc_pdc=npc_btb;
                // OTHER_JUMP:     npc_pdc=npc_btb;
                default:        npc_pdc=(({ADDR_WIDTH{~pc_reg_reg[0]}})&(pc_reg_reg+2))|(({ADDR_WIDTH{pc_reg_reg[0]}})&(pc_reg_reg+1));
            endcase
        end
        else                    npc_pdc=(({ADDR_WIDTH{~pc_reg_reg[0]}})&(pc_reg_reg+2))|(({ADDR_WIDTH{pc_reg_reg[0]}})&(pc_reg_reg+1));
    end
endmodule