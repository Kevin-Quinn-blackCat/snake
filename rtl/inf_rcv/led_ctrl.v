module led_ctrl 
#(
    parameter CNT_50MS_MAX = 22'd2500_00
)
(
    input  wire sys_clk,
    input  wire sys_rst_n,
    input  wire repeat_en,
    
    output reg  led
);

/*===上升沿检测===*/
reg     repeat_en_dly1;
reg     repeat_en_dly2;
wire    repeat_en_p;

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        repeat_en_dly1 <= 1'b0;
        repeat_en_dly2 <= 1'b0;
    end
    else begin
        repeat_en_dly1 <= repeat_en;
        repeat_en_dly2 <= repeat_en_dly1;
    end
end

assign repeat_en_p = (!repeat_en_dly2) & repeat_en_dly1;

/*===50ms倒计时计数器===*/
reg [21:0]  cnt_50ms;
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        cnt_50ms <= 22'd0;
    end
    else if(repeat_en_p) begin
        cnt_50ms <= CNT_50MS_MAX;
    end
    else if(!cnt_50ms) begin
        cnt_50ms <= 22'd0;
    end
    else
        cnt_50ms <= cnt_50ms - 22'd1;
end

/*===led输出===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        led <= 1'b1;
    end
    else if(cnt_50ms) begin
        led <= 1'b0;
    end
    else
        led <= 1'b1;
end


endmodule //led_ctrl
