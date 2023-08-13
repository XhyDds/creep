module pred_cache#(
    parameter   addr_width=8,
                tag_width=22,
                h_width=4,
                way=4
)
(
    input       clk,
    input       update_en,

    input       [addr_width-1:0]raddr,
    output reg  [1:0]taken_pdch,
    input       [h_width-1:0] h,
    input       [tag_width-1:0]tag,//用于比较

    // input       [data_width-1:0]TagV_din_write,
    // input       [way-1:0]TagV_we
    input       [addr_width-1:0]waddr,
    input       [1:0]taken_pdch_upt,
    input       mis_pdc,
    input       [h_width-1:0] h_upt,
    input       [tag_width-1:0] tag_upt
);
//declare
    wire [way-1:0]valid_rs;
    wire [way-1:0]hit_rs;
    wire [way-1:0]hits;
    wire [2*way-1:0]taken_pdchs;

    localparam data_width = tag_width+h_width*2+1;

    reg [data_width-1:0] din;
    wire [data_width*way-1:0] douts;
    wire [way-1:0] hit_ws;
    wire [way-1:0]valid_ws;
    wire [way-1:0]hits_w;
    wire [way-1:0]we_s;
//store
generate
    genvar i;
    for(i=0;i<way;i=i+1)begin:hitgenerate
    pred_ram #(
        .TAG_WIDTH(tag_width),
        .ADDR_WIDTH(addr_width),
        .H_WIDTH(h_width)
    )
    eachway(
        .clk(clk),

        .raddr(raddr),
        .taken_pdch(taken_pdchs[2*i+1:2*i]),
        .h(h),
        .tag(tag),
        .hit(hit_rs[i]),
        .valid(valid_rs[i]),

        .waddr(waddr),
        .din_w_reg(din),
        .dout_w(douts[data_width*(i+1)-1:data_width*i]),
        .tag_upt(tag_upt),
        .hit_w(hit_ws[i]),
        .valid_w(valid_ws[i]),
        .update_en_reg(we_s[i])
    );
    end
    assign hits[i]=(hit_rs[i])&&(valid_rs[i]);
    assign hits_w[i]=(hit_ws[i])&&(valid_ws[i]);
endgenerate
//pdc
//upt
endmodule
