project = novena-ws2312b
vendor = xilinx
family = spartan6
part = xc6slx45csg324-3
top_module = novena_fpga
isedir = /opt/Xilinx/14.3/ISE_DS
xil_env = . $(isedir)/settings64.sh

vfiles = ../verilog/novena_fpga.v ../verilog/i2c_slave.v \
	 ../verilog/sync_reset.v ../verilog/ws2812b_driver.v

include xilinx.mk
