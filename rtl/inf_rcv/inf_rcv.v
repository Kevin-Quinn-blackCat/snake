module inf_rcv (
    input  wire sys_clk,
    input  wire sys_rst_n,
    input  wire inf_in,

    output wire ds,
    output wire oe,
    output wire shcp,
    output wire stcp,
    output wire led,
    output wire [19:0]  data
);

/*===internal_signal===*/
wire          repeat_en;

/*===decoder_inst===*/
inf_rcv_decoder  inf_rcv_decoder_inst (
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .inf_in(inf_in),
    .data(data),
    .repeat_en(repeat_en)
);

/*===led_inst===*/
led_ctrl # (
    .CNT_50MS_MAX()
)
led_ctrl_inst (
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .repeat_en(repeat_en),
    .led(led)
);

/*===hc595_inst===*/
seg_595_dynamic  seg_595_dynamic_inst (
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .data(data),
    .point(6'b000_000),
    .seg_en(1'b1),
    .sign(1'b0),
    .stcp(stcp),
    .shcp(shcp),
    .ds(ds),
    .oe(oe)
);

endmodule //inf_rcv