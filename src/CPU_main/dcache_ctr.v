module dcache_ctr (
    input        [31:0]rrj1_forward,imm_reg_exe0_1,ctr_reg_exe0_1,rd_reg_exe0_1,excp_arg_reg_exe0_1_excp,
    // output  ALE,
    output  reg  [31:0]addr_pipeline_dcache,
    output  reg  [31:0]din_pipeline_dcache,
    output  reg  type_pipeline_dcache,//0-read 1-write
    output  reg  pipeline_dcache_vaild,
    output  reg  [3:0]pipeline_dcache_wstrb,//字节处理位
    output  reg  [31:0]pipeline_dcache_opcode,//cache操作//?????
    output  reg  pipeline_dcache_opflag//0-正常访存 1-cache操作
);
    wire [3:0]type_=ctr_reg_exe0_1[3:0];
    wire [4:0]subtype=ctr_reg_exe0_1[11:7];
    always @(*) begin
        addr_pipeline_dcache=rrj1_forward+imm_reg_exe0_1;
        din_pipeline_dcache=0;
        // type_pipeline_dcache=0;
        type_pipeline_dcache=ctr_reg_exe0_1[5];
        // pipeline_dcache_vaild=0;
        pipeline_dcache_vaild=(type_==5)|(type_==6);
        pipeline_dcache_wstrb=0;
        pipeline_dcache_opflag=0;
        pipeline_dcache_opcode=0;
        if(type_==5)
            case (subtype)//for dcache, 0~2:load, 3~5:store, 6~7:load, 8:ibar
                0: 
                begin 
                    // pipeline_dcache_vaild=1;
                    // type_pipeline_dcache=0;
                    case (addr_pipeline_dcache[1:0])//小尾端？
                        2'b00:pipeline_dcache_wstrb=4'b0001;
                        2'b01:pipeline_dcache_wstrb=4'b0010;
                        2'b10:pipeline_dcache_wstrb=4'b0100;
                        2'b11:pipeline_dcache_wstrb=4'b1000;
                    endcase
                end
                1: 
                begin 
                    // pipeline_dcache_vaild=1;
                    // type_pipeline_dcache=0;
                    case (addr_pipeline_dcache[1:0])//小尾端？
                        2'b00:begin pipeline_dcache_wstrb=4'b0011; end
                        2'b10:begin pipeline_dcache_wstrb=4'b1100; end
                        default pipeline_dcache_wstrb=0;
                    endcase
                end
                2: 
                begin 
                    // pipeline_dcache_vaild=1;
                    // type_pipeline_dcache=0;
                    pipeline_dcache_wstrb='b1111;
                end
                3: 
                begin 
                    // pipeline_dcache_vaild=1;
                    // type_pipeline_dcache=1;
                    din_pipeline_dcache={24'b0,rd_reg_exe0_1[7:0]};
                    case (addr_pipeline_dcache[1:0])//小尾端？
                        2'b00:pipeline_dcache_wstrb=4'b0001;
                        2'b01:pipeline_dcache_wstrb=4'b0010;
                        2'b10:pipeline_dcache_wstrb=4'b0100;
                        2'b11:pipeline_dcache_wstrb=4'b1000;
                    endcase
                end
                4: 
                begin 
                    // type_pipeline_dcache=1;
                    // pipeline_dcache_vaild=1;
                    din_pipeline_dcache={16'b0,rd_reg_exe0_1[15:0]}; 
                    case (addr_pipeline_dcache[1:0])//小尾端？
                        2'b00:begin pipeline_dcache_wstrb=4'b0011; end
                        2'b10:begin pipeline_dcache_wstrb=4'b1100; end
                        default pipeline_dcache_wstrb=0;
                    endcase
                end
                5: 
                begin 
                    // pipeline_dcache_vaild=1;
                    // type_pipeline_dcache=1;
                    din_pipeline_dcache=rd_reg_exe0_1; pipeline_dcache_wstrb='b1111;
                end
                6: 
                begin 
                    // pipeline_dcache_vaild=1;
                    // type_pipeline_dcache=0;
                    case (addr_pipeline_dcache[1:0])//小尾端？
                        2'b00:pipeline_dcache_wstrb=4'b0001;
                        2'b01:pipeline_dcache_wstrb=4'b0010;
                        2'b10:pipeline_dcache_wstrb=4'b0100;
                        2'b11:pipeline_dcache_wstrb=4'b1000;
                    endcase 
                    end
                7: 
                begin 
                    // pipeline_dcache_vaild=1;
                    // type_pipeline_dcache=0;
                    pipeline_dcache_wstrb=0;
                    case (addr_pipeline_dcache[1:0])//小尾端？
                        2'b00:begin pipeline_dcache_wstrb=4'b0011; end
                        2'b10:begin pipeline_dcache_wstrb=4'b1100; end
                        default pipeline_dcache_wstrb=0;
                    endcase 
                end
                8: begin 
                    // pipeline_dcache_vaild=1;
                    pipeline_dcache_opflag=1;
                end
                9: begin 
                    // pipeline_dcache_vaild=1;
                    pipeline_dcache_opflag=1;
                    pipeline_dcache_opcode=excp_arg_reg_exe0_1_excp;
                end
            endcase
        else if(type_==6)
            case (subtype)//fot yuanzi, 0:load, 1:store
                0: 
                begin 
                    // pipeline_dcache_vaild=1;
                    // type_pipeline_dcache=0;
                    pipeline_dcache_wstrb='b1111; 
                end
                1: 
                begin 
                    // pipeline_dcache_vaild=1;
                    // type_pipeline_dcache=1;
                    din_pipeline_dcache=rd_reg_exe0_1; pipeline_dcache_wstrb='b1111; 
                end
            endcase
    end
endmodule
