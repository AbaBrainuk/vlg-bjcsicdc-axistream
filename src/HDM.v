module HDM (
	input clk,
	input rst_n,
	//给下游的数据传输
	input fip_ready,
	output reg [63:0] hdm_data,
	output last_data,
	output hdm_valid,
	//来自上游的数据
	input [63:0] tile_data,
	input [31:0] tile_id,
	input tile_valid,
	output hdm_ready,
	input clac_start,//发送完不同的tileblock后发送，用来清空sta和stb，并非作为字面功能使用
	input last_ele
);

	//其实根本用不上存储矩阵A和B，以及判断tileID，因为上游发现taskid和tileb不对会冲刷。
	//但是保留了，所以这个模块即使接受了三个tile，分别id 0,0,1的话，也能正常计算，算是冗余吧，我有强迫症。

	reg [63:0] memA[15:0];
	reg [63:0] memB[15:0];
	
	reg [3:0] ptr;
	
	reg sta,stb;//a或者b被储存过了，clac后清空

	wire doRun = (fip_ready | ~(sta & stb)) & tile_valid;//上游有数据，下游也可以收，本模块不会堆积数据，那就干吧。倘若上游就绪，下游不就绪，但是不传输有效数据给下游，那也能接着让上游法，干就完了。
	assign hdm_ready = fip_ready | ~(sta & stb);
	
	wire calc_imm = ((sta & tile_id == 32'd1)|(stb & tile_id == 32'd0))& doRun; //这个是没有延迟的计算标志
	
	always @(posedge clk)begin
		if (~rst_n)begin
			ptr <= 4'd0;
		end else begin
			if(doRun)begin
				//存储数据
				if(tile_id == 32'd0)begin
					memA [ptr] <= tile_data;
					ptr <= ptr + 4'd1;
				end
				if (tile_id == 32'd1)begin
					memB [ptr] <= tile_data;
					ptr <= ptr + 4'd1;
				end
			end
		
		end
	end
	
	always @(*)begin
		if(doRun)begin
				if (tile_id == 32'd0)
					hdm_data = memB [ptr] * tile_data;
				if (tile_id == 32'd1)
					hdm_data = memA [ptr] * tile_data;	
		end
	end
	
	assign hdm_valid = calc_imm;
	assign last_data = last_ele & calc_imm;
	
	always @(posedge clk)begin //记录是否准备好两个矩阵,clac_start 后直接清空
		if (~rst_n | clac_start)begin
			sta <= 1'b0;
			stb <= 1'b0;
		end else begin
			if (tile_id == 32'd0 & tile_valid == 1'b1)
				sta <= 1'b1;
			if (tile_id == 32'd1 & tile_valid == 1'b1)
				stb <= 1'b1;
		end
	end
	
endmodule