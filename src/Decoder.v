module Decoder (
	input clk,
	input rst_n,
	//AXI_BUS
	input [63:0] axi_data,
	input [7:0] keep,//虽然没啥用，但是万一他最后一个包用一堆无用字节和有用字节，然后把无用字节掩了呢？
	input axi_valid,
	output dc_ready,
	input axi_last,
	//HDM
	output reg [63:0] tile_data,
	output reg [31:0] tile_id,
	output reg tile_valid,
	input hdm_ready, //其实除非分开测试，否则都是ready的，但还是写上相应逻辑
	output reg clac_start,
	output reg last_ele,
	//other signals
	output reg [31:0] task_id,
	output mismatch,
	output reg flash
);

	//题目要求两个包taskid不同或者tileid不为1，0或者0，1就冲刷
	localparam sHead_1 = 0,sBody_1 = 1,sHead_2 =2,sBody_2 = 3,snHead = 4;
	//第一个8字节数据必定为头部。
	
	reg [3:0] s,ns; //状态机
	
	reg [3:0] ptr;
	reg [63:0] mem [15:0]; //一样，尽管不会有用，但是还是保留这个，让这里边存边发
	
	wire doRec = axi_valid & hdm_ready;//确认接受
	assign dc_ready = doRec;
	
	reg domatch;//匹配
	assign mismatch = ~domatch;
	
	reg [31:0] pTile,pTask;//上一个寸的tileid和taskid
	wire isFirst = s == snHead | s == sHead_1;//是否是第一帧
	
	wire isTile = s == sBody_1 | s == sBody_2;//当前数据包为tile包
	wire [63:0] exkeep;
	
	wire [63:0] keeped_data = axi_data & exkeep;
	
	always @(*)begin
		case(s)
			sHead_1:ns = doRec?sBody_1:sHead_1;
			sBody_1:ns = (axi_last & doRec)?sHead_2:sBody_1;
			sHead_2:ns = doRec?sBody_2:sHead_2;
			sBody_2:ns = (axi_last & doRec)?snHead:sBody_2;
			snHead:ns = doRec?sBody_1:snHead;
		endcase
	end
	
	
	genvar i;
	generate
		for (i =0;i< 8;i= i+1)begin : ex
			assign exkeep [8*i +:8] = {8{keep[i]}};
		end
	endgenerate
	
	always @(*)begin
		tile_valid = isTile & doRec & domatch;//这里如果不匹配不给valid
		tile_data = axi_data & exkeep;//即使不匹配，数据照样发，但是不给valid
		last_ele = axi_last;
		
		clac_start = domatch & doRec & s == snHead;
		flash = ~domatch & doRec & s == snHead;
	end
	
	always @(posedge clk)begin
		if (~rst_n)begin
			s <= 4'd0;
			ptr <= 4'd0;
		end else begin
			s <= ns;
			if(isTile & doRec)begin//无论有没有用，先存着再说
				ptr <= ptr + 4'd1;
				mem[ptr] <= axi_data & exkeep;
			end
		end
	end
	
	always @(posedge clk)begin //匹配与否
		if (~rst_n)begin
			pTile <= 1'b0;
			pTask <= 1'b0;
			tile_id <= 32'd0;
			task_id <= 32'd0;
			domatch <= 1'b1;
		end else begin
			if(~isTile & doRec)begin //帧的第一个包
				if(isFirst)begin
					pTile <= keeped_data[31:0];
					pTask <= keeped_data[63:32];
					domatch <= 1'b1;
				end else begin
					if (pTask != (keeped_data[63:32]))begin//taskid不匹配
						domatch <= 1'b0;
					end else if(~((pTile == 32'd1 & (keeped_data[31:0]) == 32'd0)|(pTile == 32'd0 & (keeped_data[31:0]) == 32'd1))) begin//tileid不匹配
						domatch <= 1'b0;
					end 
				end 
				
				tile_id <= keeped_data[31:0];
				task_id <= keeped_data[63:32];
				
			end
			
		end
	end
	
endmodule