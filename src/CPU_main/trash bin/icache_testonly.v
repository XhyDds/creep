module icache_testonly (
    input      clk,rstn,flush,stall,
    output reg icache_valid_reg,
    input      [31:0]pc,
    output reg [63:0]ir_reg,
    output reg flag_reg
);
    reg [63:0]ir;
    reg flag,icache_valid;
    always @(posedge clk,negedge rstn) begin
        if(!rstn|flush) ir_reg<=0;
        else if(!stall) ir_reg<=ir;
    end
    always @(posedge clk,negedge rstn) begin
        if(!rstn|flush) flag_reg<=0;
        else if(!stall) flag_reg<=flag;
    end
    always @(posedge clk,negedge rstn) begin
        if(!rstn|flush) icache_valid_reg<=0;
        else if(!stall) icache_valid_reg<=icache_valid;
    end

    always @(*) begin
        case (pc)
            //0:alu, 1:br, 2:div, 3:priv, 4:mul, 5:dcache, 6:priv+dcache, 7:RDCNT, 8:alu+br
            //addi r1,r1,4 addi r2,r2,1
                //r1=4 r2=1
            //ld.w r3,r2,1 bne r2,r1,-2
                //r2=0 ALE pc=0
                    //r2=4,r3=00000084 1000_0100
            //mulh.w r5,r2,r3 mul.w r6,r2,r3
                //r5=0 r6=210
            //div.w r7,r3,r2 mod.w r8,r3,r2
                //r7=10_0001 21 r8=0
            //addi r8,r8,1 addi r8,r8,1
            0: begin ir=64'b0000001010_000000000100_00001_00001_0000001010_000000000001_00010_00010;flag=1;icache_valid=1;end
                4: begin ir=64'b0000001010_000000000001_00010_00010_0010100010_000000000001_00010_00011;flag=0;icache_valid=1;end
            8: begin ir=64'b0010100010_000000000001_00010_00011_010111_1111111111111110_00001_00010;flag=1;icache_valid=1;end
            16: begin ir=64'b00000000000111001_00011_00010_00101_00000000000111000_00011_00010_00110;flag=1;icache_valid=1;end
            24: begin ir=64'b00000000001000000_00010_00011_00111_00000000001000001_00010_00011_01000;flag=1;icache_valid=1;end
            default: begin ir=64'b0000001010_000000000001_01000_01000_0000001010_000000000001_01000_01000;flag=0;icache_valid=1;end
        endcase
    end


    // always @(*) begin
    //     case (pc)
    //         //0:alu, 1:br, 2:div, 3:priv, 4:mul, 5:dcache, 6:priv+dcache, 7:RDCNT, 8:alu+br
    //         //addi r1,r1,16
    //             //r1=10
    //         //ld.w r2,r3,1 
    //             //r2=0, ALE
    //         //ld.w r3,r1,0
    //             //r3=80000010
    //         //addi r2,r2,2
    //             //r2=2
    //         //ld.b r4,r3,1 mul.wh r5,r2,r3
    //             //r4=11 r5=ffffffff
    //         //addi r6,r6,1
    //             //r6=1
    //         //add r7,r4,r5 addi r8,r8,1
    //             //r7=10, r8=1
    //         0: begin ir='b0000001010_000000010000_00001_00001_0010100010_000000000001_00011_00010;flag=1;icache_valid=1;end
    //         8: begin ir='b0010100010_000000000000_00001_00011_0000001010_000000000010_00010_00010;flag=1;icache_valid=1;end
    //         16: begin ir='b0010100000_000000000001_00011_00100_00000000000111001_00011_00010_00101;flag=1;icache_valid=1;end
    //         24: begin ir='b0000001010_000000000001_00110_00110_00000000000100000_00100_00101_00111;flag=1;icache_valid=1;end
    //         default: begin ir='b0000001010_000000000001_01000_01000_0000001010_000000000001_01000_01000;flag=0;icache_valid=1;end
    //     endcase
    // end


    // always @(*) begin
    //     case (pc)
    //         //0 4 8 12 16 20 24
    //         //r1++ r3++ 
    //         //r1++ r3++
    //         //r1++ 
    //         //r5=r1+1 r5=r3+1
    //         //r8++ r8++ ...
    //         0: begin ir=64'b0000001010_000000000001_00001_00001_0000001010_000000000001_00011_00011;flag=1;icache_valid=1;end
    //         // 4: begin ir=64'b0000001010_000000000001_00011_00011_0000001010_000000000001_00001_00001;flag=0;icache_valid=1;end
    //         8: begin ir=64'b0000001010_000000000001_00001_00001_0000001010_000000000001_00011_00011;flag=1;icache_valid=1;end
    //         // 12: begin ir=64'b0000001010_000000000001_00011_00011_0000001010_000000000001_00001_00001;flag=0;icache_valid=1;end
    //         16: begin ir=64'b0000001010_000000000001_00001_00001_0000001010_000000000001_00001_00101;flag=1;icache_valid=1;end
    //         // 20: begin ir=64'b0000001010_000000000001_00001_00101_0000001010_000000000001_00011_00101;flag=0;icache_valid=1;end
    //         24: begin ir=64'b0000001010_000000000001_00011_00101_0000001010_000000000001_00100_00100;flag=1;icache_valid=1;end
    //         // 28: begin ir=64'b0000001010_000000000000_00000_00000_0000001010_000000000000_00000_00000;flag=0;icache_valid=1;end
    //         default: begin ir=64'b0000001010_000000000001_00100_00100_0000001010_000000000001_00100_00100;flag=0;icache_valid=1;end
    //     endcase
    // end
endmodule //icache_testonly
