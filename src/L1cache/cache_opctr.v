module cache_opctr (
    input clk,
    input opin_i,opin_d,opin_l2,
    input ack_i,ack_d,ack_l2,
    input [31:0]addrin_i,addrin_d,addrin_l2,
    output [31:0]addr_i,addr_d,addr_l2,
    input [31:0]opcodein_i,opcodein_d,opcodein_l2,
    output [31:0]opcode_i,opcode_d,opcode_l2,
    output op_i,op_d,op_l2
);
writefirst_reg #(
    .width(1)
)
op_im(
    .clk(clk),
    .we(opin_i),
    .clear(ack_i),
    .in(1),
    .out(op_i)
    );

writefirst_reg #(
    .width(1)
)
op_dm(
    .clk(clk),
    .we(opin_d),
    .clear(ack_d),
    .in(1),
    .out(op_d)
    );

writefirst_reg #(
    .width(1)
)
op_l2m(
    .clk(clk),
    .we(opin_l2),
    .clear(ack_l2),
    .in(1),
    .out(op_l2)
    );

writefirst_reg #(
    .width(32)
)
addr_im(
    .clk(clk),
    .we(opin_i),
    .clear(ack_i),
    .in(addrin_i),
    .out(addr_i)
    );

writefirst_reg #(
    .width(32)
)
addr_dm(
    .clk(clk),
    .we(opin_d),
    .clear(ack_d),
    .in(addrin_d),
    .out(addr_d)
    );

writefirst_reg #(
    .width(32)
)
addr_l2m(
    .clk(clk),
    .we(opin_l2),
    .clear(ack_l2),
    .in(addrin_l2),
    .out(addr_l2)
    );

writefirst_reg #(
    .width(32)
)
opcode_im(
    .clk(clk),
    .we(opin_i),
    .clear(ack_i),
    .in(opcodein_i),
    .out(opcode_i)
    );

writefirst_reg #(
    .width(32)
)
opcode_dm(
    .clk(clk),
    .we(opin_d),
    .clear(ack_d),
    .in(opcodein_d),
    .out(opcode_d)
    );

writefirst_reg #(
    .width(32)
)
opcode_l2m(
    .clk(clk),
    .we(opin_l2),
    .clear(ack_l2),
    .in(opcodein_l2),
    .out(opcode_l2)
    );
endmodule