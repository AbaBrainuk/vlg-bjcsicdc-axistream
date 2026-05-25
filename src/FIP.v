module FIP(
	input clk,
	input rst_n,
	input [63:0] hdm_data,
	input last_data,
	input hdm_valid,
	output fip_ready,
	output reg acc_valid,
	output reg [63:0] acc_result
);
	localparam sReady = 0,sDone = 1;

	reg [1:0] s,ns;
	reg [63:0] local_result;
	always @(*)begin//状态转移
		case(s)
			sReady:ns = (last_data & hdm_valid)?sDone : sReady;
			sDone:ns = sReady;
		endcase
	end
	
	
	
	always @(posedge clk)begin//状态流与数据流
		if(~rst_n)begin
			local_result <= 64'd0;
			s <= sReady;
		end else begin 
			s <= ns;
			if(hdm_valid) begin
				local_result <= local_result + hdm_data;
			end
			if(s == sDone)begin
				local_result <= 64'd0;
			end
		end
	end
	
	always @(posedge clk)begin//输出流
		if(~rst_n)begin
			acc_result <= 64'd0;
			acc_valid <= 1'b0;
		end else begin 
			if(s == sDone) begin
				acc_result <= local_result;
				acc_valid <= 1'b1;
			end
		end
	end

	assign fip_ready = s == sReady;
endmodule