module L2cache_pref_reqbuf (
    input clk,rstn,
    input [31:0]addr_l1,data_l1,
    input [1:0]from,
    input [3:0]wstrb_l1,
    output reg [31:0]addr_l1_pref,data_l1_pref,
    output reg [1:0]from_pref,
    output reg [3:0]wstrb_pref
);
always @(posedge clk) begin
    if(!rstn)begin
        addr_l1_pref <= 0;
        data_l1_pref <= 0;
        from_pref <= 0;
        wstrb_pref <= 0;
    end
    else begin
        addr_l1_pref <= addr_l1;
        data_l1_pref <= data_l1;
        from_pref <= from;
        wstrb_pref <= wstrb_l1;
    end
end
endmodule