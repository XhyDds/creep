module npc_predictor#(
    parameter   gh_width   = 14,
                stack_len  = 16,
                ADDR_WIDTH = 30
)(
    input clk,
    input rstn,
    input update_en,
    //ex
    input [ADDR_WIDTH-1:0] npc_ex,
    input [gh_width-1:0] pc_ex_gh_hashed,
    input [2:0]kind_ex,
    input choice_real,
    input mis_pdc,   //地址预测错误
    //预测
    output reg[ADDR_WIDTH-1:0] npc_pdc,
    input [2:0]kind_pdc,
    input taken_pdc,
    output choice_btb_ras,    //0:btb,1:ras
    output reg[ADDR_WIDTH-1:0] npc_test,
    //当前
    input [gh_width-1:0] pc_gh_hashed,
    input [ADDR_WIDTH-1:0] pc
);
    parameter NOT_JUMP = 3'd0,DIRECT_JUMP = 3'd1,JUMP=3'd2,CALL = 3'd3,RET = 3'd4,INDIRECT_JUMP = 3'd5,OTHER_JUMP = 3'd6;

    // assign npc_test=pc+1;
    // npc_test
    reg [29:0]offset_test;
    always @(posedge clk,negedge rstn) begin
        if(!rstn)  begin
            offset_test<=0;
            npc_test<=0;
        end 
        else begin
            npc_test<=offset_test;
            if(offset_test==0) offset_test<=0;
            else offset_test<=1;
        end
    end
    
    wire [ADDR_WIDTH-1:0]npc_btb;
    wire [ADDR_WIDTH-1:0]npc_ras;

    btb#(
        .gh_width(gh_width),
        .ADDR_WIDTH(ADDR_WIDTH)
    )
    btb_table(
        .clk(clk),
        .hashed_pc(pc_gh_hashed),
        .npc_pdc(npc_btb),
        .hashed_pc_update(pc_ex_gh_hashed),
        .npc_real(npc_ex),
        .update_en((kind_ex!=3'd0)&&update_en)
    );

    ras#(
        .stack_len(stack_len),
        .ADDR_WIDTH(ADDR_WIDTH)
    )
    ret_stack(
        .clk(clk),
        .rstn(rstn),
        .is_call_ex(kind_ex==CALL),
        .ret_pc_ex(npc_ex),
        .ret_pc_pdc(npc_ras),
        .mis_pdc(mis_pdc),
        .is_ret_ex(kind_ex==RET),
        .is_ret_pdc(kind_pdc==RET),
        .update_en(update_en)
    );

    cpht#(
        .ch_width(gh_width)
    )
    cpht_btb_ras(
        .clk(clk),
        .hashed_pc(pc_gh_hashed),
        .choice_pdc(choice_btb_ras),
        .hashed_pc_update(pc_ex_gh_hashed),
        .choice_real(choice_real),
        .update_en((kind_ex==RET)&&update_en)
    );

    always @(*) begin
        if(taken_pdc) begin
            case (kind_pdc)
                NOT_JUMP: 
                    if(~pc[0])   npc_pdc=pc+2;
                    else        npc_pdc=pc+1;
                DIRECT_JUMP:    npc_pdc=npc_btb;
                CALL:           npc_pdc=npc_btb;
                RET:            npc_pdc=choice_btb_ras?npc_ras:npc_btb;
                INDIRECT_JUMP:  npc_pdc=npc_btb;
                OTHER_JUMP:     npc_pdc=npc_btb;
                default: 
                    if(~pc[0])   npc_pdc=pc+2;
                    else        npc_pdc=pc+1;
            endcase
        end
        else        
                    if(~pc[0])   npc_pdc=pc+2;
                    else        npc_pdc=pc+1;
    end
endmodule
