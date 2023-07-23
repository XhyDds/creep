module cache_ctr (
    input        [31:0]rrj1_forward,imm_reg_exe0_1,ctr_reg_exe0_1,rrd1_forward,
    input        [15:0]excp_arg_reg_exe0_1_excp,
    output  reg  [31:0]addr_pipeline_dcache,
    output  reg  [31:0]din_pipeline_dcache,
    output  reg  type_pipeline_dcache, //0-read 1-write
    output  reg  pipeline_dcache_valid,
    output  reg  ifcacop_ibar,
    output  reg  [3:0]pipeline_dcache_wstrb, //字节处理位
    output  reg  [31:0]pipeline_cache_opcode, //cache操作//?????
    output  reg  pipeline_dcache_opflag, //0-正常访存 1-cache操作
    output  reg  pipeline_icache_opflag, //0-正常访存 1-cache操作
    output  reg  pipeline_l2cache_opflag //0-正常访存 1-cache操作
);
    wire [3:0]type_=ctr_reg_exe0_1[3:0];
    wire [4:0]subtype=ctr_reg_exe0_1[11:7];
    always @(*) begin
        addr_pipeline_dcache=rrj1_forward+imm_reg_exe0_1;
        din_pipeline_dcache=0;
        type_pipeline_dcache=ctr_reg_exe0_1[5];
        pipeline_dcache_valid=(type_==5)|(type_==6)|(type_==9);
        pipeline_dcache_wstrb=0;
        pipeline_dcache_opflag=0;
        pipeline_cache_opcode=0;
        pipeline_icache_opflag=0;
        pipeline_l2cache_opflag=0;
        ifcacop_ibar=0;
        if(type_==5)
            case (subtype)//for dcache, 0~2:load, 3~5:store, 6~7:load, 8:ibar
                0: 
                begin 
                    case (addr_pipeline_dcache[1:0])//小尾端？
                        2'b00:pipeline_dcache_wstrb=4'b0001;
                        2'b01:pipeline_dcache_wstrb=4'b0010;
                        2'b10:pipeline_dcache_wstrb=4'b0100;
                        2'b11:pipeline_dcache_wstrb=4'b1000;
                    endcase
                end
                1: 
                begin 
                    case (addr_pipeline_dcache[1:0])//小尾端？
                        2'b00:begin pipeline_dcache_wstrb=4'b0011; end
                        2'b10:begin pipeline_dcache_wstrb=4'b1100; end
                        default pipeline_dcache_wstrb=0;
                    endcase
                end
                2: 
                begin 
                    pipeline_dcache_wstrb='b1111;
                end
                3: 
                begin 
                    case (addr_pipeline_dcache[1:0])//小尾端？
                        2'b00:begin 
                            pipeline_dcache_wstrb=4'b0001;
                            din_pipeline_dcache={24'b0,rrd1_forward[7:0]}; 
                        end
                        2'b01:begin 
                            pipeline_dcache_wstrb=4'b0010; 
                            din_pipeline_dcache={16'b0,rrd1_forward[7:0],8'b0}; 
                        end
                        2'b10:begin 
                            pipeline_dcache_wstrb=4'b0100; 
                            din_pipeline_dcache={8'b0,rrd1_forward[7:0],16'b0}; 
                        end
                        2'b11:begin 
                            pipeline_dcache_wstrb=4'b1000; 
                            din_pipeline_dcache={rrd1_forward[7:0],24'b0}; 
                        end
                    endcase
                end
                4: 
                begin 
                    case (addr_pipeline_dcache[1:0])//小尾端？
                        2'b00:begin 
                            pipeline_dcache_wstrb=4'b0011; 
                            din_pipeline_dcache={16'b0,rrd1_forward[15:0]}; 
                        end
                        2'b10:begin 
                            pipeline_dcache_wstrb=4'b1100; 
                            din_pipeline_dcache={rrd1_forward[15:0],16'b0}; 
                        end
                        default pipeline_dcache_wstrb=0;
                    endcase
                end
                5: 
                begin 
                    din_pipeline_dcache=rrd1_forward; pipeline_dcache_wstrb='b1111;
                end
                6: 
                begin 
                    case (addr_pipeline_dcache[1:0])//小尾端？
                        2'b00:pipeline_dcache_wstrb=4'b0001;
                        2'b01:pipeline_dcache_wstrb=4'b0010;
                        2'b10:pipeline_dcache_wstrb=4'b0100;
                        2'b11:pipeline_dcache_wstrb=4'b1000;
                    endcase 
                    end
                7: 
                begin 
                    pipeline_dcache_wstrb=0;
                    case (addr_pipeline_dcache[1:0])//小尾端？
                        2'b00:begin pipeline_dcache_wstrb=4'b0011; end
                        2'b10:begin pipeline_dcache_wstrb=4'b1100; end
                        default pipeline_dcache_wstrb=0;
                    endcase 
                end
                8: begin //cacop
                    case (excp_arg_reg_exe0_1_excp[2:0])
                        0: pipeline_icache_opflag=1;
                        1: pipeline_dcache_opflag=1;
                        2: pipeline_l2cache_opflag=1;
                    endcase
                    pipeline_cache_opcode={1'b0,15'b0,excp_arg_reg_exe0_1_excp};
                    ifcacop_ibar=1;
                end
            endcase
        else if(type_==6)
            case (subtype)//fot yuanzi, 0:load, 1:store
                11: 
                begin 
                    pipeline_dcache_wstrb='b1111; 
                end
                12: 
                begin 
                    din_pipeline_dcache=rrd1_forward; 
                    pipeline_dcache_wstrb='b1111; 
                end
            endcase
        else if(type_==9) begin //ibar
            pipeline_cache_opcode={1'b1,31'b0};
            pipeline_icache_opflag=1;
            ifcacop_ibar=1;
        end
    end
endmodule
