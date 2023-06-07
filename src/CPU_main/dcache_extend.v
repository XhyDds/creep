module dcache_extend (
    input [31:0]ctr_exe0_exe1_1,dout_dcache_pipeline,
    input [1:0]addr_pipeline_dcache_reg,
    output reg [31:0]dout_dcache_pipeline_extend
);
    wire [3:0]type1=ctr_exe0_exe1_1[3:0];
    wire [4:0]subtype=ctr_exe0_exe1_1[11:7];
    wire [15:0]dout16=addr_pipeline_dcache_reg[1]?dout_dcache_pipeline[15:0]:dout_dcache_pipeline[31:16];
    reg [7:0]dout8;
    always @(*) begin
        dout8=0;
        case (addr_pipeline_dcache_reg[1:0])
            'b00: dout8=dout_dcache_pipeline[31:24];
            'b01: dout8=dout_dcache_pipeline[23:16];
            'b10: dout8=dout_dcache_pipeline[15:8];
            'b11: dout8=dout_dcache_pipeline[7:0];
        endcase
    end

    always @(*) begin
        dout_dcache_pipeline_extend=0;
        if(type1==5)
            case (subtype)
                0: dout_dcache_pipeline_extend=dout_dcache_pipeline;
                1: dout_dcache_pipeline_extend={{16{dout16[15]}},dout16};
                2: dout_dcache_pipeline_extend={{24{dout16[15]}},dout8};
                6: dout_dcache_pipeline_extend={16'b0,dout16};
                7: dout_dcache_pipeline_extend={24'b0,dout8};
            endcase
        else if(type1==6)
            case (subtype)
                0: dout_dcache_pipeline_extend={{16{dout16[15]}},dout16};
                1: dout_dcache_pipeline_extend={{24{dout16[15]}},dout8};
            endcase
    end
endmodule //dcache_extend
