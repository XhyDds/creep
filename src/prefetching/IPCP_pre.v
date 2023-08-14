module IPCP_pre(
    input clk,rstn,
    input [31:0] IPaddr,
    input [31:0] visitaddr,
    input visitaddr_valid,
    output [31:0] preaddr,
    output preaddr_valid

);
    localparam NL=0,CS=1,CPLX=2,GS=3;
     reg [1:0] ntype0,type0,ntype1,type1,ntype2,type2;
    //reg [26:0] npreaddr0,preaddr0,npreaddr1,preaddr1,npreaddr2,preaddr2;
    reg [7:0] nstride0,stride0,nstride1,stride1;
    reg [31:5] visitaddr0,visitaddr1;reg vaddrvalid0,vaddrvalid1;
    reg [31:0] IPaddr0,IPaddr1;
    wire [31:0] IP_dout,IP_din;
    wire [8:0]IP_tagout;wire IP_vout,IP_svout,IP_teout,IP_drout;
    reg [8:0]IP_tagin;reg IP_vin,IP_svin,IP_tein,IP_drin;
    wire [1:0] IP_lvpout,IP_confout;wire [6:0] IP_lloffsetout;
    reg [1:0] IP_lvpin,IP_confin;reg [6:0] IP_lloffsetin;
    wire [7:0] IP_strout;
    reg [7:0] IP_strin;
    wire [5:0] IP_raddr,IP_waddr;
    bram #(.DATA_WIDTH(32),.ADDR_WIDTH(6))IP_table(.clk(clk),.raddr(IP_raddr),
                    .waddr(IP_waddr),.din(IP_din),.dout(IP_dout),.we(vaddrvalid0));
    
    assign {IP_tagout,IP_vout,IP_lvpout,IP_lloffsetout,IP_strout,IP_confout,IP_svout,IP_teout,IP_drout}=IP_dout;
    assign IP_din={IP_tagin,IP_vin,IP_lvpin,IP_lloffsetin,IP_strin,IP_confin,IP_svin,IP_tein,IP_drin};
    assign IP_raddr=IPaddr[7:2],IP_waddr=IPaddr0[7:2];
    
    wire [5:0] IP_sig_waddr;
    wire [6:0] IP_sigout;reg [6:0] IP_sigin;
    wire IP_sig_we;
    bram #(.DATA_WIDTH(7),.ADDR_WIDTH(6))IP_sigtable(.clk(clk),.raddr(IP_raddr),
                    .waddr(IP_sig_waddr),.din(IP_sigin),.dout(IP_sigout),.we(IP_sig_we));
    assign IP_sig_we=type1==CPLX&&vaddrvalid1;
    
    wire [99:0] RST_din,RST_dout; wire [3:0] RST_raddr,RST_waddr;reg RST_we;
    wire [9:0] RST_tagout; wire [5:0] RST_vout,RST_lloffsetout,RST_pncout,RST_deout; wire [63:0] RST_bvout;
    wire RST_trout,RST_drout;
    reg [9:0] RST_tagin;reg [5:0] RST_vin,RST_lloffsetin,RST_pncin,RST_dein; reg [63:0] RST_bvin;
    reg RST_trin,RST_drin;
    bram #(.DATA_WIDTH(100),.ADDR_WIDTH(4))RST_table(.clk(clk),.raddr(RST_raddr),
            .waddr(RST_waddr),.din(RST_din),.dout(RST_dout),.we(vaddrvalid0));
    assign {RST_tagout,RST_vout,RST_lloffsetout,RST_bvout,RST_pncout,RST_deout,RST_trout,RST_drout}=RST_dout;
    assign RST_din={RST_tagin,RST_vin,RST_lloffsetin,RST_bvin,RST_pncin,RST_dein,RST_trin,RST_drin};
    assign RST_raddr=visitaddr[14:11],RST_waddr=visitaddr0[14:11];
    
    wire [6:0] CSPT_raddr;reg [6:0] CSPT_waddr;wire [9:0]CSPT_din,CSPT_dout;wire CSPT_we;
    wire [7:0] CSPT_strout;wire [1:0] CSPT_confout;
    reg [7:0] CSPT_strin;reg [1:0] CSPT_confin;
    bram #(.DATA_WIDTH(10),.ADDR_WIDTH(7))CSPT_table(.clk(clk),.raddr(CSPT_raddr),
            .waddr(CSPT_waddr),.din(CSPT_din),.dout(CSPT_dout),.we(CSPT_we));
    assign {CSPT_strout,CSPT_confout}=CSPT_dout;
    assign CSPT_din={CSPT_strin,CSPT_confin};
    assign CSPT_we=type1==CPLX&&vaddrvalid1;
    assign CSPT_raddr=IPaddr0==IPaddr1?IP_sigin:IP_sigout;
    
    always@(posedge(clk))
    begin
    if(!rstn)
        begin
        visitaddr0<=0;
        IPaddr0<=0;
        IPaddr1<=0;
        stride1<=0;
        vaddrvalid0<=0;
        vaddrvalid1<=0;
        CSPT_waddr<=0;
        end
    else
        begin
        visitaddr0<=visitaddr[31:5];
        IPaddr0<=IPaddr;
        IPaddr1<=IPaddr0;
        vaddrvalid0<=visitaddr_valid;
        vaddrvalid1<=vaddrvalid0;
        stride1<=nstride1;
        CSPT_waddr<=CSPT_raddr;
        end
    end
    //IP_table
    always@(*)
    begin
    IP_tagin=IP_tagout;IP_vin=IP_vout;IP_lvpin=IP_lvpout;
    IP_lloffsetin=IP_lloffsetout;IP_strin=IP_strout;IP_confin=IP_confout;
    IP_svin=IP_svout;IP_tein=IP_teout;IP_drin=IP_drout;type0=NL;
    stride0=visitaddr0[13:5]-{IP_lvpout,IP_lloffsetout};//7:0=8:0
    if(IP_tagout!=IPaddr0[16:8])
        begin
        if(IP_vout)
            IP_vin=0;
        else
            begin
            IP_tagin=IPaddr0[16:8];
            IP_vin=0;IP_lvpin=visitaddr0[13:12];
            IP_lloffsetin=visitaddr0[11:5];IP_strin=0;IP_confin=0;
            IP_svin=0;IP_drin=0;
            end
        end
     else
        begin
        IP_vin=1;
        IP_lvpin=visitaddr0[13:12];
        IP_lloffsetin=visitaddr0[11:5];
        IP_tein=~RST_trout;
        if(RST_trout&&RST_tagout==visitaddr0[24:15])//GS update,RST effective
            begin
            IP_svin=1;
            IP_drin=RST_drout;
            end
        else if(visitaddr0[13:12]!=IP_lvpout&&IP_teout)
            begin
            IP_svin=0;
            end
        if(IP_svout)//GS
            begin
            type0=GS;
            stride0={{7{IP_drout}},1'b1};
            end
        else 
            begin
            if(stride0!=IP_strout&&|IP_confout)
                IP_confin=IP_confout-1;
            if(stride0==IP_strout&&~(&IP_confout))
                IP_confin=IP_confout+1;
            if(!IP_confout)
                IP_strin=stride0;
            if(IP_confout[1])//CS,conf>1
                begin
                type0=CS;
                end
            else
                type0=CPLX;//CPLX
            end
        end
    end
    //RST
    always@(*)
    begin
    RST_tagin=RST_tagout;RST_vin=RST_vout;RST_lloffsetin=RST_lloffsetout;RST_bvin=RST_bvout;
    RST_pncin=RST_pncout;RST_dein=RST_deout;RST_trin=RST_trout;RST_drin=RST_drout;
    if(RST_tagout!=visitaddr0[24:15])
        begin
        if(RST_vout==0)
            begin
            RST_tagin=visitaddr0[24:15];
            RST_lloffsetin=visitaddr0[10:5];
            RST_bvin=64'b0;RST_pncin={1'b1,5'b0};
            RST_dein=0;RST_trin=0;RST_drin=1'b1;
            end
        else
            RST_vin=RST_vout-1;
        end
    else
        begin
        if(~(&RST_vout))
            RST_vin=RST_vout+1;
        RST_lloffsetin=visitaddr0[10:5];
        RST_bvin=RST_bvout|(64'b1<<visitaddr0[10:5]);
        if(RST_pncout!=0&&visitaddr0[10:5]<RST_lloffsetout)
            RST_pncin=RST_pncout-1;//[5]1 pos 0 neg
        else if(!(&RST_pncout)&&visitaddr0[10:5]>RST_lloffsetout)
            RST_pncin=RST_pncout+1;
        if(!(RST_bvout&(64'b1<<visitaddr0[10:5])))
            RST_dein=RST_deout+1;
        RST_trin=RST_trout|(&RST_deout[5:4]);
        RST_drin=~RST_pncin[5];//1 neg 0 pos
        end
    
    end
    
    //CSPT
    always@(*)
    begin
    
    end
    
endmodule

