//非写优先
module pred_ram #(
    parameter TAG_WIDTH = 22,
              ADDR_WIDTH = 8,
              H_WIDTH = 4
)
(
    input clk,                    // Clock

    input  [ADDR_WIDTH-1:0] raddr,  // Read Address
    output reg [1:0]taken_pdch,
    input  [H_WIDTH-1:0] h,
    input  [TAG_WIDTH-1:0] tag,
    output hit,
    output valid,

    input  [ADDR_WIDTH-1:0] waddr,
    input  [TAG_WIDTH+H_WIDTH*2:0] din_w_reg,
    input  [TAG_WIDTH-1:0] tag_upt,
    output reg[TAG_WIDTH+H_WIDTH*2:0]dout_w,
    output hit_w,
    output valid_w,
    input  update_en_reg               // Write Enable
); 
    localparam DATA_WIDTH = TAG_WIDTH+H_WIDTH*2+1;
    reg [DATA_WIDTH-1:0] dout_r;
    reg [DATA_WIDTH-1:0] ram [0:(1 << ADDR_WIDTH)-1];

    reg  [ADDR_WIDTH-1:0]   waddr_reg;
    reg  [TAG_WIDTH-1:0] tag_upt_reg;

    reg  [DATA_WIDTH-1:0]   din_w;

    integer i;
    initial begin
        for (i = 0; i < (1 << ADDR_WIDTH); i = i + 1) begin
            ram[i] = 0;
        end
    end

    always @(posedge clk) begin
        waddr_reg   <= waddr   ;
        tag_upt_reg <= tag_upt ;

        dout_r <= ram[raddr];
        dout_w <= ram[waddr];
        if (update_en_reg) ram[waddr_reg] <= din_w_reg;
    end
    assign  hit = tag == dout_r[TAG_WIDTH:1];
    assign  hit_w = tag_upt_reg == dout_w[TAG_WIDTH:1];
    assign  valid = dout_r[0];
    assign  valid_w = dout_w[0];

    assign  taken_pdch=(hit&valid)?{ram[raddr][TAG_WIDTH+2*h+1],ram[raddr][TAG_WIDTH+2*h]}:2'b0;

endmodule
