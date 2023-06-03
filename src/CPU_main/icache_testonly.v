module icache (
    input      clk,rstn,
    output reg icache_valid_reg,
    input      [31:0]pc,
    output reg [63:0]ir_reg,
    output reg flag_reg
);
    reg [63:0]ir;
    reg flag,icache_valid;
    always @(posedge clk,negedge rstn) begin
        if(!rstn) ir_reg<=0;
        else ir_reg<=ir;
    end
    always @(posedge clk,negedge rstn) begin
        if(!rstn) flag_reg<=0;
        else flag_reg<=flag;
    end
    always @(posedge clk,negedge rstn) begin
        if(!rstn) icache_valid_reg<=0;
        else icache_valid_reg<=icache_valid;
    end
    always @(*) begin
        case (pc)
        //0 4 8 12 16 20 24
        //r1++ r3++ 
        //r1++ r3++
        //r1++ 
        //r5=r1+1 
        //r5=r3+1
            0: begin ir='b0000001010_000000000001_00001_00001_0000001010_000000000001_00011_00011;flag=1;icache_valid<=1;end
            4: begin ir='b0000001010_000000000001_00011_00011_0000001010_000000000001_00001_00001;flag=0;icache_valid<=1;end
            8: begin ir='b0000001010_000000000001_00001_00001_0000001010_000000000001_00011_00011;flag=1;icache_valid<=1;end
            12: begin ir='b0000001010_000000000001_00011_00011_0000001010_000000000001_00001_00001;flag=0;icache_valid<=1;end
            16: begin ir='b0000001010_000000000001_00001_00001_0000001010_000000000001_00001_00101;flag=1;icache_valid<=1;end
            20: begin ir='b0000001010_000000000001_00001_00101_0000001010_000000000001_00011_00101;flag=0;icache_valid<=1;end
            24: begin ir='b0000001010_000000000001_00011_00101_0000001010_000000000000_00000_00000;flag=1;icache_valid<=1;end
            28: begin ir='b0000001010_000000000000_00000_00000_0000001010_000000000000_00000_00000;flag=0;icache_valid<=1;end
            default: begin ir='b0000001010_000000000001_00000_00000_0000001010_000000000001_00000_00000;flag=0;icache_valid<=1;end
        endcase
    end
endmodule //icache
