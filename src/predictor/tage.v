<<<<<<< HEAD
=======
//4 comp tage 
module tage#(
    parameter gh_width = 32,
            ADDR_WIDTH = 30,
            h_width = 8,
            DATA_WIDTH = 27
)(
    input  clk,
    input  update_en,
    //pc
    input  [ADDR_WIDTH-1:0]pc_reg,
    input  [gh_width-1:0]gh,
    //bh
    input  taken_bh,
    //ex
    input  [ADDR_WIDTH-1:0]pc_ex,
    input  taken_pdc_ex,
    input  taken_ex,
    input  [gh_width-1:0]gh_ex,
    input [11:0]pdch_ex,
    //pdc
    output reg taken_pdc,
    output [11:0]pdch
);
    wire pred_pdch_8;
    wire pred_pdch_16;
    wire pred_pdch_32;
    wire [1:0]u_pdch_8;
    wire [1:0]u_pdch_16;
    wire [1:0]u_pdch_32;
    reg [1:0]choice_pdch;
    reg taken_altpdc;
    assign pdch={choice_pdch,taken_altpdc,u_pdch_32,u_pdch_16,u_pdch_8,pred_pdch_32,pred_pdch_16,pred_pdch_8};
    wire pred_pdch_ex_8=pdch_ex[0];
    wire pred_pdch_ex_16=pdch_ex[1];
    wire pred_pdch_ex_32=pdch_ex[2];
    wire [1:0]u_pdch_ex_8=pdch_ex[4:3];
    wire [1:0]u_pdch_ex_16=pdch_ex[6:5];
    wire [1:0]u_pdch_ex_32=pdch_ex[8:7];
    wire [1:0]choice_pdch_ex=pdch_ex[10:9];
    wire taken_altpdc_ex=pdch_ex[11];

    wire [h_width-1:0] hashed_pc_gh_8;
    wire [h_width-1:0] hashed_pc_gh_upt_8;
    wire [h_width-1:0] hashed_pc_gh_16;
    wire [h_width-1:0] hashed_pc_gh_upt_16;
    wire [h_width-1:0] hashed_pc_gh_32;
    wire [h_width-1:0] hashed_pc_gh_upt_32;

//comp

    wire [1:0]u_8;
    wire pred_8;
    reg [1:0] u_upt_8;
    reg pred_upt_8;
    wire [DATA_WIDTH-4:0] _pc_8;
    wire hit_8=(_pc_8==pc_reg[23:0]);
    reg update_en_8;
    sp_dram#(
        .ADDR_WIDTH(h_width),
        .DATA_WIDTH(DATA_WIDTH)
    )
    bpht_regs_8(
        .clk(clk),
        .raddr(hashed_pc_gh_8),
        .dout({pred_8,_pc_8,u_8}),
        .waddr(hashed_pc_gh_upt_8),
        .din({pred_upt_8,pc_ex[23:0],u_upt_8}),
        .we(update_en_8)
    );

    wire [1:0]u_16;
    wire pred_16;
    reg [1:0] u_upt_16;
    reg pred_upt_16;
    wire [DATA_WIDTH-4:0] _pc_16;
    wire hit_16=(_pc_16==pc_reg[23:0]);
    reg update_en_16;
    sp_dram#(
        .ADDR_WIDTH(h_width),
        .DATA_WIDTH(DATA_WIDTH)
    )
    bpht_regs_16(
        .clk(clk),
        .raddr(hashed_pc_gh_16),
        .dout({pred_16,_pc_16,u_16}),
        .waddr(hashed_pc_gh_upt_16),
        .din({pred_upt_16,pc_ex[23:0],u_upt_16}),
        .we(update_en_16)
    );

    wire [1:0]u_32;
    wire pred_32;
    reg [1:0] u_upt_32;
    reg pred_upt_32;
    wire [DATA_WIDTH-4:0] _pc_32;
    wire hit_32=(_pc_32==pc_reg[23:0]);
    reg update_en_32;
    sp_dram#(
        .ADDR_WIDTH(h_width),
        .DATA_WIDTH(DATA_WIDTH)
    )
    bpht_regs_32(
        .clk(clk),
        .raddr(hashed_pc_gh_32),
        .dout({pred_32,_pc_32,u_32}),
        .waddr(hashed_pc_gh_upt_32),
        .din({pred_upt_32,pc_ex[23:0],u_upt_32}),
        .we(update_en_32)
    );

//pred
    always @(*) begin
        if(hit_32&u_32[1]) begin
            taken_pdc=pred_32;
            choice_pdch=2'b11;

            if(hit_16&u_16[1]) 
                taken_altpdc=pred_16;
            else if(hit_8&u_8[1])
                taken_altpdc=pred_8;
            else
                taken_altpdc=taken_bh;
        end
        else if(hit_16&u_16[1]) begin
            taken_pdc=pred_16;
            choice_pdch=2'b10;
            
            if(hit_8&u_8[1])
                taken_altpdc=pred_8;
            else
                taken_altpdc=taken_bh;
        end
        else if(hit_8&u_8[1]) begin
            taken_pdc=pred_8;
            choice_pdch=2'b01;
            taken_altpdc=taken_bh;
        end
        else begin
            taken_pdc=taken_bh;
            choice_pdch=2'b00;
            taken_altpdc=taken_bh;
        end
    end

//update
    reg u_taken_8,u_taken_16,u_taken_32;
    wire[1:0] u_upt_8_,u_upt_16_,u_upt_32_;
    always @(*) begin
        u_upt_8=u_upt_8_;
        u_upt_16=u_upt_16_;
        u_upt_32=u_upt_32_;
        u_taken_8=0;
        u_taken_16=0;
        u_taken_32=0;
        update_en_8=0;
        update_en_16=0;
        update_en_32=0;
        pred_upt_8=pred_pdch_8;
        pred_upt_16=pred_pdch_16;
        pred_upt_32=pred_pdch_32;
        if(update_en) ;
        else if(taken_pdc_ex==taken_ex) begin//预测正确
            if(taken_altpdc_ex!=taken_pdc_ex) begin
                case (choice_pdch_ex)
                    2'b11: begin
                        update_en_32=1;
                        u_taken_32=1;
                    end
                    2'b10: begin
                        update_en_16=1;
                        u_taken_16=1;
                    end
                    2'b01: begin
                        update_en_8=1;
                        u_taken_8=1;
                    end
                    2'b00: ;
                endcase
            end
            else begin
                //清空策略
            end
        end
        else begin//预测失败
            //自减
            case (choice_pdch_ex)
                2'b11: begin
                    update_en_32=1;
                    u_taken_32=0;
                end
                2'b10: begin
                    update_en_16=1;
                    u_taken_16=0;
                end
                2'b01: begin
                    update_en_8=1;
                    u_taken_8=0;
                end
                2'b00: ;
            endcase
            //分配
            if(u_pdch_8==0) begin
                u_upt_8=2'b10;
                pred_upt_8=taken_ex;
                update_en_8=1;
            end
            else if(u_pdch_16==0) begin
                u_upt_16=2'b10;
                pred_upt_16=taken_ex;
                update_en_16=1;
            end
            else if(u_pdch_32==0) begin
                u_upt_32=2'b10;
                pred_upt_32=taken_ex;
                update_en_32=1;
            end
            else begin //全体减一
                u_taken_8=0;
                u_taken_16=0;
                u_taken_32=0;
                update_en_8=1;
                update_en_16=1;
                update_en_32=1;
            end
        end
    end

//2bit prepare for update
    transformer_2bit u_2bit_8(
        .crt(u_pdch_ex_8),
        .nxt(u_upt_8_),
        .taken(u_taken_8)
    );    
    transformer_2bit u_2bit_16(
        .crt(u_pdch_ex_16),
        .nxt(u_upt_16_),
        .taken(u_taken_16)
    );
    transformer_2bit u_2bit_32(
        .crt(u_pdch_ex_32),
        .nxt(u_upt_32_),
        .taken(u_taken_32)
    );

//hash
    pc_gh_hash#(
        .GH_width(gh_width),
        .ADDR_width(ADDR_WIDTH),
        .HASH_width(h_width)
    )u_hash(
        .gh(gh),
        .pc(pc_reg),
        .hashed_8(hashed_pc_gh_8),
        .hashed_16(hashed_pc_gh_16),
        .hashed_32(hashed_pc_gh_32)
    );

        //hash
    pc_gh_hash#(
        .GH_width(gh_width),
        .ADDR_width(ADDR_WIDTH),
        .HASH_width(h_width)
    )u_hash_upt(
        .gh(gh_ex),
        .pc(pc_ex),
        .hashed_8(hashed_pc_gh_upt_8),
        .hashed_16(hashed_pc_gh_upt_16),
        .hashed_32(hashed_pc_gh_upt_32)
    );

endmodule
>>>>>>> 8b9b04c (tage)
