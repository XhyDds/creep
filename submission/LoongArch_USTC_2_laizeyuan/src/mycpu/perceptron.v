//暂时不做替换
//h_width:16
module perceptron #(
    parameter   hash_width = 8,
                h_width = 16,
                weight_width = 3,
                tag_width = 24,
                threshold = 7'h10

) (
    input  clk,
    input  stall,
    input  update_en,
    //预测
    input  [hash_width-1:0] pc_hashed,
    input  [tag_width-1:0] tag,
    input  [h_width-1:0] h,

    output reg taken_pdc,
    //历史
    output reg[h_width*weight_width-1:0] weight_h,
    //更新
    input  [hash_width-1:0] pc_hashed_upt,
    input  [tag_width-1:0] tag_upt,
    input  mis_pdc_taken,
    input  [h_width-1:0]h_upt,
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

    //compute
        localparam compute_width = weight_width+4;
        //init
        wire [compute_width*h_width-1:0] d;        //标准化//中间连线
        genvar j;
        generate
            for(j=0;j<h_width;j=j+1) begin: BLOCK_INITIAL
                assign d[(compute_width*(j+1))-1:compute_width*j]=~{h[j]^weight[(weight_width*(j+1))-1],4'd0,weight[(weight_width*(j+1))-2:weight_width*j]}+1;
            end
        endgenerate
        //第一层
        wire [compute_width*(h_width/2)-1:0] dd;        //标准化//中间连线
        genvar jj;
        generate
            for(jj=0;jj<h_width/2;jj=jj+1) begin: BLOCK_1
                assign dd[(compute_width*(jj+1))-1:compute_width*jj]=d[(compute_width*(2*jj+1))-1:compute_width*2*jj]+d[(compute_width*(2*jj+2))-1:compute_width*(2*jj+1)];
            end
        endgenerate
        //第二层
        wire [compute_width*(h_width/4)-1:0] ddd;        //标准化//中间连线
        genvar jjj;
        generate
            for(jjj=0;jjj<h_width/4;jjj=jjj+1) begin: BLOCK_2
                assign ddd[(compute_width*(jjj+1))-1:compute_width*jjj]=dd[(compute_width*(2*jjj+1))-1:compute_width*2*jjj]+d[(compute_width*(2*jjj+2))-1:compute_width*(2*jjj+1)];
            end
        endgenerate
        //第三层
        wire [compute_width*(h_width/8)-1:0] dddd;        //标准化//中间连线
        genvar jjjj;
        generate
            for(jjjj=0;jjjj<h_width/8;jjjj=jjjj+1) begin: BLOCK_3
                assign dddd[(compute_width*(jjjj+1))-1:compute_width*jjjj]=ddd[(compute_width*(2*jjjj+1))-1:compute_width*2*jjjj]+d[(compute_width*(2*jjjj+2))-1:compute_width*(2*jjjj+1)];
            end
        endgenerate
        //第四层
        wire [compute_width*(h_width/16)-1:0] ddddd;        //标准化//中间连线
        genvar jjjjj;
        generate
            for(jjjjj=0;jjjjj<h_width/16;jjjjj=jjjjj+1) begin: BLOCK_4
                assign ddddd[(compute_width*(jjjjj+1))-1:compute_width*jjjjj]=dddd[(compute_width*(2*jjjjj+1))-1:compute_width*2*jjjjj]+d[(compute_width*(2*jjjjj+2))-1:compute_width*(2*jjjjj+1)];
            end
        endgenerate
        wire [compute_width-1:0] res=ddddd+threshold;    //减去阈值
    //pdc
    always @(*) begin
        weight_h=0;
        taken_pdc=0;
        if(hit) begin
            weight_h=weight;
            //计算
            if(res[compute_width-1]) taken_pdc=0;    //小于阈值
            else taken_pdc=1;
        end
    end

    //upt
    genvar k;
    generate
        for(k=0;k<h_width;k=k+1) begin: BLOCK_INITIAL
            assign weight_upt[(weight_width*(k+1))-1:weight_width*k]
                =  (mis_pdc_taken^(weight_h_upt[weight_width*(k+1)-1]^h_upt[k]))  //0:+1 1:-1
                    ?(  //-1
                        (|weight_h_upt[(weight_width*(k+1))-2:weight_width*k])  //0:- 1:-1
                        ?(weight_h_upt[(weight_width*(k+1))-1:weight_width*k]-1)
                        :(weight_h_upt[(weight_width*(k+1))-1:weight_width*k])
                    )
                    :(  //+1
                        (&weight_h_upt[(weight_width*(k+1))-2:weight_width*k])  //0:+1 1:-
                        ?(weight_h_upt[(weight_width*(k+1))-1:weight_width*k])
                        :(weight_h_upt[(weight_width*(k+1))-1:weight_width*k]+1)
                    );
        end
    endgenerate
endmodule