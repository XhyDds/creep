module L2cache_prefnum#(
    parameter   addr_width=4,
                data_width=3,
                way=8
)
(
    input       clk,rstn,
    input       [addr_width-1:0]num_addr_read,
    input       [addr_width-1:0]num_addr_write,
    input       [data_width-1:0]num_din,
    output      [data_width-1:0]num_dout,
    input       [way-1:0]hit,
    input       [way-1:0]num_we,
    input       clear
    );

wire [data_width-1:0]num_data[way-1:0];

L2cache_prefnum_lut #(
    .DATA_WIDTH(data_width),
    .ADDR_WIDTH(addr_width)
)
way0(
    .clk(clk),.rstn(rstn),

    .waddr(num_addr_write),
    .din(num_din),
    .we(num_we[0]),

    .raddr(num_addr_read),
    .dout(num_data[0]),
    .clear(clear & num_we[0])
);

L2cache_prefnum_lut #(
    .DATA_WIDTH(data_width),
    .ADDR_WIDTH(addr_width)
)
way1(
    .clk(clk),.rstn(rstn),

    .waddr(num_addr_write),
    .din(num_din),
    .we(num_we[1]),

    .raddr(num_addr_read),
    .dout(num_data[1]),
    .clear(clear & num_we[1])
);

L2cache_prefnum_lut #(
    .DATA_WIDTH(data_width),
    .ADDR_WIDTH(addr_width)
)
way2(
    .clk(clk),.rstn(rstn),

    .waddr(num_addr_write),
    .din(num_din),
    .we(num_we[2]),

    .raddr(num_addr_read),
    .dout(num_data[2]),
    .clear(clear & num_we[2])
);

L2cache_prefnum_lut #(
    .DATA_WIDTH(data_width),
    .ADDR_WIDTH(addr_width)
)
way3(
    .clk(clk),.rstn(rstn),

    .waddr(num_addr_write),
    .din(num_din),
    .we(num_we[3]),

    .raddr(num_addr_read),
    .dout(num_data[3]),
    .clear(clear & num_we[3])
);

L2cache_prefnum_lut #(
    .DATA_WIDTH(data_width),
    .ADDR_WIDTH(addr_width)
)
way4(
    .clk(clk),.rstn(rstn),

    .waddr(num_addr_write),
    .din(num_din),
    .we(num_we[4]),

    .raddr(num_addr_read),
    .dout(num_data[4]),
    .clear(clear & num_we[4])
);

L2cache_prefnum_lut #(
    .DATA_WIDTH(data_width),
    .ADDR_WIDTH(addr_width)
)
way5(
    .clk(clk),.rstn(rstn),

    .waddr(num_addr_write),
    .din(num_din),
    .we(num_we[5]),

    .raddr(num_addr_read),
    .dout(num_data[5]),
    .clear(clear & num_we[5])
);

L2cache_prefnum_lut #(
    .DATA_WIDTH(data_width),
    .ADDR_WIDTH(addr_width)
)
way6(
    .clk(clk),.rstn(rstn),

    .waddr(num_addr_write),
    .din(num_din),
    .we(num_we[6]),

    .raddr(num_addr_read),
    .dout(num_data[6]),
    .clear(clear & num_we[6])
);

L2cache_prefnum_lut #(
    .DATA_WIDTH(data_width),
    .ADDR_WIDTH(addr_width)
)
way7(
    .clk(clk),.rstn(rstn),

    .waddr(num_addr_write),
    .din(num_din),
    .we(num_we[7]),

    .raddr(num_addr_read),
    .dout(num_data[7]),
    .clear(clear & num_we[7])
);

assign num_dout = hit[0] ? num_data[0] :
                  hit[1] ? num_data[1] :
                  hit[2] ? num_data[2] :
                  hit[3] ? num_data[3] :
                  hit[4] ? num_data[4] :
                  hit[5] ? num_data[5] :
                  hit[6] ? num_data[6] :
                  hit[7] ? num_data[7] : 0;

endmodule