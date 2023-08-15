module pred_cache#(
    parameter   addr_width=8,
                tag_width=22,
                h_width=4,
                way=4
)
(
    input       clk,
    input       update_en_reg,

    input       [addr_width-1:0]raddr,
    output reg  [1:0]taken_pdch,
    input       [h_width-1:0] h,
    input       [tag_width-1:0]tag,//用于比较

    input       [addr_width-1:0]waddr,
    input       taken_real,
    input       [h_width-1:0] h_upt,
    input       [tag_width-1:0] tag_upt
);
//declare
    wire [way-1:0]valid_rs;
    wire [way-1:0]hit_rs;
    wire [way-1:0]hits;
    wire [2*way-1:0]taken_pdchs;

    localparam data_width = tag_width+(1<<h_width)*2+1;

    wire [way-1:0] hit_ws;//input
    wire [way-1:0]valid_ws;//input
    wire [way-1:0]hits_w;//input
    reg  [data_width-1:0] din;//output
    wire [data_width*way-1:0] douts;//input
    reg  [way-1:0]we_s;//output

    wire [1:0] way_select;
//store
generate
    genvar i;
    for(i=0;i<way;i=i+1)begin:hitgenerate
    pred_ram #(
        .TAG_WIDTH(tag_width),
        .ADDR_WIDTH(addr_width),
        .H_WIDTH(h_width)
    )
    eachway(
        .clk(clk),

        .raddr(raddr),
        .taken_pdch(taken_pdchs[2*i+1:2*i]),
        .h(h),
        .tag(tag),
        .hit(hit_rs[i]),
        .valid(valid_rs[i]),

        .waddr(waddr),
        .din_w_reg(din),
        .dout_w(douts[data_width*(i+1)-1:data_width*i]),
        .tag_upt(tag_upt),
        .hit_w(hit_ws[i]),
        .valid_w(valid_ws[i]),
        .update_en_reg(we_s[i])
    );
    end
    assign hits[i]=(hit_rs[i])&&(valid_rs[i]);
    assign hits_w[i]=(hit_ws[i])&&(valid_ws[i]);
endgenerate
//pdc
    always @(*) begin
        if(hits[0])      taken_pdch=taken_pdchs[1:0];
        else if(hits[1]) taken_pdch=taken_pdchs[3:2];
        else if(hits[2]) taken_pdch=taken_pdchs[5:4];
        else if(hits[3]) taken_pdch=taken_pdchs[7:6];
        else             taken_pdch=2'b00;
    end
//upt
    reg [tag_width-1:0] tag_upt_reg;
    reg [h_width-1:0] h_upt_reg;
    reg taken_real_reg;

    wire [data_width-1:0] dout0=douts[data_width*1-1:data_width*0];
    wire [data_width-1:0] dout1=douts[data_width*2-1:data_width*1];
    wire [data_width-1:0] dout2=douts[data_width*3-1:data_width*2];
    wire [data_width-1:0] dout3=douts[data_width*4-1:data_width*3];

    reg  [1:0] taken_pdch_upt_old;
    wire [1:0] taken_pdch_upt_new;
    reg  [data_width-1:0] din_old;

    always @(posedge clk) begin
        tag_upt_reg<=tag_upt;
        h_upt_reg<=h_upt;
        taken_real_reg<=taken_real;
    end
    //old
    always @(*) begin
        if(hits_w[0])      taken_pdch_upt_old={dout0[2*h_upt_reg+1],dout0[2*h_upt_reg]};
        else if(hits_w[1]) taken_pdch_upt_old={dout1[2*h_upt_reg+1],dout1[2*h_upt_reg]};
        else if(hits_w[2]) taken_pdch_upt_old={dout2[2*h_upt_reg+1],dout2[2*h_upt_reg]};
        else if(hits_w[3]) taken_pdch_upt_old={dout3[2*h_upt_reg+1],dout3[2*h_upt_reg]};
        else               taken_pdch_upt_old=2'b00;

        if(hits_w[0])      din_old=dout0;
        else if(hits_w[1]) din_old=dout1;
        else if(hits_w[2]) din_old=dout2;
        else if(hits_w[3]) din_old=dout3;
        else               din_old={tag_upt_reg,1'b1,{(1<<h_width){2'b0}}};
    end
    transformer_2bit core(
        .crt(taken_pdch_upt_old),
        .nxt(taken_pdch_upt_new),
        .taken(taken_real_reg)
    );

    always @(*) begin
        //din
        case (h_upt_reg)
            4'd0: din={din_old[data_width-1:2],
                        taken_pdch_upt_new};
            4'd1: din={din_old[data_width-1:4],
                        taken_pdch_upt_new,
                        din_old[1:0]};
            4'd2: din={din_old[data_width-1:6],
                        taken_pdch_upt_new,
                        din_old[3:0]};
            4'd3: din={din_old[data_width-1:8],
                        taken_pdch_upt_new,
                        din_old[5:0]};
            4'd4: din={din_old[data_width-1:10],
                        taken_pdch_upt_new,
                        din_old[7:0]};
            4'd5: din={din_old[data_width-1:12],
                        taken_pdch_upt_new,
                        din_old[9:0]};
            4'd6: din={din_old[data_width-1:14],
                        taken_pdch_upt_new,
                        din_old[11:0]};
            4'd7: din={din_old[data_width-1:16],
                        taken_pdch_upt_new,
                        din_old[13:0]};
            4'd8: din={din_old[data_width-1:18],
                        taken_pdch_upt_new,
                        din_old[15:0]};
            4'd9: din={din_old[data_width-1:20],
                        taken_pdch_upt_new,
                        din_old[17:0]};
            4'd10: din={din_old[data_width-1:22],   
                        taken_pdch_upt_new,
                        din_old[19:0]};
            4'd11: din={din_old[data_width-1:24],
                        taken_pdch_upt_new,
                        din_old[21:0]};
            4'd12: din={din_old[data_width-1:26],
                        taken_pdch_upt_new,
                        din_old[23:0]};
            4'd13: din={din_old[data_width-1:28],
                        taken_pdch_upt_new,
                        din_old[25:0]};
            4'd14: din={din_old[data_width-1:30],   
                        taken_pdch_upt_new,
                        din_old[27:0]};
            4'd15: din={din_old[data_width-1:32],
                        taken_pdch_upt_new,
                        din_old[29:0]};

        endcase

        //we_s
        we_s=0;
        if(~update_en_reg) ;
        else if(valid_ws[0])   we_s=4'b0001;
        else if(valid_ws[1])   we_s=4'b0010;
        else if(valid_ws[2])   we_s=4'b0100;
        else if(valid_ws[3])   we_s=4'b1000;
        else begin
            if(hit_ws[0])      we_s=4'b0001;
            else if(hit_ws[1]) we_s=4'b0010;
            else if(hit_ws[2]) we_s=4'b0100;
            else if(hit_ws[3]) we_s=4'b1000;
            else begin
                //replace
                case (way_select)
                    2'b00:     we_s=4'b0001;
                    2'b01:     we_s=4'b0010;
                    2'b10:     we_s=4'b0100;
                    2'b11:     we_s=4'b1000; 
                endcase
            end
        end
    end

//replace
    pred_replace#(
        .addr_width(addr_width),
        .way(way)
    )u_replace(
        .clk(clk),
        .use1(we_s),
        .update_en(update_en_reg),

        .addr(waddr),
        .way_sel(way_select)//reg
    );
endmodule
