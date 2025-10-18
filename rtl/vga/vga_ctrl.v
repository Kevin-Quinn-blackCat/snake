module vga_ctrl
#(
    parameter H_SYNC = 10'd96,
    parameter H_BACK = 10'd41,
    parameter H_LEFT = 10'd9,
    parameter H_VALID = 10'd639,
    parameter H_RIGHT = 10'd8,
    parameter H_FRONT = 10'd7,
    parameter H_TOTAL = 10'd800,

    parameter V_SYNC = 10'd2,
    parameter V_BACK = 10'd26,
    parameter V_TOP = 10'd8,
    parameter V_VALID = 10'd479,
    parameter V_BOTTOM = 10'd8,
    parameter V_FRONT = 10'd2,
    parameter V_TOTAL = 10'd525
)
(
    input    wire        sys_clk,
    input    wire        sys_rst_n,
    input    wire    [15:0]   pix_rgb_data,

    output wire     [9:0]     pix_x,
    output wire     [9:0]     pix_y,
    output wire               hsync,
    output wire               vsync,
    output wire     [15:0]    rgb 
);

/*===internal_port===*/
reg [9:0] cnt_h;
reg [9:0] cnt_v;
wire       rgb_valid;   

/*===行计数器===*/
// 记录这是某行的第几个工作周期
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        cnt_h <= 10'd0;
    end
    else if(cnt_h == H_TOTAL - 10'd1) begin
        cnt_h <= 10'd0;
    end
    else
        cnt_h <= cnt_h + 10'd1;
end

/*===场计数器===*/
// 记录已经工作到第几行了
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        cnt_v <= 10'd0;
    end
    else if((cnt_v == V_TOTAL - 10'd1)
            && (cnt_h == H_TOTAL - 10'd1)) begin
        cnt_v <= 10'd0;
    end
    else if(cnt_h == H_TOTAL - 10'd1) begin
        cnt_v <= cnt_v + 10'd1;
    end
    else
        cnt_v <= cnt_v;
end

/*===图像显示有效信号===*/
// 在本周期，传入的数据会显示在屏幕对应的像素点上
assign rgb_valid = ((cnt_h >= H_SYNC + H_BACK + H_LEFT)
                    && (cnt_h < H_SYNC + H_BACK + H_LEFT + H_VALID)
                    && (cnt_v >= V_SYNC + V_BACK + V_TOP)
                    && (cnt_v < V_SYNC + V_BACK + V_TOP + V_VALID))
                    ? 1'b1 : 1'b0;

/*===数据请求信号===*/
// 提前将有效信号拉高，告诉外部的数据产生模块下一个像素坐标是那里
wire    pix_data_req;
assign pix_data_req = ((cnt_h >= H_SYNC + H_BACK + H_LEFT - 10'd2)
                    && (cnt_h < H_SYNC + H_BACK + H_LEFT + H_VALID - 10'd2)
                    && (cnt_v >= V_SYNC + V_BACK + V_TOP)
                    && (cnt_v < V_SYNC + V_BACK + V_TOP + V_VALID))
                    ? 1'b1 : 1'b0;

/*===像素坐标信号===*/
// 受控于数据请求模块，将下一个像素的坐标发出，告诉外部的数据产生模块下一个像素坐标是那里
// 应该是目前行计数器(控制像素)数字的下一位
assign pix_x = (pix_data_req == 1'b1)
                ? (cnt_h - (H_SYNC + H_BACK + H_LEFT) + 10'd2)
                : 10'h3ff;

assign pix_y = (pix_data_req == 1'b1)
                ? (cnt_v - (V_SYNC + V_BACK + V_TOP))
                : 10'h3ff;

/*===行场同步信号===*/
assign hsync = (cnt_h <= H_SYNC - 10'd1)
                ? 1'b1 : 1'b0;

assign vsync = (cnt_v <= V_SYNC - 10'd1)
                ? 1'b1 : 1'b0;

/*===像素颜色数据===*/
// 目前像素的显示数据，这取决于上周期发出的像素坐标
assign rgb = (rgb_valid == 1'b1) ? pix_rgb_data : 16'h0000;

endmodule //vga_ctrl
