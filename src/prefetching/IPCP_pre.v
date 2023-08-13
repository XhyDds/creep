module IPCP_pre(
    input clk,rstn,
    input [31:0] IPaddr,
    input [31:0] visitaddr,
    input visitaddr_valid,
    output [31:0] preaddr,
    output preaddr_valid

);
    wire [8:0]IP_tagout;wire IP_vout,IP_svout,IP_drout;
    reg [8:0]IP_tagin;reg IP_vin,IP_svin,IP_drin;
    wire [1:0] IP_lvpout,IP_confout;wire [6:0] IP_lloffsetout,IP_sigout;
    reg [1:0] IP_lvpin,IP_confin;reg [6:0] IP_lloffsetin,IP_sigin;
    wire [7:0] IP_strout;wire [30:0] IP_dout;
    reg [7:0] IP_strin;wire [30:0] IP_din;
    reg [5:0] IP_waddr;wire [5:0] IP_raddr;reg IP_we;
    bram #(.DATA_WIDTH(31),.ADDR_WIDTH(6))IP_table(.clk(clk),.raddr(IP_raddr),
                    .waddr(IP_waddr),.din(IP_din),.dout(IP_dout),.we(IP_we));
    bram #(.DATA_WIDTH(7),.ADDR_WIDTH(6))IP_sigtable(.clk(clk),.raddr(IP_raddr),
                    .waddr(IP_sig_waddr),.din(IP_sig),.dout(IP_sig),.we(IP_sig_we));
    assign {IP_tagout,IP_vout,IP_lvpout,IP_lloffsetout,IP_strout,IP_confout,IP_svout,IP_drout}=IP_dout;
    assign IP_din={IP_tagin,IP_vin,IP_lvpin,IP_lloffsetin,IP_strin,IP_confin,IP_svin,IP_drin};
    assign IP_raddr=IPaddr[7:2];
    always@(posedge(clk))
    begin
    if(!rstn)
        begin
        IP_waddr<=0;
        IP_we<=0;
        end
    else
        begin
        IP_waddr<=IP_raddr;
        IP_we<=visitaddr_valid;
        end
    end
    always@(*)
    begin
    IP_tagin=IP_tagout;IP_vin=IP_vout;IP_lvpin=IP_lvpout;
    IP_lloffsetin=IP_lloffsetout;IP_strin=IP_strout;IP_confin=IP_confout;
    IP_svin=IP_svout;IP_drin=IP_drout;
    if(IP_tagout!=IPaddr[16:8])
        begin
        if(IP_vout)
            IP_vin=0;
        else
            begin
            IP_tagin=IPaddr[16:8];
            IP_vin=0;IP_lvpin=visitaddr[13:12];
            IP_lloffsetin=visitaddr[11:5];IP_strin=0;IP_confin=0;
            IP_svin=0;IP_drin=0;
            end
        end
     else if()
    end
    
    
    
endmodule

