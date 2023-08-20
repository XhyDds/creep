module IPCP_buff#(
    parameter Bufferlen=3
)(
    //lauch
    input clk,rstn,
    input [31:5] baseaddr,
    input [7:0] stridein,
    input [1:0] typein,
    input [6:0] IPsigin,
    //lookup
    output reg [6:0] CSPT_lookaddr,
    input [9:0] CSPT_datain,
    //hitcount
    input visithit,
    input [2:0] hitype,
    //cache
    output reg req,
    output reg [2:0] reqtype,
    output reg [31:0] reqaddr,
    input reqcomp
    
);
    localparam NL=0,CS=1,CPLX=2,GS=3;
    localparam CS_max=6,CPLX_max=6,GS_max=9;
    localparam Idle=0,Req=1,Getnaddr=2;
    reg [Bufferlen-1:0] headp,tailp,ntailp;reg [43:0] buffer[0:(1<<Bufferlen)-1];
    wire [43:0] buff_din,buff_dout;reg [3:0] ns,cs;reg [3:0] prenum,nprenum;
    reg [1:0] typenow,ntypenow;reg [31:5] addrnow,naddrnow;
    reg [7:0] stridenow,nstridenow;reg [6:0] IPsignow,nIPsignow;
    assign buff_din={typein,IPsigin,stridein,baseaddr};
    assign buff_dout=buffer[tailp];
    
    reg [7:0] tcoun_CS,hcoun_CS,tcoun_CPLX,hcoun_CPLX,tcoun_GS,hcoun_GS;
    reg [3:0] CS_num,CPLX_num,GS_num;reg req_reg;
    always@(posedge(clk))
    begin
    if(!rstn)
        begin
        cs<=Idle;
        prenum<=0;
        typenow<=NL;
        addrnow<=0;
        stridenow<=0;
        IPsignow<=0;
        req_reg<=0;
        end
    else
        begin
        cs<=ns;
        prenum<=nprenum;
        typenow<=ntypenow;
        addrnow<=naddrnow;
        stridenow<=nstridenow;
        IPsignow<=nIPsignow;
        req_reg<=req;
        end
    end
    always@(*)
    begin
    ns=Idle;
    ntypenow=typenow;
    naddrnow=addrnow;
    nstridenow=stridenow;
    nIPsignow=IPsignow;
    ntailp=tailp;nprenum=prenum;
    req=0;reqtype=typenow;CSPT_lookaddr=IPsignow;
    reqaddr={addrnow,5'b0};
    case(cs)
        Idle:
            if(|buff_dout[43:42]&&headp!=tailp)
                begin
                ns=Req;
                {ntypenow,nIPsignow,nstridenow}=buff_dout[43:27];
                naddrnow=buff_dout[26:0]+{{19{buff_dout[34]}},buff_dout[33:27]};
                ntailp=tailp+1;
                case(buff_dout[43:42])
                    CS:
                        nprenum=CS_num;
                    CPLX:
                        nprenum=CPLX_num;
                    GS:
                        nprenum=GS_num;    
                    default:
                        nprenum=0; 
                endcase
                end
              else
                ns=Idle;
        Req:
            begin
            req=1;
            ns=Req;
            if(reqcomp)
                begin
                req=0;//?
                if(prenum>1)
                    ns=Getnaddr;
                else
                    ns=Idle;
                end
            end
        Getnaddr:
            begin
            nprenum=prenum-1;
            ns=Req;
            if(typenow==CPLX)
                begin
                //nstridenow=CSPT_datain[9:2];
                naddrnow=addrnow+{{19{CSPT_datain[9]}},CSPT_datain[8:2]};
                nIPsignow={IPsignow[5:0],1'b0}^CSPT_datain[9:2];
                if(~CSPT_datain[1])
                    begin
                    if(|prenum)
                        ns=Getnaddr;
                    else
                        ns=Idle;
                    end
                end
            else
                begin
                naddrnow=addrnow+{{19{stridenow[7]}},stridenow[6:0]};
                end
            end
    endcase
    end
    //total_counter
    always@(posedge(clk))
    begin
    if(!rstn)
        begin
        tcoun_CS<=0;
        tcoun_CPLX<=0;
        tcoun_GS<=0;
        end
    else if(&tcoun_CS)
        tcoun_CS<=0;
    else if(&tcoun_CPLX)
        tcoun_CPLX<=0;
    else if(&tcoun_GS)
        tcoun_GS<=0;
    else if(req&~req_reg)
        begin
        case(reqtype)
            CS:
               tcoun_CS<=tcoun_CS+1;
            CPLX:
               tcoun_CPLX<=tcoun_CPLX+1;
            GS:
                tcoun_GS<=tcoun_GS+1;
        endcase
        end
    end
    
    //hit_counter
    always@(posedge(clk))
    begin
    if(!rstn)
        begin
        hcoun_CS<=0;
        hcoun_CPLX<=0;
        hcoun_GS<=0;
        CS_num<=CS_max;
        CPLX_num<=CPLX_max;
        GS_num<=GS_max;
        end
    else
        begin
        if(&tcoun_CS)
            begin
            hcoun_CS<=0;
            if(hcoun_CS<102&&CS_num>1)
                CS_num<=CS_num-1;
            else if(hcoun_CS>192&&CS_num<CS_max)
                CS_num<=CS_num+1;
            end
        else if(&tcoun_CPLX)
            begin
            hcoun_CPLX<=0;
            if(hcoun_CPLX<102&&CPLX_num>1)
                CPLX_num<=CPLX_num-1;
            else if(hcoun_CPLX>192&&CPLX_num<CPLX_max)
                CPLX_num<=CPLX_num+1;
            end
        else if(&tcoun_GS)
            begin
            hcoun_GS<=0;
            if(hcoun_GS<102&&GS_num>1)
                GS_num<=GS_num-1;
            else if(hcoun_GS>192&&GS_num<GS_max)
                GS_num<=GS_num+1;
            end
        else if(visithit)
            begin
            case(hitype)
                CS:
                    hcoun_CS<=hcoun_CS+{7'b0,~(&hcoun_CS)};
                CPLX:
                    hcoun_CPLX<=hcoun_CPLX+{7'b0,~(&hcoun_CPLX)};
                GS:
                    hcoun_GS<=hcoun_GS+{7'b0,~(&hcoun_GS)};
                default
                    begin
                    end
            endcase
            end
        end
    end
    
    
    //head
    always@(posedge(clk))
    begin
    if(!rstn)
        begin
        headp<=0;
        end
    else if(|typein&&buffer[headp-1]!=buff_din)
        begin
        headp<=headp+1;
        end
    end
    //tail
    always@(posedge(clk))
    begin
    if(!rstn)
        begin
        tailp<=0;
        
        end
    else 
        begin
        tailp<=ntailp;
        end
    end
    //buffer
    always@(posedge(clk))
    begin
    if(|typein&&buffer[headp-1]!=buff_din)
        buffer[headp]<=buff_din;
    end
    
    
    
endmodule