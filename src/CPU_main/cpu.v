module core_top (
    input           aclk,
    input           aresetn,
    input    [ 7:0] intrpt, 

    //AXI interface 
    //read reqest
    output   [ 3:0] arid,
    output   [31:0] araddr,
    output   [ 7:0] arlen,
    output   [ 2:0] arsize,
    output   [ 1:0] arburst,
    output   [ 1:0] arlock,
    output   [ 3:0] arcache,
    output   [ 2:0] arprot,
    output          arvalid,
    input           arready,
    //read back
    input    [ 3:0] rid,
    input    [31:0] rdata,
    input    [ 1:0] rresp,
    input           rlast,
    input           rvalid,
    output          rready,
    //write request
    output   [ 3:0] awid,
    output   [31:0] awaddr,
    output   [ 7:0] awlen,
    output   [ 2:0] awsize,
    output   [ 1:0] awburst,
    output   [ 1:0] awlock,
    output   [ 3:0] awcache,
    output   [ 2:0] awprot,
    output          awvalid,
    input           awready,
    //write data
    output   [ 3:0] wid,
    output   [31:0] wdata,
    output   [ 3:0] wstrb,
    output          wlast,
    output          wvalid,
    input           wready,
    //write back
    input    [ 3:0] bid,
    input    [ 1:0] bresp,
    input           bvalid,
    output          bready,

    //debug
    input           break_point,
    input           infor_flag,
    input  [ 4:0]   reg_num,
    output          ws_valid,
    output [31:0]   rf_rdata,

    output [31:0] debug0_wb_pc,
    output [ 3:0] debug0_wb_rf_wen,
    output [ 4:0] debug0_wb_rf_wnum,
    output [31:0] debug0_wb_rf_wdata,
    output [31:0] debug0_wb_inst,

    output [31:0] debug1_wb_pc,
    output [ 3:0] debug1_wb_rf_wen,
    output [ 4:0] debug1_wb_rf_wnum,
    output [31:0] debug1_wb_rf_wdata,
    output [31:0] debug1_wb_inst
);
    wire clk=aclk;
    wire rstn=aresetn;
    parameter offset_width = 2;

    reg [31:0]pc,npc,
    ctr_id_reg_0,ctr_id_reg_1,ctr_reg_exe0_1_ALE,
    ctr_reg_exe0_0,ctr_reg_exe0_1,
    ctr_exe0_exe1_0,ctr_exe0_exe1_1,
    ctr_exe1_wb_0,ctr_exe1_wb_1,
    pc_id_reg_0,pc_id_reg_1,
    pc_if1_fifo,
    pc_if0_if1,
    pc_reg_exe0_0,pc_reg_exe0_1,
    pc_exe0_exe1_0,pc_exe0_exe1_1,
    pc_exe1_wb_0,pc_exe1_wb_1,
    aluresult_exe0_exe1_0,aluresult_exe0_exe1_1,
    result_exe1_wb_0,result_exe1_wb_1,
    rrk_reg_exe0_0,rrj_reg_exe0_0,
    rrk_reg_exe0_1,rrj_reg_exe0_1,
    rrd_reg_exe0_0,rrd_reg_exe0_1,
    imm_reg_exe0_0,imm_reg_exe0_1,
    imm_id_reg_0,imm_id_reg_1,
    ir_id_reg_0,ir_id_reg_1,
    ir_reg_exe0_0,ir_reg_exe0_1,
    ir_exe0_exe1_0,ir_exe0_exe1_1,
    ir_exe1_wb_0,ir_exe1_wb_1,
    addr_pipeline_dcache_reg;
    
    reg [15:0]excp_arg_reg_exe0_1,excp_arg_reg_exe0_1_excp,
    excp_arg_id_reg_0,excp_arg_id_reg_1;
    reg [15:0]excp_arg_exe0_exe1_1_excp=0;

    reg [63:0]ir_if1_fifo;
    reg [4:0]rd_exe1_wb_0,rd_exe1_wb_1,
    rk_reg_exe0_0,rk_reg_exe0_1,
    rj_reg_exe0_0,rj_reg_exe0_1,
    rd_reg_exe0_0,rd_reg_exe0_1,
    rd_id_reg_0,rd_id_reg_1,
    rk_id_reg_0,rk_id_reg_1,
    rj_id_reg_0,rj_id_reg_1,
    rd_exe0_exe1_0,rd_exe0_exe1_1;
    reg icache_valid_if1_fifo,flag_if1_fifo;
    
    //TLB
    wire tlbexcp=0,tlbcode=0,tlbsubcode=0;

    //PRIV
    wire ifbr_priv,LLbit;
    wire [1:0]PLV;
    wire [31:0]pc_priv;
    wire [31:0]privresult1;
    wire flush_priv,stall_priv;
    wire stall_priv_idle;

    wire ifbr0,ifbr1,ifibar0,ifibar1;
    wire stall_div0,stall_div1,stall_fetch_buffer;
    wire stall_dcache,stall_icache;//dcache_valid-ready?
    wire flush_if0_if1,flush_if1_fifo,flush_fifo_id,flush_id_reg0,flush_id_reg1,flush_reg_exe0_0,flush_reg_exe0_1,flush_exe0_exe1_0,flush_exe0_exe1_1,flush_exe1_wb_0,flush_exe1_wb_1;
    wire stall_pc,stall_if0_if1,stall_if1_fifo,stall_fifo_id,stall_id_reg0,stall_id_reg1,stall_reg_exe0_0,stall_reg_exe0_1,stall_exe0_exe1_0,stall_exe0_exe1_1,stall_exe1_wb_0,stall_exe1_wb_1,stall_to_icache,stall_to_dcache;
    reg stall_exe1_wb_0_reg,stall_exe1_wb_1_reg;

    assign flush_if0_if1 =      flush_priv|ifibar1|ifibar0|ifbr1|ifbr0;
    assign flush_if1_fifo =     flush_priv|ifibar1|ifibar0|ifbr1|ifbr0;
    assign flush_fifo_id =      flush_priv|ifibar1|ifibar0|ifbr1|ifbr0;
    assign flush_id_reg0 =      flush_priv|ifibar1|ifibar0|ifbr1|ifbr0;
    assign flush_id_reg1 =      flush_priv|ifibar1|ifibar0|ifbr1|ifbr0;
    assign flush_reg_exe0_0 =   flush_priv|ifibar1|ifibar0|ifbr1|ifbr0;
    assign flush_reg_exe0_1 =   flush_priv|ifibar1|ifibar0|ifbr1|ifbr0;
    assign flush_exe0_exe1_0 =  flush_priv|ifibar1|ifbr1;
    assign flush_exe0_exe1_1 =  0;
    assign flush_exe1_wb_0 =    0;
    assign flush_exe1_wb_1 =    0;

    assign stall_pc =           break_point|stall_fetch_buffer|stall_priv|stall_div0|stall_div1|stall_dcache|stall_icache;
    assign stall_if0_if1 =      break_point|stall_fetch_buffer|stall_priv|stall_div0|stall_div1|stall_dcache|stall_icache;
    assign stall_to_icache =    break_point|stall_fetch_buffer|stall_priv|stall_div0|stall_div1|stall_dcache;//暂时不死锁
    assign stall_if1_fifo =     break_point|stall_fetch_buffer|stall_priv|stall_div0|stall_div1|stall_dcache;
    assign stall_fifo_id =      break_point|stall_priv|stall_div0|stall_div1|stall_dcache;
    assign stall_id_reg0 =      break_point|stall_priv|stall_div0|stall_div1|stall_dcache;
    assign stall_id_reg1 =      break_point|stall_priv|stall_div0|stall_div1|stall_dcache;
    assign stall_reg_exe0_0 =   break_point|stall_priv|stall_div0|stall_div1|stall_dcache;
    assign stall_reg_exe0_1 =   break_point|stall_priv|stall_div0|stall_div1|stall_dcache;
    assign stall_exe0_exe1_0 =  break_point|stall_priv|stall_div0|stall_div1|stall_dcache;
    assign stall_exe0_exe1_1 =  break_point|stall_priv|stall_div0|stall_div1|stall_dcache;
    assign stall_to_dcache =    break_point|stall_priv|stall_div0|stall_div1;//暂时不死锁
    assign stall_exe1_wb_0 =    break_point|stall_priv|stall_div0|stall_div1|stall_dcache;
    assign stall_exe1_wb_1 =    break_point|stall_priv|stall_div0|stall_div1|stall_dcache;

    //ICache Return Buffer
    wire        mem_icache_addrOK;
    wire        mem_icache_dataOK;
    wire 	    icache_mem_req;
    wire [32*(1<<offset_width)-1:0]     din_mem_icache;
    wire    i_rready;
    // wire    i_rvalid;
    wire    [31:0] i_rdata;
    wire    i_rlast;

    ReturnBuffer#(
        .offset_width       (offset_width)
    )
    icache_returnbuf(
        .clk                (clk),
        .rstn               (rstn),
        .cache_mem_req      (icache_mem_req),
        .mem_cache_dataOK   (mem_icache_dataOK),
        .dout_mem_cache     (din_mem_icache),
        .rready             (i_rready),
        .rdata              (i_rdata),
        .rlast              (i_rlast)
    );

    //ICache
    wire [31:0]	test1_icache;
    wire [31:0]	test2_icache;
    wire [31:0]	test3_icache;

    wire [63:0]	dout_icache_pipeline;
    wire 	    flag_icache_pipeline;
    wire        icache_pipeline_ready;

    wire [31:0]	addr_icache_mem;
    wire [1:0]	icache_mem_size;

    Icache_DMA #(
        .index_width  		( 4 		),
        .offset_width 		( 2 		),
        .way          		( 2 		))
    u_Icache(
        //ports
        .clk                    		( clk                    		),
        .rstn                   		( rstn                   		),
        .test1                  		( test1_icache           		),
        .test2                  		( test2_icache           		),
        .test3                  		( test3_icache           		),

        // .ifibar(ifibar0|ifibar1),
        .addr_pipeline_icache   		( |pc[1:0]?0:pc   		),
        .dout_icache_pipeline   		( dout_icache_pipeline   		),//
        .flag_icache_pipeline   		( flag_icache_pipeline   		),//
        .pipeline_icache_valid  		( 1  		),
        .icache_pipeline_ready  		( icache_pipeline_ready  		),//
        .pipeline_icache_opcode 		( 0 		),
        .pipeline_icache_opflag 		( 0 		),
        .pipeline_icache_ctrl           ( {30'b0,flush_if0_if1,stall_to_icache} ),
        .icache_pipeline_stall  		( stall_icache  		),//

        .addr_icache_mem        		( addr_icache_mem        		),
        .din_mem_icache         		( din_mem_icache         		),
        .icache_mem_req         		( icache_mem_req         		),
        .icache_mem_size        		( icache_mem_size        		),
        .mem_icache_addrOK      		( rready      	),
        .mem_icache_dataOK      		( mem_icache_dataOK      		)
    );

    // wire [63:0]	dout_icache_pipeline;
    // wire 	flag_icache_pipeline,icache_pipeline_ready;

    // icache_testonly u_icache_testonly(
    //     //ports
    //     .flush(flush_if0_if1),
    //     .stall(stall_if0_if1),
    //     .icache_valid_reg(icache_pipeline_ready),
    //     .clk      		( clk      		),
    //     .rstn     		( rstn     		),
    //     .pc       		( |pc[1:0]?0:pc  ),
    //     .ir_reg   		( dout_icache_pipeline   		    ),
    //     .flag_reg 		( flag_icache_pipeline 		    )
    // );

    wire [31:0]	pc0;
    wire [31:0]	pc1;
    wire [31:0]	ir0;
    wire [31:0]	ir1;
    wire 	if0;
    wire 	if1;
    
    fetch_buffer_v2 u_fetch_buffer(
        //ports
        .pc             ( pc_if1_fifo   ),
        .flush          ( flush_fifo_id ),
        .stall          ( stall_fifo_id ),
        .icache_valid   ( icache_valid_if1_fifo),
        .clk     		( clk     		),
        .rstn    		( rstn    		),
        .if0     		( if0     		),
        .if1     		( if1     		),
        .irin    		( ir_if1_fifo   ),
        .flag    		( flag_if1_fifo ),
        .ir0 		    ( ir0 	    	),
        .ir1 		    ( ir1 	    	),
        .pc0            ( pc0           ),
        .pc1            ( pc1           ),
        .stall_fetch_buffer(stall_fetch_buffer)
    );

    wire [31:0]	control0;
    wire [4:0]	rk0;
    wire [4:0]	rj0;
    wire [4:0]	rd0;
    wire [31:0]	imm0;
    wire [15:0]	excp_arg0;

    decoder u_decoder0(
        //ports
        // .PLV            ( PLV               ),
        .pc             ( pc0               ),
        .ir       		( ir0 	    	    ),
        .control  		( control0  		),
        .rk       		( rk0       		),
        .rj       		( rj0       		),
        .rd       		( rd0       		),
        .imm      		( imm0      		),
        .excp_arg 		( excp_arg0 		)
    );

    wire [31:0]	control1;
    wire [4:0]	rk1;
    wire [4:0]	rj1;
    wire [4:0]	rd1;
    wire [31:0]	imm1;
    wire [15:0]	excp_arg1;

    decoder u_decoder1(
        //ports
        // .PLV            ( PLV               ),
        .pc             ( pc1               ),
        .ir       		( ir1        	    ),
        .control  		( control1  		),
        .rk       		( rk1       		),
        .rj       		( rj1       		),
        .rd       		( rd1       		),
        .imm      		( imm1      		),
        .excp_arg 		( excp_arg1 		)
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
    wire [31:0] pc00;
    wire [31:0] pc11;
    wire [31:0] ir00;
    wire [31:0] ir11;    

    dispatcher u_dispatcher(
        //ports
        .clk     		    ( clk     		),
        .rstn    		    ( rstn    		),
        .flush(flush_fifo_id),
        .stall(stall_fifo_id),
        .pc0(pc0),
        .pc1(pc1),
        .ir0(ir0),
        .ir1(ir1),
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
        .rk00       		( rk00       		),
        .rk11       		( rk11       		),
        .rj00       		( rj00       		),
        .rj11       		( rj11       		),
        .rd00       		( rd00       		),
        .rd11       		( rd11       		),
        .imm00      		( imm00      		),
        .imm11      		( imm11      		),
        .pc00(pc00),
        .pc11(pc11),
        .ir00(ir00),
        .ir11(ir11),
        .control00  		( control00  		),
        .control11  		( control11  		),
        .excp_arg00 		( excp_arg00 		),
        .excp_arg11 		( excp_arg11 		),
        .if0        		( if0        		),
        .if1        		( if1        		)
    );

    wire [31:0]	rrk0_rf;
    wire [31:0]	rrk1_rf;
    wire [31:0]	rrj0_rf;
    wire [31:0]	rrj1_rf;
    wire [31:0]	rrd0_rf;
    wire [31:0]	rrd1_rf;
    wire [31:0]	wb_data0;
    wire [31:0]	wb_data1;
    wire [4:0]	wb_addr0;
    wire [4:0]	wb_addr1;
    wire ifwb0,ifwb1;

    register_file u_register_file(
        //ports
        .stall0(stall_exe1_wb_0),
        .stall1(stall_exe1_wb_1),
        .clk      		( clk      		),
        .rstn      		( rstn      		),
        .ifwb0    		( ifwb0    		),
        .ifwb1    		( ifwb1    		),
        .wb_data0 		( wb_data0 		),
        .wb_addr0 		( wb_addr0 		),
        .wb_data1 		( wb_data1 		),
        .wb_addr1 		( wb_addr1 		),
        .rk0     		( rk_id_reg_0     		),
        .rk1     		( rk_id_reg_1     		),
        .rj0     		( rj_id_reg_0     		),
        .rj1     		( rj_id_reg_1     		),
        .rd0     		( rd_id_reg_0     		),
        .rd1     		( rd_id_reg_1     		),
        .rrk0     		( rrk0_rf     		),
        .rrk1     		( rrk1_rf     		),
        .rrj0     		( rrj0_rf     		),
        .rrj1     		( rrj1_rf     		),
        .rrd0     		( rrd0_rf     		),
        .rrd1     		( rrd1_rf     		),
        .rf_rdata       ( rf_rdata     		),
        .reg_num        ( reg_num     		),
        .infor_flag     ( infor_flag     		)
        `ifdef DIFFTEST_EN
        ,.reg0          (regs[0]    ),
        .reg1           (regs[1]    ),
        .reg2           (regs[2]    ),
        .reg3           (regs[3]    ),
        .reg4           (regs[4]    ),
        .reg5           (regs[5]    ),
        .reg6           (regs[6]    ),
        .reg7           (regs[7]    ),
        .reg8           (regs[8]    ),
        .reg9           (regs[9]    ),
        .reg10          (regs[10]   ),
        .reg11          (regs[11]   ),
        .reg12          (regs[12]   ),
        .reg13          (regs[13]   ),
        .reg14          (regs[14]   ),
        .reg15          (regs[15]   ),
        .reg16          (regs[16]   ),
        .reg17          (regs[17]   ),
        .reg18          (regs[18]   ),
        .reg19          (regs[19]   ),
        .reg20          (regs[20]   ),
        .reg21          (regs[21]   ),
        .reg22          (regs[22]   ),
        .reg23          (regs[23]   ),
        .reg24          (regs[24]   ),
        .reg25          (regs[25]   ),
        .reg26          (regs[26]   ),
        .reg27          (regs[27]   ),
        .reg28          (regs[28]   ),
        .reg29          (regs[29]   ),
        .reg30          (regs[30]   ),
        .reg31          (regs[31]   )
        `endif
    );

    wire [31:0]	rrj0_forward;
    wire [31:0]	rrj1_forward;
    wire [31:0]	rrk0_forward;
    wire [31:0]	rrk1_forward;
    wire [31:0]	rrd0_forward;
    wire [31:0]	rrd1_forward;

    forward u_forward(
        //ports
        .ctr_exe1_wb_0(ctr_exe1_wb_0),
        .ctr_exe1_wb_1(ctr_exe1_wb_1),
        .ctr_exe0_exe1_0(ctr_exe0_exe1_0),
        .ctr_exe0_exe1_1(ctr_exe0_exe1_1),
        .aluresult_exe0_exe1_0 		( aluresult_exe0_exe1_0 		),
        .aluresult_exe0_exe1_1 		( aluresult_exe0_exe1_1 		),
        .result_exe1_wb_0      		( result_exe1_wb_0      		),
        .result_exe1_wb_1      		( result_exe1_wb_1      		),
        .rrj_reg_exe0_0        		( rrj_reg_exe0_0        		),
        .rrj_reg_exe0_1        		( rrj_reg_exe0_1        		),
        .rrk_reg_exe0_0        		( rrk_reg_exe0_0        		),
        .rrk_reg_exe0_1        		( rrk_reg_exe0_1        		),
        .rd_exe0_exe1_0        		( rd_exe0_exe1_0        		),
        .rd_exe0_exe1_1        		( rd_exe0_exe1_1        		),
        .rrd_reg_exe0_0        		( rrd_reg_exe0_0        		),
        .rrd_reg_exe0_1        		( rrd_reg_exe0_1        		),
        .rd_exe1_wb_0          		( rd_exe1_wb_0          		),
        .rd_exe1_wb_1          		( rd_exe1_wb_1          		),
        .rj0                   		( rj_reg_exe0_0               		),
        .rj1                   		( rj_reg_exe0_1               		),
        .rk0                   		( rk_reg_exe0_0               		),
        .rk1                   		( rk_reg_exe0_1               		),
        .rd0(rd_reg_exe0_0),
        .rd1(rd_reg_exe0_1),
        .rrj0                  		( rrj0_forward                  ),
        .rrj1                  		( rrj1_forward                  ),
        .rrk0                  		( rrk0_forward                  ),
        .rrk1                  		( rrk1_forward                  ),
        .rrd0(rrd0_forward),
        .rrd1(rrd1_forward)
    );

    wire [31:0]	alu1_0;

    alusrc u_alusrc1_0(
        //ports
        .register0 		( rrj0_forward 		),
        .register2 		( 0 		),
        .register3 		( 0 		),
        .register1    	( pc_reg_exe0_0    		),
        .alusrc_   		( ctr_reg_exe0_0[15:14]   		),
        .alu      		( alu1_0      		)
    );

    wire [31:0]	alu2_0;

    alusrc u_alusrc2_0(
        //ports
        .register0 		( rrk0_forward 		),
        .register2 		( rrd0_forward 		),
        .register3 		( 4 		),
        .register1    	( imm_reg_exe0_0    		),
        .alusrc_   		( ctr_reg_exe0_0[13:12]   		),
        .alu      		( alu2_0      		)
    );

    wire [31:0]	alu1_1;

    alusrc u_alusrc1_1(
        //ports
        .register0 		( rrj1_forward 		),
        .register2 		( 0 		),
        .register3 		( 0 		),
        .register1    	( pc_reg_exe0_1    		),
        .alusrc_   		( ctr_reg_exe0_1_ALE[15:14]   		),
        .alu      		( alu1_1      		)
    );

    wire [31:0]	alu2_1;

    alusrc u_alusrc2_1(
        //ports
        .register0 		( rrk1_forward 		),
        .register2 		( rrd1_forward 		),
        .register3 		( 4 		),
        .register1    	( imm_reg_exe0_1    		),
        .alusrc_   		( ctr_reg_exe0_1_ALE[13:12]   		),
        .alu      		( alu2_1      		)
    );

    wire [31:0]	aluresult0;
    wire 	zero0;

    alu u_alu0(
        //ports
        .alu1      		( alu1_0      		),
        .alu2      		( alu2_0      		),
        .ctr       		( ctr_reg_exe0_0       		),
        .aluresult 		( aluresult0		),
        .zero      		( zero0     		)
    );

    wire [31:0]	aluresult1;
    wire 	zero1;

    alu u_alu1(
        //ports
        .alu1      		( alu1_1      		),
        .alu2      		( alu2_1      		),
        .ctr       		( ctr_reg_exe0_1_ALE       		),
        .aluresult 		( aluresult1		),
        .zero      		( zero1     		)
    );

    wire [31:0]	mulresult0;

    muitiplier u_muitiplier0(
        //ports
        .clk                         		( clk                         		),
        .rstn                        		( rstn                        		),
        .pipeline_muitiplier_flush   		( flush_exe0_exe1_0   		),
        .pipeline_muitiplier_stall   		( stall_exe0_exe1_0   		),
        // .pipeline_muitiplier_type 		    ( ctr_reg_exe0_0[3:0] 		),
        .pipeline_muitiplier_subtype 		( ctr_reg_exe0_0[11:7] 		),
        .pipeline_muitiplier_din1    		( rrj0_forward    		),
        .pipeline_muitiplier_din2    		( rrk0_forward    		),
        .muitiplier_pipeline_dout    		( mulresult0    		)
    );

    wire [31:0]	mulresult1;

    muitiplier u_muitiplier1(
        //ports
        .clk                         		( clk                         		),
        .rstn                        		( rstn                        		),
        .pipeline_muitiplier_flush   		( flush_exe0_exe1_1   		),
        .pipeline_muitiplier_stall   		( stall_exe0_exe1_1   		),
        // .pipeline_muitiplier_type 		    ( ctr_reg_exe0_1_ALE[3:0] 		),
        .pipeline_muitiplier_subtype 		( ctr_reg_exe0_1_ALE[11:7] 		),
        .pipeline_muitiplier_din1    		( rrj1_forward    		),
        .pipeline_muitiplier_din2    		( rrk1_forward    		),
        .muitiplier_pipeline_dout    		( mulresult1    		)
    );

    wire [31:0]	divresult0=0;

    // divider #(
    //     .WIDTH 		( 32 		))
    // u_divider0(
    //     //ports
    //     .clk                      		( clk                      		),
    //     .rstn                     		( rstn                     		),
    //     .pipeline_divider_type    		( ctr_reg_exe0_0[3:0]    		),
    //     .pipeline_divider_subtype 		( ctr_reg_exe0_0[11:7] 		),
    //     .pipeline_divider_stall   		( stall_exe0_exe1_0   		),
    //     .pipeline_divider_flush   		( flush_exe0_exe1_0   		),
    //     .pipeline_divider_din1    		( rrj0_forward    		),
    //     .pipeline_divider_din2    		( rrk0_forward    		),
    //     .divider_pipeline_stall   		( stall_div0   		),
    //     .divider_pipeline_dout    		( divresult0    		)
    // );

    wire [31:0]	divresult1;
    
    // divider #(
    //     .WIDTH 		( 32 		))
    // u_divider1(
    //     //ports
    //     .clk                      		( clk                      		),
    //     .rstn                     		( rstn                     		),
    //     .pipeline_divider_type    		( ctr_reg_exe0_1_ALE[3:0]    		),
    //     .pipeline_divider_subtype 		( ctr_reg_exe0_1_ALE[11:7] 		),
    //     .pipeline_divider_stall   		( stall_exe0_exe1_1   		),
    //     .pipeline_divider_flush   		( flush_exe0_exe1_1   		),
    //     .pipeline_divider_din1    		( rrj1_forward    		),
    //     .pipeline_divider_din2    		( rrk1_forward    		),
    //     .divider_pipeline_stall   		( stall_div1   		),
    //     .divider_pipeline_dout    		( divresult1    		)
    // );

    ibar u_ibar0(
        //ports
        .ctr        	( ctr_reg_exe0_0        		),
        .ifibar 		( ifibar0 		)
    );

    ibar u_ibar1(
        //ports
        .ctr        	( ctr_reg_exe0_1_ALE        		),
        .ifibar 		( ifibar1 		)
    );

    wire [31:0]	brresult0;

    br u_br0(
        //ports
        .ctr      		( ctr_reg_exe0_0      		),
        .pc       		( pc_reg_exe0_0       		),
        .imm      		( imm_reg_exe0_0      		),
        .zero     		( zero0     		),
        .ifbr     		( ifbr0    		),
        .brresult 		( brresult0 	),
        .rrj            ( rrj0_forward  )
    );

    wire [31:0]	brresult1;

    br u_br1(
        //ports
        .ctr      		( ctr_reg_exe0_1_ALE      		),
        .pc       		( pc_reg_exe0_1       		),
        .imm      		( imm_reg_exe0_1      		),
        .zero     		( zero1     		),
        .ifbr     		( ifbr1    		),
        .brresult 		( brresult1		),
        .rrj            ( rrj1_forward  )
    );

    wire [31:0]	addr_pipeline_dcache;
    wire [31:0]	din_pipeline_dcache;
    wire 	type_pipeline_dcache;
    wire 	pipeline_dcache_valid;
    wire [3:0]	pipeline_dcache_wstrb;
    wire [31:0]	pipeline_dcache_opcode;
    wire 	pipeline_dcache_opflag;

    dcache_ctr u_dcache_ctr(
        //ports
        .excp_arg_reg_exe0_1_excp       ( excp_arg_reg_exe0_1_excp      ),
        .rrj1_forward         		    ( rrj1_forward         		    ),
        .imm_reg_exe0_1         		( imm_reg_exe0_1         		),
        .ctr_reg_exe0_1         		( ctr_reg_exe0_1         		),
        .rd_reg_exe0_1          		( rd_reg_exe0_1          		),
        .addr_pipeline_dcache   		( addr_pipeline_dcache   		),
        .din_pipeline_dcache    		( din_pipeline_dcache    		),
        .type_pipeline_dcache   		( type_pipeline_dcache   		),
        .pipeline_dcache_valid  		( pipeline_dcache_valid  		),
        .pipeline_dcache_wstrb  		( pipeline_dcache_wstrb  		),
        .pipeline_dcache_opcode 		( pipeline_dcache_opcode 		),
        .pipeline_dcache_opflag 		( pipeline_dcache_opflag 		)
    );

    wire [8:0]	CRMD=0;
    wire [9:0]	ASID=0;
    wire [31:0]	DMW0=0;
    wire [31:0]	DMW1=0;
    assign PLV=CRMD[1:0];

    // CSR_control u_CSR_control(
    //     //ports
    //     .clk                    		( clk                    		),
    //     .rstn                   		( rstn                   		),
    //     .pipeline_CSR_flush     		( flush_exe0_exe1_1     		),
    //     .pipeline_CSR_stall     		( stall_exe0_exe1_1     		),
    //     .CSR_pipeline_stall     		( stall_priv     		        ),
    //     .CSR_pipeline_flush     		( flush_priv     		        ),
    //     .CSR_pipeline_outpc     		( pc_priv     		            ),
    //     .pipeline_CSR_type      		( ctr_reg_exe0_1_ALE[3:0]     	),
    //     .pipeline_CSR_subtype   		( ctr_reg_exe0_1_ALE[11:7]     	),
    //     .pipeline_CSR_din       		( rrd1_forward       		    ),
    //     .pipeline_CSR_mask      		( rrj1_forward      		    ),
    //     .CSR_pipeline_dout      		( privresult1      		        ),

    //     .pipeline_CSR_inpc0     		( pc_reg_exe0_1     		    ),
    //     .pipeline_CSR_excp_arg0 		( excp_arg_reg_exe0_1_excp      ),
    //     .pipeline_CSR_evaddr0   		( addr_pipeline_dcache          ),

    //     .pipeline_CSR_inpc1     		( pc_exe0_exe1_1     		    ),
    //     .pipeline_CSR_excp_arg1 		( excp_arg_exe0_exe1_1_excp     ),
    //     .pipeline_CSR_evaddr1   		( addr_pipeline_dcache_reg		),

    //     .pipeline_CSR_ESTAT     		( 0     		),
    //     .CSR_pipeline_clk_stall 		( stall_priv_idle 		        ),
    //     .CSR_pipeline_CRMD      		( CRMD      		),
    //     .CSR_pipeline_LLBit     		( LLbit     		),
    //     .CSR_pipeline_ASID      		( ASID      		),
    //     .CSR_pipeline_DMW0      		( DMW0      		),
    //     .CSR_pipeline_DMW1      		( DMW1      		)
    // );

    wire [31:0]	test1_dcache;
    wire [31:0]	test2_dcache;
    wire [31:0]	test3_dcache;

    wire [31:0]	dout_dcache_pipeline;
    wire 	dcache_pipeline_ready;//无用？

    wire [31:0]	addr_dcache_mem;
    wire [31:0]	dout_dcache_mem;
    wire 	dcache_mem_req;
    wire 	dcache_mem_wr;
    wire [1:0]	dcache_mem_size;
    wire [3:0]	dcache_mem_wstrb;
    wire [31:0] din_mem_dcache;
    wire mem_dcache_addrOK;
    wire mem_dcache_dataOK;

    Dcache_DMA #(
        .index_width  		( 4 		),
        .offset_width 		( 2 		),
        .way          		( 2 		))
    u_Dcache(
        //ports
        .clk                    		( clk                    		),
        .rstn                   		( rstn                   		),
        .test1                  		( test1_dcache           		),
        .test2                  		( test2_dcache           		),
        .test3                  		( test3_dcache           		),

        .addr_pipeline_dcache   		( addr_pipeline_dcache          ),
        .din_pipeline_dcache    		( din_pipeline_dcache    		),
        .dout_dcache_pipeline   		( dout_dcache_pipeline   		),
        .type_pipeline_dcache   		( type_pipeline_dcache   		),
        .pipeline_dcache_valid  		( pipeline_dcache_valid  		),
        .dcache_pipeline_ready  		( dcache_pipeline_ready  		),
        .pipeline_dcache_wstrb  		( pipeline_dcache_wstrb  		),
        .pipeline_dcache_opcode 		( pipeline_dcache_opcode 		),
        .pipeline_dcache_opflag 		( pipeline_dcache_opflag 		),
        .pipeline_dcache_ctrl   		( {30'b0,flush_exe0_exe1_1,stall_to_dcache}),
        .dcache_pipeline_stall  		( stall_dcache  		        ),

        .addr_dcache_mem        		( addr_dcache_mem        		),
        .dout_dcache_mem        		( dout_dcache_mem        		),
        .din_mem_dcache         		( din_mem_dcache         		),
        .dcache_mem_req         		( dcache_mem_req         		),
        .dcache_mem_wr          		( dcache_mem_wr          		),
        .dcache_mem_size        		( dcache_mem_size        		),
        .dcache_mem_wstrb       		( dcache_mem_wstrb       		),
        .mem_dcache_addrOK      		( mem_dcache_addrOK      		),
        .mem_dcache_dataOK      		( mem_dcache_dataOK      		)
    );

    wire [31:0]	dcacheresult;

    dcache_extend u_dcache_extend(
        //ports
        .ctr_exe0_exe1_1             		( ctr_exe0_exe1_1      ),
        .dout_dcache_pipeline        		( dout_dcache_pipeline ),
        .addr_pipeline_dcache    		    ( addr_pipeline_dcache ),
        .dout_dcache_pipeline_extend 		( dcacheresult 		   ),
        .din_pipeline_dcache                ( din_pipeline_dcache )
    );

    // wire [31:0]	dcacheresult;

    // dcache_testonly u_dcache_testonly(
    //     //ports
    //     .clk      		( clk      		),
    //     .rstn     		( rstn     		),
    //     .addr     		( rrj1_forward+imm_reg_exe0_1 ),
    //     .data_reg 		( dcacheresult  )
    // );

    writeback u_writeback(
        //ports
        .ifwb0    		        ( ifwb0    		        ),
        .ifwb1    		        ( ifwb1    		        ),
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

    //AXI
    wire 	d_rready;
    wire 	d_wready;
    wire    d_rlast;
    wire    d_bvalid;
    assign  mem_dcache_addrOK = dcache_mem_wr?d_wready:arready;
    assign  mem_dcache_dataOK = d_rready;

    axi_arbiter u_axi_arbiter(
        //ports
        .clk      		( clk      		),
        .rstn     		( rstn     		),

        //ICache
        .i_rvalid 		( icache_mem_req 		),//input       
        .i_rready 		( i_rready 		),//output reg  
        .i_raddr  		( addr_icache_mem  		),//input [31:0]
        .i_rdata  		( i_rdata  		),//output[31:0]
        .i_rlast  		( i_rlast  		),//output reg  
        .i_rsize  		( {1'b0,icache_mem_size}  		),//input [2:0] 
        .i_rlen   		( 8'd3   		),//input [7:0] 

        //Dcache
        .d_rvalid 		( dcache_mem_req & ~dcache_mem_wr ),//input       
        .d_rready 		( d_rready 		),//output reg  
        .d_raddr  		( addr_dcache_mem  		),//input [31:0]
        .d_rdata  		( din_mem_dcache  		),//output [31:0]
        .d_rlast  		( d_rlast	),//output reg  
        .d_rsize  		( {1'b0,dcache_mem_size}  		),//input [2:0] 
        .d_rlen   		( 8'b0   		),//input [7:0]

        .d_wvalid 		( dcache_mem_req & dcache_mem_wr ),//input
        .d_wready 		( d_wready 		),//output reg  
        .d_waddr  		( addr_dcache_mem  		),//input [31:0]
        .d_wdata  		( dout_dcache_mem  		),//input [31:0]
        .d_wstrb  		( dcache_mem_wstrb  		),//input [3:0] 字节选通位
        .d_wlast  		( 1'b1  		),//input       
        .d_wsize  		( {1'b0,dcache_mem_size}  		),//input [2:0] 
        .d_wlen   		( 8'b0   		),//input [7:0] 

        .d_bvalid 		( d_bvalid  ),//output reg
        .d_bready 		( 1'b1 		),//input       
        
        //AXI
        .araddr   		( araddr   		),
        .arvalid  		( arvalid  		),
        .arready  		( arready  		),
        .arlen    		( arlen    		),
        .arsize   		( arsize   		),
        .arburst  		( arburst  		),
        .rdata    		( rdata    		),
        .rresp    		( rresp    		),
        .rvalid   		( rvalid   		),
        .rready   		( rready   		),
        .rlast    		( rlast    		),
        .awaddr   		( awaddr   		),
        .awvalid  		( awvalid  		),
        .awready  		( awready  		),
        .awlen    		( awlen    		),
        .awsize   		( awsize   		),
        .awburst  		( awburst  		),
        .wdata    		( wdata    		),
        .wstrb    		( wstrb    		),
        .wvalid   		( wvalid   		),
        .wready   		( wready   		),
        .wlast    		( wlast    		),
        .bresp    		( bresp    		),
        .bvalid   		( bvalid   		),
        .bready   		( bready   		)
    );

    //PC
    wire ifflush_if1_fifo=stall_icache|flush_if0_if1|fflush_if0_if1;
    always @(*) begin
        if(ifbr_priv) npc=pc_priv;
        else if(ifbr1) npc=brresult1;
        else if(ifbr0) npc=brresult0;
        // else if(pc[2]) npc=pc+4;//Icache ONLY
        else if(!ifflush_if1_fifo)npc=pc+8;//DMA ONLY
        // else npc=pc+8;//Icache ONLY
    end    
    always @(posedge clk,negedge rstn) begin
        if(!rstn) pc<=32'h1c000000;
        else if(!stall_pc|ifbr0|ifbr1) pc<=npc;
    end

    //IF0-IF1 Icache ONLY
    // always @(posedge clk or negedge rstn) begin
    //     if(!rstn|flush_if0_if1) begin
    //         pc_if0_if1<=0;
    //     end
    //     else if(!stall_if0_if1)begin
    //         pc_if0_if1<=pc;
    //     end
    // end

    //IF1-FIFO
    //flush套壳
    reg fflush_if0_if1;
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            fflush_if0_if1 <= 0;
        end
        else if(flush_if0_if1) fflush_if0_if1 <= 1;  //to be test
        else if(!stall_icache) fflush_if0_if1 <= 0;
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            pc_if1_fifo<=0;ir_if1_fifo<=0;icache_valid_if1_fifo<=0;flag_if1_fifo<=0;
        end
        else if(stall_if1_fifo);
        else if(flush_if1_fifo|ifflush_if1_fifo)begin
            pc_if1_fifo<=0;ir_if1_fifo<=0;icache_valid_if1_fifo<=0;flag_if1_fifo<=0;
        end
        else begin
            // pc_if1_fifo<=pc_if0_if1;//Icache ONLY
            pc_if1_fifo<=pc;//DMA ONLY
            ir_if1_fifo<=dout_icache_pipeline;
            icache_valid_if1_fifo<=icache_pipeline_ready;
            flag_if1_fifo<=flag_icache_pipeline;
        end
    end

    //FIFO-ID
    //即fetch_buffer

    //ID-REG
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            ctr_id_reg_0 <= 0;
            excp_arg_id_reg_0<=0;
            imm_id_reg_0<=0;
            rk_id_reg_0<=0;
            rj_id_reg_0<=0;
            rd_id_reg_0<=0;
            pc_id_reg_0<=0;
            ir_id_reg_0<=0;
        end
        else if(stall_id_reg0);
        else if(flush_id_reg0)begin
            ctr_id_reg_0 <= 0;
            excp_arg_id_reg_0<=0;
            imm_id_reg_0<=0;
            rk_id_reg_0<=0;
            rj_id_reg_0<=0;
            rd_id_reg_0<=0;
            pc_id_reg_0<=0;
            ir_id_reg_0<=0;
        end
        else begin
            ctr_id_reg_0 <= control00;
            excp_arg_id_reg_0<=excp_arg00;
            imm_id_reg_0<=imm00;
            rk_id_reg_0<=rk00;
            rj_id_reg_0<=rj00;
            rd_id_reg_0<=rd00;
            pc_id_reg_0<=pc00;
            ir_id_reg_0<=ir00;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            ctr_id_reg_1 <= 0;
            excp_arg_id_reg_1<=0;
            imm_id_reg_1<=0;
            rk_id_reg_1<=0;
            rj_id_reg_1<=0;
            rd_id_reg_1<=0;
            pc_id_reg_1<=0;
            ir_id_reg_1<=0;
        end
        else if(stall_id_reg1);
        else if(flush_id_reg1) begin
            ctr_id_reg_1 <= 0;
            excp_arg_id_reg_1<=0;
            imm_id_reg_1<=0;
            rk_id_reg_1<=0;
            rj_id_reg_1<=0;
            rd_id_reg_1<=0;
            pc_id_reg_1<=0;
            ir_id_reg_1<=0;
        end
        else begin
            ctr_id_reg_1 <= control11;
            excp_arg_id_reg_1<=excp_arg11;
            imm_id_reg_1<=imm11;
            rk_id_reg_1<=rk11;
            rj_id_reg_1<=rj11;
            rd_id_reg_1<=rd11;
            pc_id_reg_1<=pc11;
            ir_id_reg_1<=ir11;
        end
    end

    //REG-EXE0
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            ctr_reg_exe0_0 <= 0;
            // excp_arg_reg_exe0_0<=0;
            imm_reg_exe0_0<=0;
            rk_reg_exe0_0<=0;
            rj_reg_exe0_0<=0;
            rd_reg_exe0_0<=0;
            rrk_reg_exe0_0<=0;
            rrj_reg_exe0_0<=0;
            rrd_reg_exe0_0<=0;
            pc_reg_exe0_0<=0;
            ir_reg_exe0_0<=0;
        end
        else if(stall_reg_exe0_0);
        else if(flush_reg_exe0_0) begin
            ctr_reg_exe0_0 <= 0;
            // excp_arg_reg_exe0_0<=0;
            imm_reg_exe0_0<=0;
            rk_reg_exe0_0<=0;
            rj_reg_exe0_0<=0;
            rd_reg_exe0_0<=0;
            rrk_reg_exe0_0<=0;
            rrj_reg_exe0_0<=0;
            rrd_reg_exe0_0<=0;
            pc_reg_exe0_0<=0;
            ir_reg_exe0_0<=0;
        end
        else begin
            ctr_reg_exe0_0 <= ctr_id_reg_0;
            // excp_arg_reg_exe0_0<=excp_arg_id_reg_0;
            imm_reg_exe0_0<=imm_id_reg_0;
            rrk_reg_exe0_0<=rrk0_rf;
            rrj_reg_exe0_0<=rrj0_rf;
            rrd_reg_exe0_0<=rrd0_rf;
            rk_reg_exe0_0<=rk_id_reg_0;
            rj_reg_exe0_0<=rj_id_reg_0;
            rd_reg_exe0_0<=rd_id_reg_0;
            pc_reg_exe0_0<=pc_id_reg_0;
            ir_reg_exe0_0<=ir_id_reg_0;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            ctr_reg_exe0_1 <= 0;
            excp_arg_reg_exe0_1<=0;
            imm_reg_exe0_1<=0;
            rk_reg_exe0_1<=0;
            rj_reg_exe0_1<=0;
            rd_reg_exe0_1<=0;
            rrk_reg_exe0_1<=0;
            rrj_reg_exe0_1<=0;
            rrd_reg_exe0_1<=0;
            pc_reg_exe0_1<=0;
            ir_reg_exe0_1<=0;
        end
        else if(stall_reg_exe0_1);
        else if(flush_reg_exe0_1) begin
            ctr_reg_exe0_1 <= 0;
            excp_arg_reg_exe0_1<=0;
            imm_reg_exe0_1<=0;
            rk_reg_exe0_1<=0;
            rj_reg_exe0_1<=0;
            rd_reg_exe0_1<=0;
            rrk_reg_exe0_1<=0;
            rrj_reg_exe0_1<=0;
            rrd_reg_exe0_1<=0;
            pc_reg_exe0_1<=0;
            ir_reg_exe0_1<=0;
        end
        else begin
            ctr_reg_exe0_1 <= ctr_id_reg_1;
            excp_arg_reg_exe0_1<=excp_arg_id_reg_1;
            imm_reg_exe0_1<=imm_id_reg_1;
            rrk_reg_exe0_1<=rrk1_rf;
            rrj_reg_exe0_1<=rrj1_rf;
            rrd_reg_exe0_1<=rrd1_rf;
            rk_reg_exe0_1<=rk_id_reg_1;
            rj_reg_exe0_1<=rj_id_reg_1;
            rd_reg_exe0_1<=rd_id_reg_1;
            pc_reg_exe0_1<=pc_id_reg_1;
            ir_reg_exe0_1<=ir_id_reg_1;
        end
    end

    //EXE0-EXE1
    localparam liwai = 32'd3,excp_argALE='b001001,excp_argIPE='b0_001110;
    wire [1:0]addr_2=rrj1_forward[1:0]+imm_reg_exe0_1[1:0];

    always @(*) begin//检测访存地址是否对齐，特权指令是否内核态，否则将访存指令变为例外指令
        ctr_reg_exe0_1_ALE=ctr_reg_exe0_1;
        excp_arg_reg_exe0_1_excp=excp_arg_reg_exe0_1;
        if(ctr_reg_exe0_1[23]&(|PLV)) begin ctr_reg_exe0_1_ALE=liwai;excp_arg_reg_exe0_1_excp=excp_argIPE; end//用户态访问越界
        else if(ctr_reg_exe0_1[3:0]==5)
            case (ctr_reg_exe0_1[11:7])
                1: if(addr_2[0]  ) begin ctr_reg_exe0_1_ALE=liwai;excp_arg_reg_exe0_1_excp=excp_argALE; end
                2: if(|addr_2[1:0]) begin ctr_reg_exe0_1_ALE=liwai;excp_arg_reg_exe0_1_excp=excp_argALE; end
                4: if(addr_2[0]  ) begin ctr_reg_exe0_1_ALE=liwai;excp_arg_reg_exe0_1_excp=excp_argALE; end
                5: if(|addr_2[1:0]) begin ctr_reg_exe0_1_ALE=liwai;excp_arg_reg_exe0_1_excp=excp_argALE; end
                7: if(addr_2[0]  ) begin ctr_reg_exe0_1_ALE=liwai;excp_arg_reg_exe0_1_excp=excp_argALE; end
            endcase
        else if(ctr_reg_exe0_1[3:0]==6)
            case (ctr_id_reg_1[11:7])//fot yuanzi, 0:load, 1:store
                0: if(|addr_2[1:0]) begin ctr_reg_exe0_1_ALE=liwai;excp_arg_reg_exe0_1_excp=excp_argALE; end
                1: if(LLbit) if(|addr_2[1:0]) begin ctr_reg_exe0_1_ALE=liwai;excp_arg_reg_exe0_1_excp=excp_argALE; end
            endcase
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            ctr_exe0_exe1_0 <= 0;
            rd_exe0_exe1_0 <= 0;
            aluresult_exe0_exe1_0 <= 0;
            pc_exe0_exe1_0<=0;
            ir_exe0_exe1_0<=0;
        end
        else if(stall_exe0_exe1_0);
        else if(flush_exe0_exe1_0) begin
            ctr_exe0_exe1_0 <= 0;
            rd_exe0_exe1_0 <= 0;
            aluresult_exe0_exe1_0 <= 0;
            pc_exe0_exe1_0<=0;
            ir_exe0_exe1_0<=0;
        end
        else begin
            ctr_exe0_exe1_0 <= ctr_reg_exe0_0;
            rd_exe0_exe1_0 <= rd_reg_exe0_0;
            aluresult_exe0_exe1_0 <= aluresult0;
            pc_exe0_exe1_0<=pc_reg_exe0_0;
            ir_exe0_exe1_0<=ir_reg_exe0_0;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            ctr_exe0_exe1_1 <= 0;
            rd_exe0_exe1_1<=0;
            aluresult_exe0_exe1_1<=0;
            pc_exe0_exe1_1<=0;
            ir_exe0_exe1_1<=0;
            addr_pipeline_dcache_reg<=0;
        end
        else if(stall_exe0_exe1_1);
        else if(flush_exe0_exe1_1) begin
            ctr_exe0_exe1_1 <= 0;
            rd_exe0_exe1_1<=0;
            aluresult_exe0_exe1_1<=0;
            pc_exe0_exe1_1<=0;
            ir_exe0_exe1_1<=0;
            addr_pipeline_dcache_reg<=0;
        end
        else begin
            ctr_exe0_exe1_1 <= ctr_reg_exe0_1_ALE;
            rd_exe0_exe1_1<=rd_reg_exe0_1;
            aluresult_exe0_exe1_1<=aluresult1;
            pc_exe0_exe1_1<=pc_reg_exe0_1;
            ir_exe0_exe1_1<=ir_reg_exe0_1;
            addr_pipeline_dcache_reg<=addr_pipeline_dcache;
        end
    end

    //EXE1-WB
    reg [31:0]result0,result1;
    always @(*) begin//0:alu, 1:br, 2:div, 3:priv, 4:mul, 5:dcache, 6:priv+dcache, 7:RDCNT, 8:alu+br
        result0=0;
        result1=0;
        case (ctr_exe0_exe1_0[3:0])
            0: result0=aluresult_exe0_exe1_0;
            1: ;
            2: result0=divresult0;
            4: result0=mulresult0;
            8: result0=aluresult_exe0_exe1_0;
        endcase
        case (ctr_exe0_exe1_1[3:0])
            0: result1=aluresult_exe0_exe1_1;
            1: ;
            2: result1=divresult1;
            3: result1=privresult1;
            4: result1=mulresult1;
            5: result1=dcacheresult;
            6: result1=dcacheresult;
            7: ;
            8: result1=aluresult_exe0_exe1_1;
        endcase
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            ctr_exe1_wb_0 <= 0;
            rd_exe1_wb_0<=0;
            result_exe1_wb_0<=0;
            pc_exe1_wb_0<=0;
            ir_exe1_wb_0<=0;
        end
        else if(stall_exe1_wb_0);
        else if(flush_exe1_wb_0) begin
            ctr_exe1_wb_0 <= 0;
            rd_exe1_wb_0<=0;
            result_exe1_wb_0<=0;
            pc_exe1_wb_0<=0;
            ir_exe1_wb_0<=0;
        end
        else begin
            ctr_exe1_wb_0 <= ctr_exe0_exe1_0;
            rd_exe1_wb_0<=rd_exe0_exe1_0;
            result_exe1_wb_0<=result0;
            pc_exe1_wb_0<=pc_exe0_exe1_0;
            ir_exe1_wb_0<=ir_exe0_exe1_0;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            ctr_exe1_wb_1 <= 0;
            rd_exe1_wb_1<=0;
            result_exe1_wb_1<=0;
            pc_exe1_wb_1<=0;
            ir_exe1_wb_1<=0;
        end
        else if(stall_exe1_wb_1);
        else if(flush_exe1_wb_1) begin
            ctr_exe1_wb_1 <= 0;
            rd_exe1_wb_1<=0;
            result_exe1_wb_1<=0;
            pc_exe1_wb_1<=0;
            ir_exe1_wb_1<=0;
        end
        else begin
            ctr_exe1_wb_1 <= ctr_exe0_exe1_1;
            rd_exe1_wb_1<=rd_exe0_exe1_1;
            result_exe1_wb_1<=result1;
            pc_exe1_wb_1<=pc_exe0_exe1_1;
            ir_exe1_wb_1<=ir_exe0_exe1_1;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            stall_exe1_wb_0_reg <= 0;
            stall_exe1_wb_1_reg <= 0;
        end
        else begin
            stall_exe1_wb_0_reg <= stall_exe1_wb_0;
            stall_exe1_wb_1_reg <= stall_exe1_wb_1;
        end
    end

    assign debug0_wb_pc=pc_exe1_wb_0;
    assign debug1_wb_pc=pc_exe1_wb_1;
    assign debug0_wb_rf_wen=stall_exe1_wb_0_reg?0:{4{ifwb0}};//stall_exe1_wb_0_reg?0:
    assign debug1_wb_rf_wen=stall_exe1_wb_1_reg?0:{4{ifwb1}};//stall_exe1_wb_1_reg?0:
    assign debug0_wb_rf_wnum=wb_addr0;
    assign debug1_wb_rf_wnum=wb_addr1;
    assign debug0_wb_rf_wdata=wb_data0;
    assign debug1_wb_rf_wdata=wb_data1;
    assign debug0_wb_inst=ir_exe1_wb_0;
    assign debug1_wb_inst=ir_exe1_wb_1;
    assign arid=0;
    assign arlock=0;
    assign arcache=0;
    assign arprot=0;
    assign awid=0;
    assign awlock=0;
    assign awcache=0;
    assign awprot=0;
    assign wid=0;
    wire ws_valid0,ws_valid1;
    assign ws_valid0=stall_exe1_wb_0_reg?0:(|ir_exe1_wb_0);
    assign ws_valid1=stall_exe1_wb_1_reg?0:(|ir_exe1_wb_1);
    assign ws_valid=ws_valid0|ws_valid1;

//difftest begin here
`ifdef DIFFTEST_EN
    // difftest
    //undefined
    wire tlbfill_en0=0;
    wire tlbfill_en1=0;
    wire rand_index0=0;
    wire rand_index1=0;
    wire excp_flush=0;
    wire ertn_flush=0;
    wire ws_csr_ecode=0;
    
    // from wb_stage
    wire            ws_valid_diff0      =   ws_valid0;
    wire            ws_valid_diff1      =   ws_valid1;
    wire            cnt_inst_diff0      =   0;
    wire            cnt_inst_diff1      =   0;
    wire    [63:0]  timer_64_diff       =0;

    wire    [ 7:0]  inst_ld_en_diff     =0;
    wire    [31:0]  ld_paddr_diff       =0;
    wire    [31:0]  ld_vaddr_diff       =0;

    wire    [ 7:0]  inst_st_en_diff     =0;
    wire    [31:0]  st_paddr_diff       =0;//
    wire    [31:0]  st_vaddr_diff       =0;//
    wire    [31:0]  st_data_diff        =0;//

    wire            csr_rstat_en_diff   =0;
    wire    [31:0]  csr_data_diff       =0;

    wire inst_valid_diff0 = ws_valid_diff0;
    wire inst_valid_diff1 = ws_valid_diff1;
    reg             cmt_valid0           ;
    reg             cmt_valid1           ;
    reg             cmt_cnt_inst0        ;
    reg             cmt_cnt_inst1        ;
    reg     [63:0]  cmt_timer_64        ;
    reg     [ 7:0]  cmt_inst_ld_en      ;
    reg     [31:0]  cmt_ld_paddr        ;
    reg     [31:0]  cmt_ld_vaddr        ;
    reg     [ 7:0]  cmt_inst_st_en      ;
    reg     [31:0]  cmt_st_paddr        ;
    reg     [31:0]  cmt_st_vaddr        ;
    reg     [31:0]  cmt_st_data         ;
    reg             cmt_csr_rstat_en    ;
    reg     [31:0]  cmt_csr_data        ;

    reg             cmt_wen0             ;
    reg             cmt_wen1             ;
    reg     [ 7:0]  cmt_wdest0           ;
    reg     [ 7:0]  cmt_wdest1           ;
    reg     [31:0]  cmt_wdata0           ;
    reg     [31:0]  cmt_wdata1           ;
    reg     [31:0]  cmt_pc0              ;
    reg     [31:0]  cmt_pc1              ;
    reg     [31:0]  cmt_inst0            ;
    reg     [31:0]  cmt_inst1            ;

    reg             cmt_excp_flush      ;
    reg             cmt_ertn            ;
    reg     [5:0]   cmt_csr_ecode       ;
    reg             cmt_tlbfill_en0      ;
    reg             cmt_tlbfill_en1      ;
    reg     [4:0]   cmt_rand_index0      ;
    reg     [4:0]   cmt_rand_index1      ;

    // to difftest debug
    reg             trap                ;
    reg     [ 7:0]  trap_code           ;
    reg     [63:0]  cycleCnt            ;
    reg     [63:0]  instrCnt            ;

    // from regfile
    wire    [31:0]  regs[31:0]          ;

    // from csr
    wire    [31:0]  csr_crmd_diff_0     =0;
    wire    [31:0]  csr_prmd_diff_0     =0;
    wire    [31:0]  csr_ectl_diff_0     =0;
    wire    [31:0]  csr_estat_diff_0    =0;
    wire    [31:0]  csr_era_diff_0      =0;
    wire    [31:0]  csr_badv_diff_0     =0;
    wire	[31:0]  csr_eentry_diff_0   =0;
    wire 	[31:0]  csr_tlbidx_diff_0   =0;
    wire 	[31:0]  csr_tlbehi_diff_0   =0;
    wire 	[31:0]  csr_tlbelo0_diff_0  =0;
    wire 	[31:0]  csr_tlbelo1_diff_0  =0;
    wire 	[31:0]  csr_asid_diff_0     =0;
    wire 	[31:0]  csr_save0_diff_0    =0;
    wire 	[31:0]  csr_save1_diff_0    =0;
    wire 	[31:0]  csr_save2_diff_0    =0;
    wire 	[31:0]  csr_save3_diff_0    =0;
    wire 	[31:0]  csr_tid_diff_0      =0;
    wire 	[31:0]  csr_tcfg_diff_0     =0;
    wire 	[31:0]  csr_tval_diff_0     =0;
    wire 	[31:0]  csr_ticlr_diff_0    =0;
    wire 	[31:0]  csr_llbctl_diff_0   =0;
    wire 	[31:0]  csr_tlbrentry_diff_0=0;
    wire 	[31:0]  csr_dmw0_diff_0     =0;
    wire 	[31:0]  csr_dmw1_diff_0     =0;
    wire 	[31:0]  csr_pgdl_diff_0     =0;
    wire 	[31:0]  csr_pgdh_diff_0     =0;

    always @(posedge aclk) begin
        if (!aresetn) begin
            {cmt_valid0, cmt_valid1, cmt_cnt_inst0, cmt_cnt_inst1, cmt_timer_64, cmt_inst_ld_en, cmt_ld_paddr, cmt_ld_vaddr, cmt_inst_st_en, cmt_st_paddr, cmt_st_vaddr, cmt_st_data, cmt_csr_rstat_en, cmt_csr_data} <= 0;
            {cmt_wen0, cmt_wen1, cmt_wdest0, cmt_wdest1, cmt_wdata0, cmt_wdata1, cmt_pc0, cmt_pc1, cmt_inst0, cmt_inst1} <= 0;
            {trap, trap_code, cycleCnt, instrCnt} <= 0;
        end else if (~trap) begin
            // if(~stall_exe1_wb_0) begin
                cmt_valid0       <= inst_valid_diff0          ;cmt_cnt_inst0    <= cnt_inst_diff0            ;
                cmt_wen0     <=  debug0_wb_rf_wen            ;
                cmt_wdest0   <=  {3'd0, debug0_wb_rf_wnum}   ;
                cmt_wdata0   <=  debug0_wb_rf_wdata          ;
                cmt_pc0      <=  debug0_wb_pc                ;
                cmt_inst0    <=  debug0_wb_inst              ;
                cmt_tlbfill_en0  <= tlbfill_en0               ;
                cmt_rand_index0  <= rand_index0               ;
            // end
            // else cmt_valid0<=0;
            
            // if(~stall_exe1_wb_1) begin
                cmt_valid1       <= inst_valid_diff1          ;
                cmt_cnt_inst1    <= cnt_inst_diff1            ;
                cmt_wen1     <=  debug1_wb_rf_wen            ;
                cmt_wdest1   <=  {3'd0, debug1_wb_rf_wnum}   ;
                cmt_wdata1   <=  debug1_wb_rf_wdata          ;
                cmt_pc1      <=  debug1_wb_pc                ;
                cmt_inst1    <=  debug1_wb_inst              ;
                cmt_tlbfill_en1  <= tlbfill_en1               ;
                cmt_rand_index1  <= rand_index1               ;
            // end
            // else cmt_valid1<=0;
            
            cmt_timer_64    <= timer_64_diff            ;

            cmt_inst_ld_en  <= inst_ld_en_diff          ;
            cmt_ld_paddr    <= ld_paddr_diff            ;
            cmt_ld_vaddr    <= ld_vaddr_diff            ;
            cmt_inst_st_en  <= inst_st_en_diff          ;
            cmt_st_paddr    <= st_paddr_diff            ;
            cmt_st_vaddr    <= st_vaddr_diff            ;
            cmt_st_data     <= st_data_diff             ;
            cmt_csr_rstat_en<= csr_rstat_en_diff        ;
            cmt_csr_data    <= csr_data_diff            ;

            cmt_excp_flush  <= excp_flush               ;
            cmt_ertn        <= ertn_flush               ;
            cmt_csr_ecode   <= ws_csr_ecode             ;

            trap            <= 0                        ;
            trap_code       <= regs[10][7:0]            ;
            cycleCnt        <= cycleCnt + 1             ;
            instrCnt        <= instrCnt + inst_valid_diff1;
        end
    end

    DifftestInstrCommit DifftestInstrCommit0(
        .clock              (aclk           ),
        .coreid             (0              ),
        .index              (1              ),
        .valid              (cmt_valid0      ),
        .pc                 (cmt_pc0         ),
        .instr              (cmt_inst0       ),
        .skip               (0              ),
        .is_TLBFILL         (cmt_tlbfill_en0 ),
        .TLBFILL_index      (cmt_rand_index0 ),
        .is_CNTinst         (cmt_cnt_inst0   ),
        .timer_64_value     (cmt_timer_64   ),
        .wen                (cmt_wen0        ),
        .wdest              (cmt_wdest0      ),
        .wdata              (cmt_wdata0      ),
        .csr_rstat          (cmt_csr_rstat_en),
        .csr_data           (cmt_csr_data   )
    );

    DifftestInstrCommit DifftestInstrCommit1(
        .clock              (aclk           ),
        .coreid             (0              ),
        .index              (0              ),
        .valid              (cmt_valid1      ),
        .pc                 (cmt_pc1         ),
        .instr              (cmt_inst1       ),
        .skip               (0              ),
        .is_TLBFILL         (cmt_tlbfill_en1 ),
        .TLBFILL_index      (cmt_rand_index1 ),
        .is_CNTinst         (cmt_cnt_inst1   ),
        .timer_64_value     (cmt_timer_64   ),
        .wen                (cmt_wen1        ),
        .wdest              (cmt_wdest1      ),
        .wdata              (cmt_wdata1      ),
        .csr_rstat          (cmt_csr_rstat_en),
        .csr_data           (cmt_csr_data   )
    );

    DifftestExcpEvent DifftestExcpEvent(
        .clock              (aclk           ),
        .coreid             (0              ),
        .excp_valid         (cmt_excp_flush ),
        .eret               (cmt_ertn       ),
        .intrNo             (csr_estat_diff_0[12:2]),
        .cause              (cmt_csr_ecode  ),
        .exceptionPC        (cmt_pc         ),
        .exceptionInst      (cmt_inst       )
    );

    DifftestTrapEvent DifftestTrapEvent(
        .clock              (aclk           ),
        .coreid             (0              ),
        .valid              (trap           ),
        .code               (trap_code      ),
        .pc                 (cmt_pc         ),
        .cycleCnt           (cycleCnt       ),
        .instrCnt           (instrCnt       )
    );

    DifftestStoreEvent DifftestStoreEvent(
        .clock              (aclk           ),
        .coreid             (0              ),
        .index              (0              ),
        .valid              (cmt_inst_st_en ),
        .storePAddr         (cmt_st_paddr   ),
        .storeVAddr         (cmt_st_vaddr   ),
        .storeData          (cmt_st_data    )
    );

    DifftestLoadEvent DifftestLoadEvent(
        .clock              (aclk           ),
        .coreid             (0              ),
        .index              (0              ),
        .valid              (cmt_inst_ld_en ),
        .paddr              (cmt_ld_paddr   ),
        .vaddr              (cmt_ld_vaddr   )
    );

    DifftestCSRRegState DifftestCSRRegState(
        .clock              (aclk               ),
        .coreid             (0                  ),
        .crmd               (csr_crmd_diff_0    ),
        .prmd               (csr_prmd_diff_0    ),
        .euen               (0                  ),
        .ecfg               (csr_ectl_diff_0    ),
        .estat              (csr_estat_diff_0   ),
        .era                (csr_era_diff_0     ),
        .badv               (csr_badv_diff_0    ),
        .eentry             (csr_eentry_diff_0  ),
        .tlbidx             (csr_tlbidx_diff_0  ),
        .tlbehi             (csr_tlbehi_diff_0  ),
        .tlbelo0            (csr_tlbelo0_diff_0 ),
        .tlbelo1            (csr_tlbelo1_diff_0 ),
        .asid               (csr_asid_diff_0    ),
        .pgdl               (csr_pgdl_diff_0    ),
        .pgdh               (csr_pgdh_diff_0    ),
        .save0              (csr_save0_diff_0   ),
        .save1              (csr_save1_diff_0   ),
        .save2              (csr_save2_diff_0   ),
        .save3              (csr_save3_diff_0   ),
        .tid                (csr_tid_diff_0     ),
        .tcfg               (csr_tcfg_diff_0    ),
        .tval               (csr_tval_diff_0    ),
        .ticlr              (csr_ticlr_diff_0   ),
        .llbctl             (csr_llbctl_diff_0  ),
        .tlbrentry          (csr_tlbrentry_diff_0),
        .dmw0               (csr_dmw0_diff_0    ),
        .dmw1               (csr_dmw1_diff_0    )
    );

    DifftestGRegState DifftestGRegState(
        .clock              (aclk       ),
        .coreid             (0          ),
        .gpr_0              (0          ),
        .gpr_1              (regs[1]    ),
        .gpr_2              (regs[2]    ),
        .gpr_3              (regs[3]    ),
        .gpr_4              (regs[4]    ),
        .gpr_5              (regs[5]    ),
        .gpr_6              (regs[6]    ),
        .gpr_7              (regs[7]    ),
        .gpr_8              (regs[8]    ),
        .gpr_9              (regs[9]    ),
        .gpr_10             (regs[10]   ),
        .gpr_11             (regs[11]   ),
        .gpr_12             (regs[12]   ),
        .gpr_13             (regs[13]   ),
        .gpr_14             (regs[14]   ),
        .gpr_15             (regs[15]   ),
        .gpr_16             (regs[16]   ),
        .gpr_17             (regs[17]   ),
        .gpr_18             (regs[18]   ),
        .gpr_19             (regs[19]   ),
        .gpr_20             (regs[20]   ),
        .gpr_21             (regs[21]   ),
        .gpr_22             (regs[22]   ),
        .gpr_23             (regs[23]   ),
        .gpr_24             (regs[24]   ),
        .gpr_25             (regs[25]   ),
        .gpr_26             (regs[26]   ),
        .gpr_27             (regs[27]   ),
        .gpr_28             (regs[28]   ),
        .gpr_29             (regs[29]   ),
        .gpr_30             (regs[30]   ),
        .gpr_31             (regs[31]   )
    );
`endif
endmodule
