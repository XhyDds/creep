module ibar (
    input      [31:0]ctr,
    output     ifibar
);
    wire [3:0]type_ = ctr[3:0];
    assign ifibar = (type_==9);
endmodule //ibar
