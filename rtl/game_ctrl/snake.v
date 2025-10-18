/*==================================================================================*/
// Author        : Kevin_Quinn
// Create Date   : 2025/10/10
// Module Name   : snake
// Project Name  : snake
// Target Devices: Altera EP4CE10F17C8N
// Tool Versions : Quartus 13.0
// Description   : 基于vga显示的贪吃蛇游戏
//
// Revision      : V0.1.0
// Additional Comments:
// V0.1.0: 测试版本，实现基本游戏逻辑
// V1.0.0: 预计更新在数码管显示分数
// V2.0.0：预计更新新的操控模式
/*==================================================================================*/

module snake (
    input    wire             sys_clk,
    input    wire             sys_rst_n,
    input    wire             inf_in,

    output   wire             ds,
    output   wire             oe,
    output   wire             shcp,
    output   wire             stcp,
    output   wire             led,
    output   wire    [15:0]   rgb,
    output   wire             hsync,
    output   wire             vsync
);
/*===port===*/
wire            clk_pll_out;
wire            locked;
wire    [15:0]  pix_rgb_data;
wire    [9:0]   pix_x;
wire    [9:0]   pix_y;
wire            rst_n;
wire    [19:0]  data;

/*===rst_n===*/
assign rst_n = sys_rst_n && locked;

/*===pll_inst===*/
pll_25mhz	pll_25mhz_inst (
	.areset (~sys_rst_n),
	.inclk0 (sys_clk),
	.c0     (clk_pll_out),
	.locked (locked)
	);

/*===vga_ctrl_inst===*/
vga_ctrl # (
    .H_SYNC(),
    .H_BACK(),
    .H_LEFT(),
    .H_VALID(),
    .H_RIGHT(),
    .H_FRONT(),
    .H_TOTAL(),
    .V_SYNC(),
    .V_BACK(),
    .V_TOP(),
    .V_VALID(),
    .V_BOTTOM(),
    .V_FRONT(),
    .V_TOTAL()
)
vga_ctrl_inst (
    .sys_clk(clk_pll_out),
    .sys_rst_n(rst_n),
    .pix_rgb_data(pix_rgb_data),
    .pix_x(pix_x),
    .pix_y(pix_y),
    .hsync(hsync),
    .vsync(vsync),
    .rgb(rgb)
);

/*===inf_rcv===*/
inf_rcv  inf_rcv_inst (
    .sys_clk(sys_clk),
    .sys_rst_n(rst_n),
    .inf_in(inf_in),
    .ds(ds),
    .oe(oe),
    .shcp(shcp),
    .stcp(stcp),
    .led(led),
    .data(data)
);

/*===pic_data_gen_inst===*/
pic_rgb_gen # (
    .CNT_25MHZ_0_25S()
)
pic_rgb_gen_inst (
    .sys_clk(clk_pll_out),
    .sys_rst_n(rst_n),
    .pix_x(pix_x),
    .pix_y(pix_y),
    .data(data),
    .pix_rgb_data(pix_rgb_data)
);


endmodule //vga_colorbar 
