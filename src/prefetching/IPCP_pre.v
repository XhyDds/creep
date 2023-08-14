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
    reg [31:5] visitaddr0,visitaddr1;
    reg [31:0] IPaddr0;
    wire [8:0]IP_tagout;wire IP_vout,IP_svout,IP_drout;
    reg [8:0]IP_tagin;reg IP_vin,IP_svin,IP_drin;
    wire [1:0] IP_lvpout,IP_confout;wire [6:0] IP_lloffsetout,IP_sigout;
    reg [1:0] IP_lvpin,IP_confin;reg [6:0] IP_lloffsetin,IP_sigin;
    wire [7:0] IP_strout;wire [30:0] IP_dout;
    reg [7:0] IP_strin;wire [30:0] IP_din;
    wire [5:0] IP_raddr,IP_waddr;reg IP_we;
   
    bram #(.DATA_WIDTH(31),.ADDR_WIDTH(6))IP_table(.clk(clk),.raddr(IP_raddr),
                    .waddr(IP_waddr),.din(IP_din),.dout(IP_dout),.we(IP_we));
    bram #(.DATA_WIDTH(7),.ADDR_WIDTH(6))IP_sigtable(.clk(clk),.raddr(IP_raddr),
                    .waddr(IP_sig_waddr),.din(IP_sigin),.dout(IP_sigout),.we(IP_sig_we));
    assign {IP_tagout,IP_vout,IP_lvpout,IP_lloffsetout,IP_strout,IP_confout,IP_svout,IP_drout}=IP_dout;
    assign IP_din={IP_tagin,IP_vin,IP_lvpin,IP_lloffsetin,IP_strin,IP_confin,IP_svin,IP_drin};
    assign IP_raddr=IPaddr[7:2],IP_waddr=IPaddr0[7:2];
    
    wire [89:0] RST_din,RST_dout; wire [3:0] RST_raddr,RST_waddr;reg RST_we;
    wire [8:0] RST_tagout; wire [5:0] RST_lloffsetout,RST_pncout; wire [63:0] RST_bvout;
    wire RST_vout,RST_deout,RST_trout,RST_teout,RST_drout;
    reg [8:0] RST_tagin;reg [5:0] RST_lloffsetin,RST_pncin; reg [63:0] RST_bvin;
    reg RST_vin,RST_dein,RST_trin,RST_tein,RST_drin;
    bram #(.DATA_WIDTH(90),.ADDR_WIDTH(4))RST_table(.clk(clk),.raddr(RST_raddr),
            .waddr(RST_waddr),.din(RST_din),.dout(RST_dout),.we(RST_we));
    assign {RST_tagout,RST_vout,RST_lloffsetout,RST_bvout,RST_pncout,RST_deout,RST_trout,RST_teout,RST_drout}=RST_dout;
    assign RST_din={RST_tagin,RST_vin,RST_lloffsetin,RST_bvin,RST_pncin,RST_dein,RST_trin,RST_tein,RST_drin};
    assign RST_raddr=visitaddr[15:12],RST_waddr=visitaddr0[15:12];
    
    always@(posedge(clk))
    begin
    if(!rstn)
        begin
        visitaddr0<=0;
        IPaddr0<=0;
        IP_we<=0;
        RST_we<=0;
        end
    else
        begin
        visitaddr0<=visitaddr[31:5];
        IPaddr0<=IPaddr;
        IP_we<=visitaddr_valid;
        RST_we<=visitaddr_valid;
        end
    end
    //IP_table
    always@(*)
    begin
    IP_tagin=IP_tagout;IP_vin=IP_vout;IP_lvpin=IP_lvpout;
    IP_lloffsetin=IP_lloffsetout;IP_strin=IP_strout;IP_confin=IP_confout;
    IP_svin=IP_svout;IP_drin=IP_drout;ntype0=NL;
    nstride0=visitaddr[13:5]-{IP_lvpout,IP_lloffsetout};//7:0=8:0
    if(IP_tagout!=IPaddr0[16:8])
        begin
        if(IP_vout)
            IP_vin=0;
        else
            begin
            IP_tagin=IPaddr0[16:8];
            IP_vin=0;IP_lvpin=visitaddr[13:12];
            IP_lloffsetin=visitaddr[11:5];IP_strin=0;IP_confin=0;
            IP_svin=0;IP_drin=0;
            end
        end
     else
        begin
        IP_vin=1;
        IP_lvpin=visitaddr[13:12];
        IP_lloffsetin=visitaddr[11:5];
        if(IP_svout)//GS
            begin
            ntype0=GS;
            nstride0={{7{IP_drout}},1'b1};
            IP_drin=RST_drout;///////
            end
        else 
            begin
            if(nstride0!=IP_strout&&|IP_confout)
                IP_confin=IP_confout-1;
            if(nstride0==IP_strout&&~(&IP_confout))
                IP_confin=IP_confout+1;
            if(!IP_confout)
                IP_strin=nstride0;
            if(IP_confout[1])//CS,conf>1
                begin
                ntype0=CS;
                end
            else
                ntype0=CPLX;
            end
        end
    end
    
    
    
endmodule

