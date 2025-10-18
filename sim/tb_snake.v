`timescale 1ns / 1ns 

module tb_snake;
//Ports
reg  sys_clk;
reg  sys_rst_n;
reg  inf_in;
wire  ds;
wire  oe;
wire  shcp;
wire  stcp;
wire  led;
wire    [15:0] rgb;
wire  hsync;
wire  vsync;

initial begin
    sys_clk = 1'b1;
    sys_rst_n <= 1'b0;
    inf_in <= 1'b0;
    #40
    sys_rst_n <= 1'b1;
end

always #10 sys_clk = ~sys_clk;

snake  snake_inst (
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .inf_in(inf_in),
    .ds(ds),
    .oe(oe),
    .shcp(shcp),
    .stcp(stcp),
    .led(led),
    .rgb(rgb),
    .hsync(hsync),
    .vsync(vsync)
);

endmodule