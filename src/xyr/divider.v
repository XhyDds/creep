module divider#(//din1/din2
    parameter WIDTH=32
)(
    input clk,rstn,
    input [3:0] pipeline_divider_type,
    input [4:0] pipeline_divider_subtype,
    input pipeline_divider_stall,
    input pipeline_divider_flush,
    input [WIDTH-1:0] pipeline_divider_din1,
    input [WIDTH-1:0] pipeline_divider_din2,
    output divider_pipeline_stall,
    output [WIDTH-1:0] divider_pipeline_dout
    
);
    localparam Tdiv=2;
    localparam Wait=0,Aline=1,Div=2,Waitout=3;
    localparam DIVW=0,MODW=1,DIVWU=2,MODWU=3;
    wire exe,flush;reg busy;wire [WIDTH-1:0] din1,din2;
    reg [WIDTH-1:0] dout;wire [4:0] mode;reg [4:0]mode_reg,nmode;
    reg [2:0] ns,cs;reg [WIDTH:0]temp;
    reg [WIDTH-1:0] remainder,nremainder,quotient,nquotient,din2_reg,ndin2_reg;
    reg din1s,din2s;
    reg [5:0] counter,ncounter;wire [4:0] n1,n2;wire stall;
    assign stall=pipeline_divider_stall;
    assign exe=(pipeline_divider_type==Tdiv)&&(!stall);
    assign divider_pipeline_stall=busy,din1=pipeline_divider_din1;
    assign din2=pipeline_divider_din2,divider_pipeline_dout=dout;
    assign flush=pipeline_divider_flush,mode=pipeline_divider_subtype;
    aliner alin1(.din(remainder),.n(n1));
    aliner alin2(.din(din2_reg),.n(n2));
    always@(posedge(clk),negedge(rstn))
    begin
    if(!rstn||flush)
        begin
        cs<=Wait;
        mode_reg<=DIVW;
        remainder<=0;quotient<=0;
        din1s<=0;din2s<=0;
        din2_reg<=0;
        counter<=0;
        end
    else
        begin
        cs<=ns;
        remainder<=nremainder;
        quotient<=nquotient;
        counter<=ncounter;
        mode_reg<=nmode;
        din2_reg<=ndin2_reg;
        if(cs==Wait)
            begin
            
            din1s<=din1[WIDTH-1];din2s<=din2[WIDTH-1];
            
            end
        end
    end
    always@(*)
    begin
    nremainder=remainder;
    nquotient=quotient;
    ncounter=counter;
    nmode=mode_reg;
    ndin2_reg=din2_reg;
    temp=remainder-({1'b0, din2_reg}<<counter);
    ns=Wait;
    busy=1;dout=0;
    if(mode==DIVW||mode==DIVWU)
        dout=quotient;
    else
        dout=remainder;
    case(cs)
        Wait:
            if(exe)
                begin
                if(|din2)
                    ns=Aline;
                else
                    ns=Wait; 
                nquotient=0;nremainder=0;
                nmode=mode;
                if((mode==DIVW||mode==MODW)&&din1[WIDTH-1])
                    nremainder=0-din1;
                else
                    nremainder=din1;
                if((mode==DIVW||mode==MODW)&&din2[WIDTH-1])
                    ndin2_reg=0-din2;
                else
                    ndin2_reg=din2;
                end
            else
                begin
                ns=Wait;
                busy=0;
                end
        Aline:
            begin
            ncounter={1'b0,n1}-{1'b0,n2};
            if(ncounter[5])
                begin
                ns=Wait;
                nremainder=0;
                nquotient=0;
                end
            else
                ns=Div;
            end
        Div:
            begin
            if(counter[5])
                begin
                ns=Waitout;
                if(din1s&&(mode_reg==DIVW||mode_reg==MODW))
                    nremainder=0-remainder;
                if(din1s^din2s&&(mode_reg==DIVW||mode_reg==MODW))
                    nquotient=0-quotient;
                end
            else
                begin
                ns=Div;
                ncounter=counter-1;
                nquotient[WIDTH-1:1]=quotient[WIDTH-2:0];
                //ndin2_reg={1'b0,din2_reg[2*WIDTH-1:1]};
                if(temp[WIDTH]==0)
                    begin
                    nquotient[0]=1;
                    nremainder=temp[WIDTH-1:0];
                    end
                else
                    begin
                    nquotient[0]=0;
                    nremainder=remainder;
                    end
                end
            end
        Waitout:
            begin
            if(stall)
                ns=Waitout;
            else
                ns=Wait;
            busy=0;
            end
        
        
    endcase
    end
    
 
 
 
    
endmodule





module aliner(
    input [31:0] din,
    output reg [4:0] n

);
    reg [15:0]d16;reg [7:0] d8;reg [3:0] d4; reg [1:0] d2; reg d1;
    always@(*)
    begin
    if(|din[31:16])
        begin
        n[4]=1;
        d16=din[31:16];
        end
    else
        begin
        n[4]=0;
        d16=din[15:0];
        end
    if(|d16[15:8])
        begin
        n[3]=1;
        d8=d16[15:8];
        end
    else
        begin
        n[3]=0;
        d8=d16[7:0];
        end
    if(|d8[7:4])
        begin
        n[2]=1;
        d4=d8[7:4];
        end
    else
        begin
        n[2]=0;
        d4=d8[3:0];
        end
    if(|d4[3:2])
        begin
        n[1]=1;
        d2=d4[3:2];
        end
    else
        begin
        n[1]=0;
        d2=d4[1:0];
        end
    if(|d2[1])
        begin
        n[0]=1;
        end
    else
        begin
        n[0]=0;
        end
    end

endmodule









