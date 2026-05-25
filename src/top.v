module top(
	input clk,
	input rst_n,
	//AXI_BUS
	input [63:0] axi_data,
	input [7:0] keep,
	input axi_valid,
	output dc_ready,
	input axi_last,
	//final result
	output [63:0]acc_result,
	output acc_valid,
	//other module output
	output [31:0] tile_id,
	output [31:0] task_id,
	output clac_start,
	output mismatch
);

	wire flash;
	wire rst_n_f = ~flash & rst_n;
	
	//i1>i2
	wire last_ele;
	wire [63:0] tile_data;
	wire tile_valid;
	wire hdm_ready;
	
	//i2>i3
	wire [63:0]  hdm_data;
	wire hdm_valid;
	wire fip_ready;
	wire last_data;
	
	
	Decoder i1 (
		.axi_data(axi_data),
		.axi_last(axi_last),
		.axi_valid(axi_valid),
		.clac_start(clac_start),
		.clk(clk),
		.dc_ready(dc_ready),
		.flash(flash),
		.hdm_ready(hdm_ready),
		.keep(keep),
		.last_ele(last_ele),
		.mismatch(mismatch),
		.rst_n(rst_n),
		.task_id(task_id),
		.tile_data(tile_data),
		.tile_id(tile_id),
		.tile_valid(tile_valid)
	);
	
	
	HDM i2 (
		.clac_start(clac_start),
		.clk(clk),
		.fip_ready(fip_ready),
		.hdm_data(hdm_data),
		.hdm_ready(hdm_ready),
		.hdm_valid(hdm_valid),
		.last_data(last_data),
		.last_ele(last_ele),
		.rst_n(rst_n_f),
		.tile_data(tile_data),
		.tile_id(tile_id),
		.tile_valid(tile_valid)
	);

	FIP i3 ( 
		.acc_result(acc_result),
		.acc_valid(acc_valid),
		.clk(clk),
		.fip_ready(fip_ready),
		.hdm_data(hdm_data),
		.hdm_valid(hdm_valid),
		.last_data(last_data),
		.rst_n(rst_n_f)
	);


endmodule