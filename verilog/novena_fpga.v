//////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2013, Andrew "bunnie" Huang
//
// See the NOTICE file distributed with this work for additional 
// information regarding copyright ownership.  The copyright holder 
// licenses this file to you under the Apache License, Version 2.0 
// (the "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// code distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.
//////////////////////////////////////////////////////////////////////////////

/// note: must set "-g UnusedPin:Pullnone" to avoid conflicts with unused pins

`timescale 1ns / 1ps

module novena_fpga(
	// CPU side mapping
	input wire [15:0] EIM_DA,
	output reg EIM_A16,  // relay of the trigger output
	output reg EIM_A17,  // relay of the trigger data (read path)

	// connector side mapping
	//input wire F_LVDS_N3, // output of trigger
	input wire F_DX2,       // output of trigger
	//output wire F_LVDS_N5, // trigger reset
	output wire F_LVDS_P4,   // trigger reset
	//inout wire F_LVDS_P5, // trigger data (bidir)
	input wire F_DX18,      // trigger data in from sticker (DUT->CPU)
	output wire F_LVDS_P11, // trigger data out to sticker (CPU->DUT)
	//output wire F_LVDS_N8, // trigger clock
	output wire F_DX14,      // trigger clock

	output wire F_LVDS_N7, // drive TPI data line
	output wire F_LVDS_P7, // drive TPI signal lines

	output wire F_DX15,  // 1 = drive 5V, 0 = drive 3V to DUT

	output wire F_LVDS_CK1_N,
	output wire F_LVDS_CK1_P,
	output wire F_LVDS_N11,

	output wire F_LVDS_N0,
	output wire F_LVDS_P0,
	output wire F_DX1,

	output wire F_LVDS_N15,
	output wire F_LVDS_P15,
	output wire F_LVDS_NC,

	input wire F_DX11,
	input wire F_DX3,
	input wire F_DX0,

	input wire F_LVDS_CK0_P,
	input wire F_LVDS_CK0_N,
	input wire F_LVDS_P9,

	input wire [1:0] EIM_CS,
	input wire EIM_LBA,

	input wire CLK2_N,
	input wire CLK2_P,
	output wire FPGA_LED2,

	input wire I2C3_SCL,
	inout wire I2C3_SDA,

	input wire RESETBMCU,
	output wire F_DX17,  // dummy
	output wire APOPTOSIS
);
	wire clk;

	IBUFGDS clkibufgds(
		.I(CLK2_P),
		.IB(CLK2_N),
		.O(clk)
	);

	assign FPGA_LED2 = 1'b1;

	assign APOPTOSIS = 1'b0;
	assign F_DX15 = 1'b1; //+5V P_DUT
   
	// OE on bank to drive signals; signal not inverted in software
	assign F_LVDS_P7 = !EIM_DA[3];
	// OE on bank to drive the data; signal not inverted in software
	assign F_LVDS_N7 = !EIM_DA[4];
	assign F_LVDS_P4 = 1'b0;
	assign F_LVDS_P11 = 1'b0;
	assign F_LVDS_CK1_N = 1'b0;
	assign F_LVDS_CK1_P = 1'b0;
	assign F_LVDS_N11 = 1'b0;
	assign F_LVDS_N0 = 1'b0;
	assign F_LVDS_P0 = 1'b0;
	assign F_DX1 = 1'b0;
	assign F_LVDS_N15 = 1'b0;
	assign F_LVDS_P15 = 1'b0;
	assign F_LVDS_NC = 1'b0;

	// reduction and of EIM_DA, dummy-map to keep compiler quiet
	assign F_DX17 = &EIM_DA | RESETBMCU;
   
	////////////////////////////////////
	///// I2C register set
	////////////////////////////////////
	wire [7:0] reg_0_test;
	wire       SDA_pd;
	wire       SDA_int;
	reg        clk25;
   
	initial begin
		clk25 <= 1'b0;
	end
	always @ (posedge clk) begin
		clk25 <= ~clk25;
		EIM_A16 <= 1'b0;
		EIM_A17 <= 1'b0;
	end
   
	IOBUF #(
		.DRIVE(8),
		.SLEW("SLOW")
	) IOBUF_sda (
		.IO(I2C3_SDA),
		.I(1'b0),
		.T(!SDA_pd),
		.O(SDA_int)
	);

	i2c_slave i2c_slave(
		.SCL(I2C3_SCL),
		.SDA(SDA_int),
		.SDA_pd(SDA_pd),
		.clk(clk25), // nominally 26 MHz, this is close enough
		.glbl_reset(1'b0),
		.i2c_device_addr(8'h1E),

		//.reg_46_trig(eim_mon_adv),

		// outputs from I2C block (CPU->FPGA) 0-3F
		.reg_0(reg_0_test),

		//.reg_2(eim_mon_ctl[7:0]),
		// bit 0:  enable trigger condition
		// bit 1:  reset log

		// ADC control block
		//.reg_4(adc_wdata[7:0]),  
		//.reg_5(adc_addr[7:0]),
		//.reg_6({adc_commit,adc_rd_wr_n,adc_addr[12:8]}),

		// inputs to I2C block (FPGA->CPU) 40-7F
		.reg_40(reg_0_test),
		//.reg_41(eim_mon_stat[7:0]),
		// bit 0: empty
		// bit 1: full

		// ADC readback register from serial interface
		//.reg_42(adc_rdata),
		//.reg_43({7'b0,adc_sbus_busy}),

		// EIM monitor data going back to CPU
		// it auto-incs thanks to reg_46_trig
		//.reg_44(mon_data[7:0]),  
		//.reg_45(mon_data[15:8]),
		//.reg_46({mon_data[23:16]}),

		// ID / version code
		// minor / major
		.reg_fc(8'h00), .reg_fd(8'h03), .reg_fe(8'h00), .reg_ff(8'h04)
	);
    
	ws2812b_driver #(120) driver1 (.clk(clk),
		.enable(1'b1),
		.data_in({reg_0_test,136'h0000FF00000000FF00FF00FFFF00FFFFFF}),
		.wave_out(F_DX14)
		//.fin()
	);
endmodule
