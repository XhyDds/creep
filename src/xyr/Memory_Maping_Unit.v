module Memory_Maping_Unit#(
    parameter TLB_n=5,TLB_PALEN=32,TLB_VALEN=32
)(
    input clk,rstn,
    input [3:0] pipeline_MMU_type,
    input [4:0] pipeline_MMU_subtype,
    input [15:0] pipeline_MMU_excp_arg,
    input [31:0] pipeline_MMU_rj,
    input [31:0] pipeline_MMU_rk,
    input [8:0] pipeline_MMU_CRMD,
    input [9:0] pipeline_MMU_ASID,
    input [31:0] pipeline_MMU_DMW0,
    input [31:0] pipeline_MMU_DMW1,
    
    input pipeline_MMU_stallw,
    input pipeline_MMU_flushw,
    output [31:0] MMU_pipeline_TLBIDX,
    output [31:0] MMU_pipeline_TLBEHI,
    output [31:0] MMU_pipeline_TLBELO0,
    output [31:0] MMU_pipeline_TLBELO1,
    output [9:0] MMU_pipeline_ASID,
    input [31:0] pipeline_MMU_TLBIDX,
    input [31:0] pipeline_MMU_TLBEHI,
    input [31:0] pipeline_MMU_TLBELO0,
    input [31:0] pipeline_MMU_TLBELO1,

    input pipeline_MMU_stall0,
    input pipeline_MMU_flush0,
    input [1:0] pipeline_MMU_optype0,//0-fetch 1-load 2-store
    input pipeline_MMU_VADDR_valid0,
    input [31:0] pipeline_MMU_VADDR0,
    output [31:0] MMU_pipeline_PADDR0,
    output [15:0] MMU_pipeline_excp_arg0,//valid,subcode,code
    output [1:0] MMU_pipeline_memtype0,
    
    input pipeline_MMU_stall1,
    input pipeline_MMU_flush1,
    input [1:0] pipeline_MMU_optype1,//0-fetch 1-load 2-store
    input pipeline_MMU_VADDR_valid1,
    input [31:0] pipeline_MMU_VADDR1,
    output [31:0] MMU_pipeline_PADDR1,
    output [15:0] MMU_pipeline_excp_arg1,
    output [1:0] MMU_pipeline_memtype1
    
);
    localparam TLB_nex=(1<<TLB_n)-1;
    localparam MMU=11,PRIV_MMU=10;
    localparam TLBSRCH=1,TLBRD=2,TLBWR=3,TLBFILL=4,INVTLB=5;
    localparam FETCH=0,LOAD=1,STORE=2;
    localparam INT=6'H0,PIL=6'H1,PIS=6'H2,PIF=6'H3,PME=6'H4,PPI=6'H7,
    ADE=6'H8,ALE=6'H9,SYS=6'HB,BRK=6'HC,INE=6'HD,IPE=6'HE,FPD=6'HF,
    FPE=6'H12,TLBR=6'H3F;
    localparam ADEF=9'H0,ADEM=9'H1,DEFAULT=9'H0;
    
    
    wire [31:0]VADDR0,VADDR1;
    wire [1:0]optype0,optype1;//reg [1:0] optype0_reg,optype1_reg;
    wire [31:0]PADDR0,PADDR1;reg [15:0]excp_arg0,excp_arg1;
    wire [1:0]memtype0,memtype1;wire VADDR_valid0,VADDR_valid1;
    wire CRMD_DAok;
    wire DMW0_VADDR0ok,DMW0_VADDR1ok,DMW1_VADDR0ok,DMW1_VADDR1ok;
    wire optype0_f,optype1_f;
    //reg VADDR_valid0_reg,VADDR_valid1_reg;//reg [31:0]temp0,temp1;  
    assign VADDR0=pipeline_MMU_VADDR0,optype0=pipeline_MMU_optype0;
    assign MMU_pipeline_PADDR0=PADDR0,MMU_pipeline_excp_arg0=excp_arg0;
    assign MMU_pipeline_memtype0=memtype0,VADDR_valid0=pipeline_MMU_VADDR_valid0;
    assign VADDR1=pipeline_MMU_VADDR1,optype1=pipeline_MMU_optype1;
    assign MMU_pipeline_PADDR1=PADDR1,MMU_pipeline_excp_arg1=excp_arg1;
    assign MMU_pipeline_memtype1=memtype1,VADDR_valid1=pipeline_MMU_VADDR_valid1;
    
    
    
    wire [8:0]CRMDin;wire [9:0]ASIDin;wire [31:0] DMW0in,DMW1in;
    wire stallw,flushw,stall0,flush0,stall1,flush1;
    wire [3:0] type_;wire [4:0] subtype; wire [31:0] rj,rk;wire [4:0] op;
    assign CRMDin=pipeline_MMU_CRMD,ASIDin=pipeline_MMU_ASID;
    assign DMW0in=pipeline_MMU_DMW0,DMW1in=pipeline_MMU_DMW1;
    assign DMW0_plvOK=(DMW0in[0]==1&&CRMDin[1:0]==0)||(DMW0in[3]==1&&CRMDin[1:0]==3);
    assign DMW1_plvOK=(DMW1in[0]==1&&CRMDin[1:0]==0)||(DMW1in[3]==1&&CRMDin[1:0]==3);
    assign stallw=pipeline_MMU_stallw,flushw=pipeline_MMU_flushw;
    assign stall0=pipeline_MMU_stall0,flush0=pipeline_MMU_flush0;
    assign stall1=pipeline_MMU_stall1,flush1=pipeline_MMU_flush1;
             
             
    assign CRMD_DAok=CRMDin[4:3]==2'b01;  
    assign optype0_f=optype0==FETCH;
    assign optype1_f=optype1==FETCH;
     
    //0·�����߼�
    assign DMW0_VADDR0ok=(DMW0in[31:29]==VADDR0[31:29])&DMW0_plvOK; 
    assign DMW1_VADDR0ok=(DMW1in[31:29]==VADDR0[31:29])&DMW1_plvOK;
    
    assign PADDR0[28:0]=VADDR0[28:0];
    assign PADDR0[31:29]=({3{CRMD_DAok}}&VADDR0[31:29]) | 
    ({3{~CRMD_DAok}} & ( ({3{DMW0_VADDR0ok}}&DMW0in[27:25]) | ({3{DMW1_VADDR0ok}}&DMW1in[27:25]) ) );
    assign memtype0=({2{CRMD_DAok}} & ( ({2{optype0_f}} & CRMDin[6:5]) | ({2{~optype0_f}} & CRMDin[8:7]) ) ) |
                    ({2{~CRMD_DAok}} & (({2{DMW0_VADDR0ok}}&DMW0in[5:4]) | ({2{DMW1_VADDR0ok}}&DMW1in[5:4]) ) );
//    always@(*)
//    begin
//    PADDR0=0;
//    memtype0=0;
//    if(CRMDin[4:3]==2'b01)//DA==1,PG==0
//        begin
//        PADDR0=0;
//        PADDR0=VADDR0;
//        if(optype0==FETCH)
//            memtype0=CRMDin[6:5];
//        else
//            memtype0=CRMDin[8:7];
//        end
//    else if(DMW0_plvOK && DMW0in[31:29]==VADDR0[31:29])
//        begin
//        PADDR0={DMW0in[27:25],VADDR0[28:0]};
//        memtype0=DMW0in[5:4];
//        end
//    else if(DMW1_plvOK && DMW1in[31:29]==VADDR0[31:29])
//        begin
//        PADDR0={DMW1in[27:25],VADDR0[28:0]};
//        memtype0=DMW1in[5:4];
//        end
//    end
    always@(*)
    begin
    if(flush0)
        begin
        excp_arg0=0;
        end
    else
        begin
        excp_arg0=0;
        if(CRMDin[4:3]==2'b01 || (DMW0_plvOK && DMW0in[31:29]==VADDR0[31:29]) || 
        (DMW1_plvOK && DMW1in[31:29]==VADDR0[31:29]))//DA==1,PG==0
            begin
            excp_arg0=0;
            end
        else if(CRMDin[1:0]!=0 && VADDR0[31]==1)
            begin
            if(optype0==FETCH)
                excp_arg0={VADDR_valid0,ADEF,ADE}; 
            else
                excp_arg0={VADDR_valid0,ADEM,ADE}; 
            end
        else
            excp_arg0=0;
       end 
    end
    
    //1·�����߼�
    assign DMW0_VADDR1ok=(DMW0in[31:29]==VADDR1[31:29])&DMW0_plvOK; 
    assign DMW1_VADDR1ok=(DMW1in[31:29]==VADDR1[31:29])&DMW1_plvOK;
    
    assign PADDR1[28:0]=VADDR1[28:0];
    assign PADDR1[31:29]=({3{CRMD_DAok}}&VADDR1[31:29]) | 
    ({3{~CRMD_DAok}} & ( ({3{DMW0_VADDR1ok}}&DMW0in[27:25]) | ({3{DMW1_VADDR1ok}}&DMW1in[27:25]) ) );
    assign memtype1=({2{CRMD_DAok}} & ( ({2{optype1_f}} & CRMDin[6:5]) | ({2{~optype1_f}} & CRMDin[8:7]) ) ) |
                    ({2{~CRMD_DAok}} & (({2{DMW0_VADDR1ok}}&DMW0in[5:4]) | ({2{DMW1_VADDR1ok}}&DMW1in[5:4]) ) );
//    always@(*)
//    begin
//    PADDR1=0;
//    memtype1=0;
//    if(CRMDin[4:3]==2'b01)//DA==1,PG==0
//        begin
//        PADDR1=0;
//        PADDR1=VADDR1;
//        if(optype1==FETCH)
//            memtype1=CRMDin[6:5];
//        else
//            memtype1=CRMDin[8:7];
//        end
//    else if(DMW0_plvOK && DMW0in[31:29]==VADDR1[31:29])
//        begin
//        PADDR1={DMW0in[27:25],VADDR1[28:0]};
//        memtype1=DMW0in[5:4];
//        end
//    else if(DMW1_plvOK && DMW1in[31:29]==VADDR1[31:29])
//        begin
//        PADDR1={DMW1in[27:25],VADDR1[28:0]};
//        memtype1=DMW1in[5:4];
//        end
//    end
    always@(*)
    begin
    if(flush1)
        begin
        excp_arg1=0;
        end
    else
        begin
        excp_arg1=0;
        if(CRMDin[4:3]==2'b01 || (DMW0_plvOK && DMW0in[31:29]==VADDR1[31:29]) || 
        (DMW1_plvOK && DMW1in[31:29]==VADDR1[31:29]))//DA==1,PG==0
            begin
            excp_arg1=0;
            end
        else if(CRMDin[1:0]!=0 && VADDR1[31]==1)
            begin
            if(optype1==FETCH)
                excp_arg1={VADDR_valid1,ADEF,ADE}; 
            else
                excp_arg1={VADDR_valid1,ADEM,ADE}; 
            end
        else
            excp_arg1=0;
       end 
    end
endmodule

