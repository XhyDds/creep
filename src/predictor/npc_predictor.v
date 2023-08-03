module npc_predictor#(
    parameter   h_width   = 14,
                k_width   = 14,
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
    input [h_width-1:0] pc_ex_bh_hashed,
    input [k_width-1:0] pc_ex_hashed,
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
    input [h_width-1:0] pc_bh_hashed,
    input [k_width-1:0] pc_hashed_reg,
    input [ADDR_WIDTH-1:0] pc_reg
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
    // reg [29:0]offset_test;
    // always @(posedge clk)begin
    //     if(!rstn)  begin
    //         offset_test<=0;
    //         npc_test<=0;
    //     end 
    //     else begin
    //         npc_test<=offset_test;
    //         if(offset_test==0) offset_test<=0;
    //         else offset_test<=1;
    //     end
    // end
    
    wire [ADDR_WIDTH-1:0]npc_btb;
    wire [ADDR_WIDTH-1:0]npc_ras;

    btb#(                   //pc_reg+bh
        .h_width(h_width),
        .ADDR_WIDTH(ADDR_WIDTH)
    )
    btb_table(
        .clk(clk),
        .hashed_pc(pc_bh_hashed),
        .npc_pdc(npc_btb),
        .hashed_pc_update(pc_ex_bh_hashed),
        .npc_real(npc_ex),
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
        .mis_pdc(mis_pdc),
        .is_ret_ex(kind_ex==RET),
        .is_ret_pdc(kind_pdc==RET),
        .update_en(update_en)
    );

    cpht#(              //pc_reg
        .ch_width(k_width)
    )
    cpht_btb_ras(
        .clk(clk),
        .hashed_pc(pc_hashed_reg),
        .choice_pdc(choice_btb_ras),
        .choice_pdch(choice_pdch),
        .hashed_pc_update(pc_ex_hashed),
        .choice_real(choice_real),
        .choice_pdch_ex(choice_pdch_ex),
        .update_en((kind_ex==RET)&&update_en)
    );

    always @(*) begin
        // if(stall) npc_pdc=pc_reg;
        // else 
        if(taken_pdc) begin
            case (kind_pdc)
                NOT_JUMP:       npc_pdc=(({ADDR_WIDTH{~pc_reg[0]}})&(pc_reg+2))|(({ADDR_WIDTH{pc_reg[0]}})&(pc_reg+1));
                DIRECT_JUMP:    npc_pdc=npc_btb;
                RET:            npc_pdc=(({ADDR_WIDTH{choice_btb_ras}})&npc_btb)|(({ADDR_WIDTH{~choice_btb_ras}})&npc_ras);
                INDIRECT_JUMP:  npc_pdc=npc_btb;
                JUMP:           npc_pdc=npc_btb;
                CALL:           npc_pdc=npc_btb;
                // OTHER_JUMP:     npc_pdc=npc_btb;
                default:        npc_pdc=(({ADDR_WIDTH{~pc_reg[0]}})&(pc_reg+2))|(({ADDR_WIDTH{pc_reg[0]}})&(pc_reg+1));
            endcase
        end
        else                    npc_pdc=(({ADDR_WIDTH{~pc_reg[0]}})&(pc_reg+2))|(({ADDR_WIDTH{pc_reg[0]}})&(pc_reg+1));
    end

    // reg [ADDR_WIDTH-1:0] npc_pdc_reg;
    // always @(posedge clk) begin
    //     if(!rstn) begin
    //         npc_pdc_reg<=30'h0700_0002;
    //     end
    //     else begin
    //         npc_pdc_reg<=npc_pdc;
    //     end
    // end
endmodule
