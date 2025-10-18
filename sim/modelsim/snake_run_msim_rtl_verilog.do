transcript on
if ![file isdirectory verilog_libs] {
	file mkdir verilog_libs
}

vlib verilog_libs/altera_ver
vmap altera_ver ./verilog_libs/altera_ver
vlog -vlog01compat -work altera_ver {d:/altera/13.0sp1/quartus/eda/sim_lib/altera_primitives.v}

vlib verilog_libs/lpm_ver
vmap lpm_ver ./verilog_libs/lpm_ver
vlog -vlog01compat -work lpm_ver {d:/altera/13.0sp1/quartus/eda/sim_lib/220model.v}

vlib verilog_libs/sgate_ver
vmap sgate_ver ./verilog_libs/sgate_ver
vlog -vlog01compat -work sgate_ver {d:/altera/13.0sp1/quartus/eda/sim_lib/sgate.v}

vlib verilog_libs/altera_mf_ver
vmap altera_mf_ver ./verilog_libs/altera_mf_ver
vlog -vlog01compat -work altera_mf_ver {d:/altera/13.0sp1/quartus/eda/sim_lib/altera_mf.v}

vlib verilog_libs/altera_lnsim_ver
vmap altera_lnsim_ver ./verilog_libs/altera_lnsim_ver
vlog -sv -work altera_lnsim_ver {d:/altera/13.0sp1/quartus/eda/sim_lib/altera_lnsim.sv}

vlib verilog_libs/cycloneive_ver
vmap cycloneive_ver ./verilog_libs/cycloneive_ver
vlog -vlog01compat -work cycloneive_ver {d:/altera/13.0sp1/quartus/eda/sim_lib/cycloneive_atoms.v}

if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+D:/fpga_code/personal_code/snake/rtl/game_ctrl {D:/fpga_code/personal_code/snake/rtl/game_ctrl/snake.v}
vlog -vlog01compat -work work +incdir+D:/fpga_code/personal_code/snake/rtl/game_ctrl {D:/fpga_code/personal_code/snake/rtl/game_ctrl/direct_sig_ctrl.v}
vlog -vlog01compat -work work +incdir+D:/fpga_code/personal_code/snake/quartus_prj/ip_core/ram_256x2 {D:/fpga_code/personal_code/snake/quartus_prj/ip_core/ram_256x2/ram_256x2.v}
vlog -vlog01compat -work work +incdir+D:/fpga_code/personal_code/snake/quartus_prj/ip_core/PLL25MHz {D:/fpga_code/personal_code/snake/quartus_prj/ip_core/PLL25MHz/pll_25mhz.v}
vlog -vlog01compat -work work +incdir+D:/fpga_code/personal_code/snake/quartus_prj/ip_core/fifo_256x8 {D:/fpga_code/personal_code/snake/quartus_prj/ip_core/fifo_256x8/fifo_256x8.v}
vlog -vlog01compat -work work +incdir+D:/fpga_code/personal_code/snake/rtl/inf_rcv {D:/fpga_code/personal_code/snake/rtl/inf_rcv/led_ctrl.v}
vlog -vlog01compat -work work +incdir+D:/fpga_code/personal_code/snake/rtl/inf_rcv {D:/fpga_code/personal_code/snake/rtl/inf_rcv/inf_rcv_decoder.v}
vlog -vlog01compat -work work +incdir+D:/fpga_code/personal_code/snake/rtl/inf_rcv {D:/fpga_code/personal_code/snake/rtl/inf_rcv/inf_rcv.v}
vlog -vlog01compat -work work +incdir+D:/fpga_code/personal_code/snake/rtl/lfsr {D:/fpga_code/personal_code/snake/rtl/lfsr/prbs32_to_8.v}
vlog -vlog01compat -work work +incdir+D:/fpga_code/personal_code/snake/rtl/lfsr {D:/fpga_code/personal_code/snake/rtl/lfsr/prbs8bit.v}
vlog -vlog01compat -work work +incdir+D:/fpga_code/personal_code/snake/rtl/seg_595_dynamic {D:/fpga_code/personal_code/snake/rtl/seg_595_dynamic/seg_dynamic.v}
vlog -vlog01compat -work work +incdir+D:/fpga_code/personal_code/snake/rtl/seg_595_dynamic {D:/fpga_code/personal_code/snake/rtl/seg_595_dynamic/seg_595_dynamic.v}
vlog -vlog01compat -work work +incdir+D:/fpga_code/personal_code/snake/rtl/seg_595_dynamic {D:/fpga_code/personal_code/snake/rtl/seg_595_dynamic/hc595_ctrl.v}
vlog -vlog01compat -work work +incdir+D:/fpga_code/personal_code/snake/rtl/seg_595_dynamic {D:/fpga_code/personal_code/snake/rtl/seg_595_dynamic/bcd_8421.v}
vlog -vlog01compat -work work +incdir+D:/fpga_code/personal_code/snake/rtl/vga {D:/fpga_code/personal_code/snake/rtl/vga/vga_ctrl.v}
vlog -vlog01compat -work work +incdir+D:/fpga_code/personal_code/snake/rtl/vga {D:/fpga_code/personal_code/snake/rtl/vga/pic_rgb_gen.v}
vlog -vlog01compat -work work +incdir+D:/fpga_code/personal_code/snake/quartus_prj/db {D:/fpga_code/personal_code/snake/quartus_prj/db/pll_25mhz_altpll.v}

vlog -vlog01compat -work work +incdir+D:/fpga_code/personal_code/snake/quartus_prj/../sim {D:/fpga_code/personal_code/snake/quartus_prj/../sim/tb_snake.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L rtl_work -L work -voptargs="+acc"  tb_snake

add wave *
view structure
view signals
run 1 us
