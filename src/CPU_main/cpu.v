module cpu (
    input clk,rstn
);
    reg [31:0]npc;
    wire [1:0]pcsrc_exe1_wb;
    wire ifpriv;
    reg [31:0]pc,wb_data,
    ctr_id_reg_0,ctr_id_reg_1,
    ctr_reg_exe0_0,ctr_reg_exe0_1,
    ctr_exe0_exe1_0,ctr_exe0_exe1_1,
    ctr_exe1_wb_0,ctr_exe1_wb_1,
    pc_id_reg_0,pc_id_reg_1,
    // pc_fifo_id,
    pc_if1_fifo,
    pc_if0_if1,
    pc_reg_exe0_0,pc_reg_exe0_1,
    aluresult_exe0_exe1_0,aluresult_exe0_exe1_1,
    result_exe1_wb_0,result_exe1_wb_1,
    rrk_reg_exe0_0,rrj_reg_exe0_0,
    rrk_reg_exe0_1,rrj_reg_exe0_1,
    rrd_reg_exe0_0,rrd_reg_exe0_1,
    imm_reg_exe0_0,imm_reg_exe0_1,
    rd_exe1_wb_0,rd_exe1_wb_1,
    excp_arg_id_reg_0,excp_arg_id_reg_1,
    
    imm_id_reg_0,imm_id_reg_1,
    excp_arg_reg_exe0_0,excp_arg_reg_exe0_1;

    wire [31:0]wb_pc;
    reg [4:0]rk_reg_exe0_0,rk_reg_exe0_1,
    rj_reg_exe0_0,rj_reg_exe0_1,
    rd_reg_exe0_0,rd_reg_exe0_1,
    rd_id_reg_0,rd_id_reg_1,
    rk_id_reg_0,rk_id_reg_1,
    rj_id_reg_0,rj_id_reg_1,
    rd_exe0_exe1_0,rd_exe0_exe1_1;
    
    
    wire [31:0]	pc0;
    wire [31:0]	pc1;
    wire [31:0]	ir0;
    wire [31:0]	ir1;
    wire 	if0;
    wire 	if1;

    fetch_buffer u_fetch_buffer(
        //ports
        .pc(pc_if1_fifo),
        .clk     		( clk     		),
        .rstn    		( rstn    		),
        .if0     		( if0     		),
        .if1     		( if1     		),
        .irin    		( irin    		),
        .flag    		( flag    		),
        .ir0 		    ( ir0 	    	),
        .ir1 		    ( ir1 	    	),
        .pc0(pc0),
        .pc1(pc1)
    );

    wire [31:0]	control0;
    wire [4:0]	rk0;
    wire [4:0]	rj0;
    wire [4:0]	rd0;
    wire [31:0]	imm0;
    wire [15:0]	excp_arg0;
    // wire 	INE0;

    decoder u_decoder0(
        //ports
        .ir       		( ir0 	    	    ),
        .control  		( control0  		),
        .rk       		( rk0       		),
        .rj       		( rj0       		),
        .rd       		( rd0       		),
        .imm      		( imm0      		),
        .excp_arg 		( excp_arg0 		)
        // .INE      		( INE0      		)
    );

    wire [31:0]	control1;
    wire [4:0]	rk1;
    wire [4:0]	rj1;
    wire [4:0]	rd1;
    wire [31:0]	imm1;
    wire [15:0]	excp_arg1;
    // wire 	INE1;

    decoder u_decoder1(
        //ports
        .ir       		( ir1        	    ),
        .control  		( control1  		),
        .rk       		( rk1       		),
        .rj       		( rj1       		),
        .rd       		( rd1       		),
        .imm      		( imm1      		),
        .excp_arg 		( excp_arg1 		)
        // .INE      		( INE1      		)
    );

    wire [4:0]	rk00;
    wire [4:0]	rk11;
    wire [4:0]	rj00;
    wire [4:0]	rj11;
    wire [4:0]	rd00;
    wire [4:0]	rd11;
    wire [31:0]	imm00;
    wire [31:0]	imm11;
    wire [31:0]	control00;
    wire [31:0]	control11;
    wire [15:0]	excp_arg00;
    wire [15:0]	excp_arg11;
    // wire 	INE00;
    // wire 	INE11;

    dispatcher u_dispatcher(
        //ports
        .imm0       		( imm0       		),
        .imm1       		( imm1       		),
        .control0   		( control0   		),
        .control1   		( control1   		),
        .rk0        		( rk0        		),
        .rk1        		( rk1        		),
        .rj0        		( rj0        		),
        .rj1        		( rj1        		),
        .rd0        		( rd0        		),
        .rd1        		( rd1        		),
        .excp_arg0  		( excp_arg0  		),
        .excp_arg1  		( excp_arg1  		),
        // .INE0       		( INE0       		),
        // .INE1       		( INE1       		),
        .rk00       		( rk00       		),
        .rk11       		( rk11       		),
        .rj00       		( rj00       		),
        .rj11       		( rj11       		),
        .rd00       		( rd00       		),
        .rd11       		( rd11       		),
        .imm00      		( imm00      		),
        .imm11      		( imm11      		),
        .control00  		( control00  		),
        .control11  		( control11  		),
        .excp_arg00 		( excp_arg00 		),
        .excp_arg11 		( excp_arg11 		),
        // .INE00      		( INE00      		),
        // .INE11      		( INE11      		),
        .if0        		( if0        		),
        .if1        		( if1        		)
    );

    wire [31:0]	rrk0;
    wire [31:0]	rrk1;
    wire [31:0]	rrj0;
    wire [31:0]	rrj1;
    wire [31:0]	rrd0;
    wire [31:0]	rrd1;
    wire [31:0]	wb_data0;
    wire [31:0]	wb_data1;
    wire [4:0]	wb_addr0;
    wire [4:0]	wb_addr1;

    register_file u_register_file(
        //ports
        .clk      		( clk      		),
        .ifwb0    		( ifwb0    		),
        .ifwb1    		( ifwb1    		),
        .wb_data0 		( wb_data0 		),
        .wb_addr0 		( wb_addr0 		),
        .wb_data1 		( wb_data1 		),
        .wb_addr1 		( wb_addr1 		),
        .rk00     		( rk_id_reg_0     		),
        .rk11     		( rk_id_reg_1     		),
        .rj00     		( rj_id_reg_0     		),
        .rj11     		( rj_id_reg_1     		),
        .rd00     		( rd_id_reg_0     		),
        .rd11     		( rd_id_reg_1     		),
        .rrk0     		( rrk0     		),
        .rrk1     		( rrk1     		),
        .rrj0     		( rrj0     		),
        .rrj1     		( rrj1     		),
        .rrd0     		( rrd0     		),
        .rrd1     		( rrd1     		)
    );

    wire [31:0]	alu1_0;

    alusrc u_alusrc1_0(
        //ports
        .a      		( pc_id_reg_0      		),
        .b      		( rj_id_reg_0      		),
        .alusrc 		( ctr_reg_exe0_0[15:14] 	),
        .alu    		( alu1_0    		)
    );

    wire [31:0]	alu2_0;

    alusrc u_alusrc2_0(
        //ports
        .a      		( imm_id_reg_0      		),
        .b      		( rk_id_reg_0      		),
        .alusrc 		( ctr_reg_exe0_0[13:12] 	),
        .alu    		( alu2_0    		)
    );

    wire [31:0]	alu1_1;

    alusrc u_alusrc1_1(
        //ports
        .a      		( pc_id_reg_1      		),
        .b      		( rj_id_reg_1      		),
        .alusrc 		( ctr_reg_exe0_1[15:14] 	),
        .alu    		( alu1_1    		)
    );

    wire [31:0]	alu2_1;

    alusrc u_alusrc2_1(
        //ports
        .a      		( imm_id_reg_1      		),
        .b      		( rk_id_reg_1      		),
        .alusrc 		( ctr_reg_exe0_1[13:12] 	),
        .alu    		( alu2_1    		)
    );

    wire [31:0]	aluresult0;
    wire 	zero0;

    alu u_alu0(
        //ports
        .alu1      		( alu1_0      		),
        .alu2      		( alu2_0      		),
        .ctr       		( ctr       		),
        .aluresult 		( aluresult0		),
        .zero      		( zero0     		)
    );

    wire [31:0]	aluresult1;
    wire 	zero1;

    alu u_alu1(
        //ports
        .alu1      		( alu1_1      		),
        .alu2      		( alu2_1      		),
        .ctr       		( ctr       		),
        .aluresult 		( aluresult1		),
        .zero      		( zero1     		)
    );

    wire [31:0]	mulresult0;

    mul u_mul0(
        //ports
        .rj        		( rrj_reg_exe0_0        		),
        .rk        		( rrk_reg_exe0_0        		),
        .ctr       		( ctr_reg_exe0_0       		),
        .mulresult 		( mulresult0		)
    );

    wire [31:0]	mulresult1;

    mul u_mul1(
        //ports
        .rj        		( rrj_reg_exe0_1        		),
        .rk        		( rrk_reg_exe0_1        		),
        .ctr       		( ctr_reg_exe0_1       		),
        .mulresult 		( mulresult1 		)
    );


    wire [31:0]	divresult0;

    div u_div0(
        //ports
        .rj        		( rrj_reg_exe0_0        		),
        .rk        		( rrk_reg_exe0_0        		),
        .ctr       		( ctr_reg_exe0_0       		),
        .divresult 		( divresult0 		)
    );

    wire [31:0]	divresult1;

    div u_div1(
        //ports
        .rj        		( rrj_reg_exe0_1       		),
        .rk        		( rrk_reg_exe0_1       		),
        .ctr       		( ctr_reg_exe0_1       		),
        .divresult 		( divresult1 		)
    );

    wire 	ifbr0;
    wire [31:0]	brresult0;

    br u_br0(
        //ports
        .ctr      		( ctr_reg_exe0_0      		),
        .rrj      		( rrj_reg_exe0_0      		),
        .rrd      		( rrd_reg_exe0_0      		),
        .pc       		( pc_reg_exe0_0       		),
        .imm      		( imm_reg_exe0_0      		),
        .zero     		( zero0     		),
        .ifbr     		( ifbr0    		),
        .brresult 		( brresult0 	)
    );

    wire 	ifbr1;
    wire [31:0]	brresult1;

    br u_br1(
        //ports
        .ctr      		( ctr_reg_exe0_1      		),
        .rrj      		( rrj_reg_exe0_1      		),
        .rrd      		( rrd_reg_exe0_1      		),
        .pc       		( pc_reg_exe0_1       		),
        .imm      		( imm_reg_exe0_1      		),
        .zero     		( zero1     		),
        .ifbr     		( ifbr1    		),
        .brresult 		( brresult1		)
    );

    writeback u_writeback(
        //ports
        .result_exe1_wb_0 		( result_exe1_wb_0 		),
        .result_exe1_wb_1 		( result_exe1_wb_1 		),
        .ctr_exe1_wb_0    		( ctr_exe1_wb_0    		),
        .ctr_exe1_wb_1    		( ctr_exe1_wb_1    		),
        .rd_exe1_wb_0     		( rd_exe1_wb_0     		),
        .rd_exe1_wb_1     		( rd_exe1_wb_1     		),
        .wb_data0         		( wb_data0         		),
        .wb_data1         		( wb_data1         		),
        .wb_addr0         		( wb_addr0         		),
        .wb_addr1         		( wb_addr1         		)
    );

    


    always @(posedge clk,negedge rstn) begin
        if(!rstn) pc<=0;
        else pc<=npc;
    end

    always @(*) begin
        if(ifpriv) npc=wb_pc;
        else if(ifbr1) npc=aluresult_exe0_exe1_1;
        else if(ifbr0) npc=aluresult_exe0_exe1_0;
        else if(pc[2]) npc=pc+4;
        else npc=pc+8;
        //0000 0004 0008 000C 0010
        //0000 0100 1000 1100 10000
    end

    //IF0-IF1
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            pc_if0_if1<=0;
        end
        else begin
            pc_if0_if1<=pc;
        end
    end

    //IF1-FIFO
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            pc_if1_fifo<=0;
        end
        else begin
            pc_if1_fifo<=pc_if0_if1;
        end
    end

    // //FIFO-ID
    // always @(posedge clk or negedge rstn) begin
    //     if(!rstn) begin
    //         pc_fifo_id<=0;
    //     end
    //     else begin
    //         pc_fifo_id<=pc_if1_fifo;
    //     end
    // end

    //ID-REG
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            ctr_id_reg_0 <= 0;
            ctr_id_reg_1 <= 0;
            excp_arg_id_reg_0<=0;
            excp_arg_id_reg_1<=0;
            imm_id_reg_0<=0;
            imm_id_reg_1<=0;
            rk_id_reg_0<=0;
            rk_id_reg_1<=0;
            rj_id_reg_0<=0;
            rj_id_reg_1<=0;
            rd_id_reg_0<=0;
            rd_id_reg_1<=0;
            pc_id_reg_0<=0;
            pc_id_reg_1<=0;
        end
        else begin
            ctr_id_reg_0 <= control00;
            ctr_id_reg_1 <= control11;
            excp_arg_id_reg_0<=excp_arg00;
            excp_arg_id_reg_1<=excp_arg11;
            imm_id_reg_0<=imm00;
            imm_id_reg_1<=imm11;
            rk_id_reg_0<=rk00;
            rk_id_reg_1<=rk11;
            rj_id_reg_0<=rj00;
            rj_id_reg_1<=rj11;
            rd_id_reg_0<=rd00;
            rd_id_reg_1<=rd11;
            pc_id_reg_0<=pc0;
            pc_id_reg_1<=pc1;
        end
    end

    //REG-EXE0
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            ctr_reg_exe0_0 <= 0;
            ctr_reg_exe0_1 <= 0;
            excp_arg_reg_exe0_0<=0;
            excp_arg_reg_exe0_1<=0;
            imm_reg_exe0_0<=0;
            imm_reg_exe0_1<=0;
            rk_reg_exe0_0<=0;
            rk_reg_exe0_1<=0;
            rj_reg_exe0_0<=0;
            rj_reg_exe0_1<=0;
            rd_reg_exe0_0<=0;
            rd_reg_exe0_1<=0;
            rrk_reg_exe0_0<=0;
            rrk_reg_exe0_1<=0;
            rrj_reg_exe0_0<=0;
            rrj_reg_exe0_1<=0;
            rrd_reg_exe0_0<=0;
            rrd_reg_exe0_1<=0;
        end
        else begin
            ctr_reg_exe0_0 <= ctr_id_reg_0;
            ctr_reg_exe0_1 <= ctr_id_reg_1;
            excp_arg_reg_exe0_0<=excp_arg_id_reg_0;
            excp_arg_reg_exe0_1<=excp_arg_id_reg_1;
            imm_reg_exe0_0<=imm_id_reg_0;
            imm_reg_exe0_1<=imm_id_reg_1;
            rrk_reg_exe0_0<=rrk0;
            rrk_reg_exe0_1<=rrk1;
            rrj_reg_exe0_0<=rrj0;
            rrj_reg_exe0_1<=rrj1;
            rrd_reg_exe0_0<=rrd0;
            rrd_reg_exe0_1<=rrd1;
            rk_reg_exe0_0<=rk0;
            rk_reg_exe0_1<=rk1;
            rj_reg_exe0_0<=rj0;
            rj_reg_exe0_1<=rj1;
            rd_reg_exe0_0<=rd0;
            rd_reg_exe0_1<=rd1;
        end
    end

    //EXE0-EXE1
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            ctr_exe0_exe1_0 <= 0;
            ctr_exe0_exe1_1 <= 0;
            rd_exe0_exe1_0<=0;
            rd_exe0_exe1_1<=0;
            aluresult_exe0_exe1_0<=0;
            aluresult_exe0_exe1_1<=0;
        end
        else begin
            ctr_exe0_exe1_0 <= ctr_id_reg_0;
            ctr_exe0_exe1_1 <= ctr_id_reg_1;
            rd_exe0_exe1_0<=rd_reg_exe0_0;
            rd_exe0_exe1_1<=rd_reg_exe0_1;
            aluresult_exe0_exe1_0<=aluresult0;
            aluresult_exe0_exe1_1<=aluresult1;
        end
    end

    //EXE1-WB
    reg [31:0]result0,result1;
    //0:alu, 1:br, 2:div, 3:priv, 4:mul, 5:dcache, 6:priv+dcache, 7:RDCNT, 8:alu+br
    always @(*) begin
        result0=0;
        result1=0;
        case (ctr_exe0_exe1_0[3:0])
            0: result0=aluresult_exe0_exe1_0;
            1: ;
            2: result0=divresult0;
            // 3: result0=privresult0;
            4: result0=mulresult0;
            // 5: result0=dcacheresult0;
            // 6: result0=dcacheresult0;
            7: ;
            8: result0=aluresult_exe0_exe1_0;
        endcase
        case (ctr_exe0_exe1_1[3:0])
            0: result1=aluresult_exe0_exe1_1;
            1: ;
            2: result1=divresult1;
            // 3: result1=privresult1;
            4: result1=mulresult1;
            // 5: result1=dcacheresult1;
            // 6: result1=dcacheresult1;
            7: ;
            8: result1=aluresult_exe0_exe1_1;
        endcase
    end
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            ctr_exe1_wb_0 <= 0;
            ctr_exe1_wb_1 <= 0;
            rd_exe1_wb_0<=0;
            rd_exe1_wb_1<=0;
            result_exe1_wb_0<=0;
            result_exe1_wb_1<=0;
        end
        else begin
            ctr_exe1_wb_0 <= ctr_id_reg_0;
            ctr_exe1_wb_1 <= ctr_id_reg_1;
            rd_exe1_wb_0<=rd_reg_exe0_0;
            rd_exe1_wb_1<=rd_reg_exe0_1;
            result_exe1_wb_0<=result0;
            result_exe1_wb_1<=result1;
        end
    end

    // wire [31:0]	addr_pipeline_dcache;
    // wire [31:0]	din_pipeline_dcache;
    // wire 	type_pipeline_dcache;
    // wire 	pipeline_dcache_vaild;
    // wire [3:0]	pipeline_dcache_wstrb;
    // wire [31:0]	pipeline_dcache_opcode;
    // wire 	pipeline_dcache_opflag;
    // wire [31:0]	pipeline_dcache_ctrl;

    // dcache_ctr u_dcache_ctr(
    //     //ports
    //     .rj                     		( rj                     		),
    //     .rk                     		( rk                     		),
    //     .ctr                    		( ctr                    		),
    //     .addr_pipeline_dcache   		( addr_pipeline_dcache   		),
    //     .din_pipeline_dcache    		( din_pipeline_dcache    		),
    //     .type_pipeline_dcache   		( type_pipeline_dcache   		),
    //     .pipeline_dcache_vaild  		( pipeline_dcache_vaild  		),
    //     .pipeline_dcache_wstrb  		( pipeline_dcache_wstrb  		),
    //     .pipeline_dcache_opcode 		( pipeline_dcache_opcode 		),
    //     .pipeline_dcache_opflag 		( pipeline_dcache_opflag 		),
    //     .pipeline_dcache_ctrl   		( pipeline_dcache_ctrl   		)
    // );

    //IM
    // dist_mem_gen_0(.a(addr),.d(din),.dpra((pc-'h00003000)>>2),.clk(clk_ld),.we(we_im),.spo(dout_im),.dpo(irf));
    
    //DM
    // wire [31:0]dpo1,spo1;
    // dist_mem_gen_1(.a(we_dm?addr:y>>2),.d(we_dm?din:mdw),.dpra(we_dm?y>>2:addr),.clk(clk_ld),.we(we_dm|ctrm[3]),.spo(spo1),.dpo(dpo1));
    // assign dout_dm=we_dm?spo1:dpo1;
    // assign readdata=ctrm[9]?(we_dm?dpo1:spo1):0;


endmodule