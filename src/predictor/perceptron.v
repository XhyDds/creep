module perceptron #(
    parameter   hash_width = 14,
                h_width = 16,
                weight_width = 7,
                tag_width = 30

) (
    input  clk,
    input  stall,
    input  update_en,
    //预测
    input  [hash_width-1:0] pc_hashed,
    input  [tag_width-1:0] tag,

    output taken_pdc,
    //历史
    output [h_width*weight_width-1:0] weight_h,
    //更新
    input  [hash_width-1:0] pc_hashed_upt,
    input  [tag_width-1:0] tag_upt,
    input  taken_upt,
    input  [h_width*weight_width-1:0] weight_h_upt
);
    wire [h_width*weight_width-1:0] weight;
    wire [tag_width-1:0] tag_;
    reg  [tag_width-1:0] tag_reg;
    reg [h_width*weight_width-1:0] weight_upt;
    wire hit=(tag_==tag_reg);

    always @(posedge clk) begin
        if(~stall)  tag_reg<=tag;
    end

    assign weight_h=weight;

    //table
    sp_bram#(
        .ADDR_WIDTH(hash_width),
        .DATA_WIDTH(h_width*weight_width+tag_width),
        .INIT_NUM(0)
    )u_weight_table(
        .clk(clk),
        .raddr(pc_hashed),
        .dout({weight, tag_}),
        .enb(~stall),
        .waddr(pc_hashed_upt),
        .din({weight_upt, tag_upt}),
        .we(update_en)
    );

    //pdc
    always @(*) begin
        if(hit) begin
            
        end
    end

    //upt
    always @(*) begin
        
    end

endmodule