module Memory_Maping_Unit#(//stall frist
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
    
    reg [TLB_VALEN-14:0] VPPN[0:TLB_nex];reg [5:0] PS[0:TLB_nex];
    reg G[0:TLB_nex];reg [9:0] ASID[0:TLB_nex];reg E[0:TLB_nex];
    reg [TLB_PALEN-13:0] PPN0[0:TLB_nex],PPN1[0:TLB_nex];
    reg [1:0] PLV0[0:TLB_nex],PLV1[0:TLB_nex];
    reg [1:0] MAT0[0:TLB_nex],MAT1[0:TLB_nex];
    reg D0[0:TLB_nex],D1[0:TLB_nex];reg V0[0:TLB_nex],V1[0:TLB_nex];
    
    wire [31:0]VADDR0,VADDR1;
    wire [1:0]optype0,optype1;//reg [1:0] optype0_reg,optype1_reg;
    reg [31:0]PADDR0,PADDR1;reg [15:0]excp_arg0,excp_arg1;
    reg [1:0]memtype0,memtype1;wire VADDR_valid0,VADDR_valid1;
    //reg VADDR_valid0_reg,VADDR_valid1_reg;//reg [31:0]temp0,temp1;
    reg TLB_found0,TLB_found1;reg [5:0] found_ps0,found_ps1;
    reg found_v0,found_d0,found_v1,found_d1;
    reg [1:0] found_mat0,found_plv0,found_mat1,found_plv1;
    reg [TLB_PALEN-13:0] found_ppn0,found_ppn1;
    wire [31:0] addrmask0,addrmask1;wire DMW0_plvOK,DMW1_plvOK;   
    assign VADDR0=pipeline_MMU_VADDR0,optype0=pipeline_MMU_optype0;
    assign MMU_pipeline_PADDR0=PADDR0,MMU_pipeline_excp_arg0=excp_arg0;
    assign MMU_pipeline_memtype0=memtype0,VADDR_valid0=pipeline_MMU_VADDR_valid0;
    assign VADDR1=pipeline_MMU_VADDR1,optype1=pipeline_MMU_optype1;
    assign MMU_pipeline_PADDR1=PADDR1,MMU_pipeline_excp_arg1=excp_arg1;
    assign MMU_pipeline_memtype1=memtype1,VADDR_valid1=pipeline_MMU_VADDR_valid1;
    
    
    
    reg [31:0] TLBIDXout,TLBEHIout,TLBELO0out,TLBELO1out;
    reg [31:0] TLBIDX,TLBEHI,TLBELO0,TLBELO1;
    reg [9:0] ASIDrd,ASIDout;
    wire [31:0] TLBIDXin,TLBEHIin,TLBELO0in,TLBELO1in;
    assign MMU_pipeline_TLBIDX=TLBIDXout,MMU_pipeline_TLBEHI=TLBEHIout;
    assign MMU_pipeline_TLBELO0=TLBELO0out,MMU_pipeline_TLBELO1=TLBELO1out;
    assign TLBIDXin=pipeline_MMU_TLBIDX,TLBEHIin=pipeline_MMU_TLBEHI;
    assign TLBELO0in=pipeline_MMU_TLBELO0,TLBELO1in=pipeline_MMU_TLBELO1;
    assign MMU_pipeline_ASID=ASIDout;
    
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
    assign type_=pipeline_MMU_type,subtype=pipeline_MMU_subtype;
    assign rj=pipeline_MMU_rj,rk=pipeline_MMU_rk;
    assign op=pipeline_MMU_excp_arg[4:0];
    
    wire exe;reg exe_reg;
    wire [TLB_n-1:0] Index,Index_tlbsch,Index_look0,Index_look1;
    reg [TLB_nex:0] found_tlbsch,look0,look1;
    assign exe=(type_==MMU||type_==PRIV_MMU);
    assign Index=TLBIDXin[TLB_n-1:0];
    
    encoder_2n_n  #(TLB_n)encoder_tlbsch(.din(found_tlbsch),.dout(Index_tlbsch));
    encoder_2n_n  #(TLB_n)encoder_look0(.din(look0),.dout(Index_look0));
    encoder_2n_n  #(TLB_n)encoder_look1(.din(look1),.dout(Index_look1));
    
    always@(posedge(clk))
    begin
    if(!rstn || (flushw && !stallw))
        begin
        TLBIDXout<=0;TLBEHIout<=0;
        TLBELO0out<=0;TLBELO1out<=0;
        ASIDout<=0;exe_reg<=0;
        //optype0_reg<=0;optype1_reg<=0;
        end
    else if(~stallw)
        begin
        TLBIDXout<=TLBIDX;TLBEHIout<=TLBEHI;
        TLBELO0out<=TLBELO0;TLBELO1out<=TLBELO1;
        ASIDout<=ASIDrd;exe_reg<=exe;
        //optype0_reg<=optype0;optype1_reg<=optype1;
        end
    end
    
    genvar i;
    generate
    for(i=0;i<=TLB_nex;i=i+1)
        begin:gen_tlbsch
        always@(*)
        begin
        found_tlbsch[i]=1'b0;
        if((ASID[i]==ASIDin || G[i]==1) && ({VPPN[i],12'b0}>>PS[i])==(TLBEHIin[31:1]>>PS[i]) && E[i]==1)//VPPNlow
            found_tlbsch[i]=1'b1;
        else
            found_tlbsch[i]=1'b0;
        end
        end
    endgenerate
    
    always@(*)
    begin
    TLBIDX=TLBIDXin;TLBEHI=TLBEHIin;
    TLBELO0=TLBELO0in;TLBELO1=TLBELO1in;
    ASIDrd=ASIDin;
    if(exe)
       begin
       case(subtype)
           TLBSRCH:
               begin
               TLBIDX[31]=1;//NE
               if(|found_tlbsch)//hit
                    begin
                    TLBIDX[31]=0;
                    TLBIDX[TLB_n-1:0]=Index_tlbsch;//Index
                    end
               end
           TLBRD:
               if(E[Index])//E[Index]==1
                   begin
                   TLBIDX[31]=0;//NE
                   TLBEHI[31:13]=VPPN[Index];
                   TLBELO0[6:0]={G[Index],MAT0[Index],PLV0[Index],D0[Index],V0[Index]};
                   TLBELO0[TLB_PALEN-5:8]=PPN0[Index];
                   TLBELO1[6:0]={G[Index],MAT1[Index],PLV1[Index],D1[Index],V1[Index]};
                   TLBELO1[TLB_PALEN-5:8]=PPN1[Index];
                   TLBIDX[29:24]=PS[Index];
                   ASIDrd=ASID[Index];
                   end
               else
                   begin
                   TLBIDX[31]=1;
                   TLBEHI[31:13]=0;
                   TLBELO0=0;
                   TLBELO1=0;
                   TLBIDX[30:0]=0;
                   ASIDrd=0;
                   end
       endcase 
       end
    end
    
    always@(posedge(clk))
    begin
    if(exe_reg && ~stallw && ~flushw && (subtype==TLBWR || subtype==TLBFILL))
        begin
        PS[Index]<=TLBIDXin[29:24];
        VPPN[Index]<=TLBEHIin[31:13];
        {MAT0[Index],PLV0[Index],D0[Index],V0[Index]}<=TLBELO0in[5:0];
        PPN0[Index]<=TLBELO0in[TLB_PALEN-5:8];
        {MAT1[Index],PLV1[Index],D1[Index],V1[Index]}<=TLBELO1in[5:0];
        PPN1[Index]<=TLBELO1in[TLB_PALEN-5:8];
        G[Index]<=TLBELO1in[6]&TLBELO0in[6];
        ASID[Index]<=ASIDin;
        end
    end
    genvar j;
    generate
    for(j=0;j<=TLB_nex;j=j+1)
        begin:gen_E
        always@(posedge(clk))
        begin
        if(exe_reg && ~stallw && ~flushw)
            if(Index==j && (subtype==TLBWR || subtype==TLBFILL))
                begin
                E[j]<=~TLBIDXin[31];
                end
            else if(subtype==INVTLB)
                begin
                case(op)
                    5'h0,5'h1:
                        begin
                        E[j]<=0;
                        end
                    5'h2:
                        begin
                        if(G[j])//G[j]==1
                            begin
                            E[j]<=0;
                            end
                        end
                    5'h3:
                        begin
                        if(~G[j])//G[j]==0
                            begin
                            E[j]<=0;
                            end
                        end
                    5'h4:
                        begin
                        if(~G[j] && ASID[j]==rj[9:0])//G[j]==0
                            begin
                            E[j]<=0;
                            end
                        end
                    5'h5:
                        begin
                        if(~G[j] && ASID[j]==rj[9:0] && ({1'b0,VPPN[j],12'b0}>>PS[j])==(rk>>PS[j]+1))//G[j]==0
                            begin
                            E[j]<=0;
                            end
                        end
                    5'h6:
                        begin
                        if((G[j] || ASID[j]==rj[9:0]) && ({1'b0,VPPN[j],12'b0}>>PS[j])==(rk>>PS[j]+1))//G[j]==1
                            begin
                            E[j]<=0;
                            end
                        end
                
                endcase
                end
        end
        end
    endgenerate
    
    //0·�����߼�
    generate
    for(i=0;i<=TLB_nex;i=i+1)
        begin:gen_look0
        always@(*)
        begin
        look0[i]=1'b0;
        if(E[i]==1&&(G[i]==1||ASID[i]==ASIDin)&&({VPPN[i],12'b0}>>PS[i])==(VADDR0[31:1]>>PS[i]))//ȥ��λ�Ƚϣ�VPPNҪ��13λΪ��ȷ��ַ
            look0[i]=1'b1;
        else
            look0[i]=1'b0;
        end
        end
    endgenerate
    
    always@(*)
    begin
//    TLB_found0=0;
//    found_v0=0;found_d0=0;
//    found_mat0=0;found_plv0=0;
//    found_ppn0=0;found_ps0=0;
    TLB_found0=|look0;       
    found_ps0=PS[Index_look0];
    if(|((VADDR0>>found_ps0)&32'b1))//VLow==1
        begin
        found_v0=V1[Index_look0];found_d0=D1[Index_look0];
        found_mat0=MAT1[Index_look0];found_plv0=PLV1[Index_look0];
        found_ppn0=PPN1[Index_look0];
        end
    else
        begin
        found_v0=V0[Index_look0];found_d0=D0[Index_look0];
        found_mat0=MAT0[Index_look0];found_plv0=PLV0[Index_look0];
        found_ppn0=PPN0[Index_look0];
        end
    end
    assign addrmask0=(~0)<<found_ps0;
    always@(posedge(clk))
    begin
    if(!rstn || flush0)//flush first
        begin
        PADDR0<=0;excp_arg0<=0;
        memtype0<=0;
        end
    else if(~stall0)
        begin
        PADDR0<=({found_ppn0,12'b0}&addrmask0)|(VADDR0&~addrmask0);
        memtype0<=found_mat0;
        excp_arg0<=0;
        if(CRMDin[4:3]==2'b01)//DA==1,PG==0
            begin
            PADDR0<=0;
            PADDR0<=VADDR0;
            excp_arg0<=0;
            if(optype0==FETCH)
                memtype0<=CRMDin[6:5];
            else
                memtype0<=CRMDin[8:7];
            end
        else if(DMW0_plvOK && DMW0in[31:29]==VADDR0[31:29])
            begin
            PADDR0<={DMW0in[27:25],VADDR0[28:0]};
            memtype0<=DMW0in[5:4];
            excp_arg0<=0;
            end
        else if(DMW1_plvOK && DMW1in[31:29]==VADDR0[31:29])
            begin
            PADDR0<={DMW1in[27:25],VADDR0[28:0]};
            memtype0<=DMW1in[5:4];
            excp_arg0<=0;
            end
        else if(CRMDin[1:0]!=0 && VADDR0[31]==1)
            begin
            if(optype0==FETCH)
                excp_arg0<={VADDR_valid0,ADEF,ADE}; 
            else
                excp_arg0<={VADDR_valid0,ADEM,ADE}; 
            end
        else if(TLB_found0==0)
            begin
            excp_arg0<={VADDR_valid0,DEFAULT,TLBR};
            end
        else if(found_v0==0)
            case(optype0)
                FETCH:
                   excp_arg0<={VADDR_valid0,DEFAULT,PIF}; 
                LOAD:
                    excp_arg0<={VADDR_valid0,DEFAULT,PIL};
                STORE:
                    excp_arg0<={VADDR_valid0,DEFAULT,PIS};
            endcase
        else if(CRMDin[1:0]>found_plv0)
            excp_arg0<={VADDR_valid0,DEFAULT,PPI};
        else if(optype0==STORE&&found_d0==0)
            excp_arg0<={VADDR_valid0,DEFAULT,PME};
        else
            excp_arg0<=0;
       end 
    end
    
    //1·�����߼�
    generate
    for(i=0;i<=TLB_nex;i=i+1)
        begin:gen_look1
        always@(*)
        begin
        look1[i]=1'b0;
        if(E[i]==1&&(G[i]==1||ASID[i]==ASIDin)&&({VPPN[i],12'b0}>>PS[i])==(VADDR1[31:1]>>PS[i]))//ȥ��λ�Ƚϣ�VPPNҪ��13λΪ��ȷ��ַ
            look1[i]=1'b1;
        else
            look1[i]=1'b0;
        end
        end
    endgenerate
    
    always@(*)
    begin
//    TLB_found1=0;
//    found_v1=0;found_d1=0;
//    found_mat1=0;found_plv1=0;
//    found_ppn1=0;found_ps1=0;
    TLB_found1=|look1;       
    found_ps1=PS[Index_look1];
    if(|((VADDR1>>found_ps1)&32'b1))//VLow==1
        begin
        found_v1=V1[Index_look1];found_d1=D1[Index_look1];
        found_mat1=MAT1[Index_look1];found_plv1=PLV1[Index_look1];
        found_ppn1=PPN1[Index_look1];
        end
    else
        begin
        found_v1=V0[Index_look1];found_d1=D0[Index_look1];
        found_mat1=MAT0[Index_look1];found_plv1=PLV0[Index_look1];
        found_ppn1=PPN0[Index_look1];
        end
    end
    assign addrmask1=(~0)<<found_ps1;
    always@(posedge(clk))
    begin
    if(!rstn || (flush1&&!stall1))
        begin
        PADDR1<=0;excp_arg1<=0;
        memtype1<=0;
        end
    else if(~stall1)
        begin
        PADDR1<=({found_ppn1,12'b0}&addrmask1)|(VADDR1&~addrmask1);
        memtype1<=found_mat1;
        excp_arg1<=0;
        if(CRMDin[4:3]==2'b01)//DA==1,PG==0
            begin
            PADDR1<=0;
            PADDR1<=VADDR1;
            excp_arg1<=0;
            if(optype1==FETCH)
                memtype1<=CRMDin[6:5];
            else
                memtype1<=CRMDin[8:7];
            end
        else if(DMW0_plvOK && DMW0in[31:29]==VADDR1[31:29])
            begin
            PADDR1<={DMW0in[27:25],VADDR1[28:0]};
            memtype1<=DMW0in[5:4];
            excp_arg1<=0;
            end
        else if(DMW1_plvOK && DMW1in[31:29]==VADDR1[31:29])
            begin
            PADDR1<={DMW1in[27:25],VADDR1[28:0]};
            memtype1<=DMW1in[5:4];
            excp_arg1<=0;
            end
        else if(CRMDin[1:0]!=0 && VADDR1[31]==1)
            begin
            if(optype1==FETCH)
                excp_arg1<={VADDR_valid1,ADEF,ADE}; 
            else
                excp_arg1<={VADDR_valid1,ADEM,ADE}; 
            end
        else if(TLB_found1==0)
            begin
            excp_arg1<={VADDR_valid1,DEFAULT,TLBR};
            end
        else if(found_v1==0)
            case(optype1)
                FETCH:
                   excp_arg1<={VADDR_valid1,DEFAULT,PIF}; 
                LOAD:
                    excp_arg1<={VADDR_valid1,DEFAULT,PIL};
                STORE:
                    excp_arg1<={VADDR_valid1,DEFAULT,PIS};
            endcase
        else if(CRMDin[1:0]>found_plv1)
            excp_arg1<={VADDR_valid1,DEFAULT,PPI};
        else if(optype1==STORE&&found_d1==0)
            excp_arg1<={VADDR_valid1,DEFAULT,PME};
        else 
            excp_arg1<=0;    
        
        end
    end
endmodule

module encoder_2n_n#(
    parameter n=7
)(
    input [(1<<n)-1:0] din,
    output reg [n-1:0] dout
);
    integer i;
    always@(*)
    begin
    dout=0;
    for(i=0;i<(1<<n);i=i+1)
        begin
        if(din[i])
            dout=i;
        end
    end

endmodule






