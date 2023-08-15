//2bit计数器
module transformer_2bit (
    input       [1:0] crt,
    output reg  [1:0] nxt,
    input       taken
);
    parameter S_NTK=2'b00,W_NTK=2'b01,W_TAK=2'b10,S_TAK = 2'b11;

    always @(*) begin
        case(crt)
            S_NTK: begin
                if(taken)   nxt = W_NTK;
                else        nxt = S_NTK;
            end
            W_NTK: begin
                if(taken)   nxt = W_TAK;
                else        nxt = S_NTK;
            end
            W_TAK: begin
                if(taken)   nxt = S_TAK;
                else        nxt = W_NTK;
            end
            S_TAK: begin
                if(taken)   nxt = S_TAK;
                else        nxt = W_TAK;
            end
        endcase
    end
endmodule
