module preceptron #(
    parameter   h_width = 16,
                weight_width = 7,
                tag_width = 30

) (
    //预测
    input  [h_width-1:0] pc_hashed,
    input  [tag_width-1:0] tag,

    output taken_pdc,
    //历史
    output [h_width*weight_width-1:0] weight_h,
    //更新
    input  [h_width-1:0] pc_hashed_upt,
    input  [tag_width-1:0] tag_upt,
    input  taken_upt,
    input  [h_width*weight_width-1:0] weight_h_upt
);
    
endmodule