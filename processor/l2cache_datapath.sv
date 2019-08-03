module l2cache_datapath (
	input	logic			clk,    // Clock

	output	logic			miss,
	output	logic			dirty,

	input	logic			evict,
	input	logic			read,
	input	logic			commit,

	input	logic	[31:0]	mem_address,
	output	logic	[255:0]	mem_rdata,
	input	logic	[255:0]	mem_wdata,
	input	logic			mem_read,
	input	logic			mem_write,
	output	logic			mem_resp,

	// Physical memory signals
	output	logic	[31:0]	pmem_address,
	input	logic	[255:0]	pmem_rdata,
	output	logic	[255:0]	pmem_wdata
);
	// split memory address
	logic [21:0] tag;
	assign tag = mem_address[31:10];
	logic [4:0] index;
	assign index = mem_address[9:5];

	// internal wires
	logic [1:0] way;
	logic tag_write_enable, tag_write_enable0, tag_write_enable1, tag_write_enable2, tag_write_enable3;
	logic [21:0] tag_in, tag_out0, tag_out1, tag_out2, tag_out3, tag_out;
	logic data_write_enable, data_write_enable0, data_write_enable1, data_write_enable2, data_write_enable3;
	logic [255:0] data_in, data_out0, data_out1, data_out2, data_out3, data_out;
	logic valid_write_enable, valid_write_enable0, valid_write_enable1, valid_write_enable2, valid_write_enable3;
	logic valid_in, valid_out0, valid_out1, valid_out2, valid_out3, valid_out;
	logic dirty_write_enable, dirty_write_enable0, dirty_write_enable1, dirty_write_enable2, dirty_write_enable3;
	logic dirty_in, dirty_out0, dirty_out1, dirty_out2, dirty_out3, dirty_out;
	logic lru_write_enable;
	logic [2:0] lru_in, lru_out;

	// cache hit signals
	logic hit, hit0, hit1, hit2, hit3;
	assign hit0 = (tag_out0 == tag) & valid_out0;
	assign hit1 = (tag_out1 == tag) & valid_out1;
	assign hit2 = (tag_out2 == tag) & valid_out2;
	assign hit3 = (tag_out3 == tag) & valid_out3;
	assign hit = hit0 | hit1 | hit2 | hit3;

	// control unit signals
	assign miss = (mem_read | mem_write) & ~hit;
	lru_mux4 #(.width(1)) dirty_mux(
		.sel(lru_out),
		.a(dirty_out0 & valid_out0),
		.b(dirty_out1 & valid_out1),
		.c(dirty_out2 & valid_out2),
		.d(dirty_out3 & valid_out3),
		.f(dirty)
	);

	// other signals
	logic [1:0] hit_way, lru_out_way;
	assign way = hit ? hit_way : lru_out_way;
	onehot_mux4 #(.width(2)) hit_mux(
		.selA(hit0),
		.selB(hit1),
		.selC(hit2),
		.selD(hit3),
		.a(2'b00),
		.b(2'b01),
		.c(2'b10),
		.d(2'b11),
		.f(hit_way)
	);
	lru_mux4 #(.width(2)) way_mux(
		.sel(lru_out),
		.a(2'b00),
		.b(2'b01),
		.c(2'b10),
		.d(2'b11),
		.f(lru_out_way)
	);

	assign mem_resp = hit & (mem_read | mem_write);
	assign mem_rdata = data_out;

	assign pmem_address = evict ? {tag_out, index, 5'b00000} : {tag, index, 5'b00000};
	assign pmem_wdata = data_out;

	assign tag_in = tag;
	assign valid_in = 1'b1;
	assign dirty_in = ~read; // read ? 1'b0 : 1'b1;
	assign lru_in = lru_out[2] ? {~lru_out[2], ~lru_out[1], lru_out[0]} : {~lru_out[2], lru_out[1], ~lru_out[0]};

	assign data_write_enable = read ? commit : (hit & mem_write & valid_out);
	assign dirty_write_enable = read ? commit : (hit & mem_write & valid_out);
	assign tag_write_enable = commit;
	assign valid_write_enable = commit;
	assign lru_write_enable = read ? commit : (hit & (mem_write | mem_read) & valid_out);

	// masking/shifting for the data_in
	assign data_in = read ? pmem_rdata : mem_wdata;

	// tag
	assign tag_write_enable0 = tag_write_enable & (way == 2'b00);
	assign tag_write_enable1 = tag_write_enable & (way == 2'b01);
	assign tag_write_enable2 = tag_write_enable & (way == 2'b10);
	assign tag_write_enable3 = tag_write_enable & (way == 2'b11);
	l2array #(.width(22)) tag_store_arr0(.clk, .write(tag_write_enable0), .index, .datain(tag_in), .dataout(tag_out0));
	l2array #(.width(22)) tag_store_arr1(.clk, .write(tag_write_enable1), .index, .datain(tag_in), .dataout(tag_out1));
	l2array #(.width(22)) tag_store_arr2(.clk, .write(tag_write_enable2), .index, .datain(tag_in), .dataout(tag_out2));
	l2array #(.width(22)) tag_store_arr3(.clk, .write(tag_write_enable3), .index, .datain(tag_in), .dataout(tag_out3));
	mux4 #(.width(22)) tag_out_mux(.sel(way), .a(tag_out0), .b(tag_out1), .c(tag_out2), .d(tag_out3), .f(tag_out));

	// data
	assign data_write_enable0 = data_write_enable & (way == 2'b00);
	assign data_write_enable1 = data_write_enable & (way == 2'b01);
	assign data_write_enable2 = data_write_enable & (way == 2'b10);
	assign data_write_enable3 = data_write_enable & (way == 2'b11);
	l2array #(.width(256)) data_store_arr0(.clk, .write(data_write_enable0), .index, .datain(data_in), .dataout(data_out0));
	l2array #(.width(256)) data_store_arr1(.clk, .write(data_write_enable1), .index, .datain(data_in), .dataout(data_out1));
	l2array #(.width(256)) data_store_arr2(.clk, .write(data_write_enable2), .index, .datain(data_in), .dataout(data_out2));
	l2array #(.width(256)) data_store_arr3(.clk, .write(data_write_enable3), .index, .datain(data_in), .dataout(data_out3));
	mux4 #(.width(256)) data_out_mux(.sel(way), .a(data_out0), .b(data_out1), .c(data_out2), .d(data_out3), .f(data_out));

	// valid
	assign valid_write_enable0 = valid_write_enable & (way == 2'b00);
	assign valid_write_enable1 = valid_write_enable & (way == 2'b01);
	assign valid_write_enable2 = valid_write_enable & (way == 2'b10);
	assign valid_write_enable3 = valid_write_enable & (way == 2'b11);
	l2array #(.width(1)) valid_store_arr0(.clk, .write(valid_write_enable0), .index, .datain(valid_in), .dataout(valid_out0));
	l2array #(.width(1)) valid_store_arr1(.clk, .write(valid_write_enable1), .index, .datain(valid_in), .dataout(valid_out1));
	l2array #(.width(1)) valid_store_arr2(.clk, .write(valid_write_enable2), .index, .datain(valid_in), .dataout(valid_out2));
	l2array #(.width(1)) valid_store_arr3(.clk, .write(valid_write_enable3), .index, .datain(valid_in), .dataout(valid_out3));
	mux4 #(.width(1)) valid_out_mux(.sel(way), .a(valid_out0), .b(valid_out1), .c(valid_out2), .d(valid_out3), .f(valid_out));

	// dirty
	assign dirty_write_enable0 = dirty_write_enable & (way == 2'b00);
	assign dirty_write_enable1 = dirty_write_enable & (way == 2'b01);
	assign dirty_write_enable2 = dirty_write_enable & (way == 2'b10);
	assign dirty_write_enable3 = dirty_write_enable & (way == 2'b11);
	l2array #(.width(1)) dirty_store_arr0(.clk, .write(dirty_write_enable0), .index, .datain(dirty_in), .dataout(dirty_out0));
	l2array #(.width(1)) dirty_store_arr1(.clk, .write(dirty_write_enable1), .index, .datain(dirty_in), .dataout(dirty_out1));
	l2array #(.width(1)) dirty_store_arr2(.clk, .write(dirty_write_enable2), .index, .datain(dirty_in), .dataout(dirty_out2));
	l2array #(.width(1)) dirty_store_arr3(.clk, .write(dirty_write_enable3), .index, .datain(dirty_in), .dataout(dirty_out3));
	mux4 #(.width(1)) dirty_out_mux(.sel(way), .a(dirty_out0), .b(dirty_out1),.c(dirty_out2), .d(dirty_out3),  .f(dirty_out));

	// lru
	l2array #(.width(3)) lru_store_arr(.clk, .write(lru_write_enable), .index, .datain(lru_in), .dataout(lru_out));

endmodule

module lru_mux4 #(parameter width = 32) (
	input [2:0] sel,
	input [width-1:0] a, b, c, d,
	output logic [width-1:0] f
);

logic [width-1:0] out;
assign f = out;

always_comb
begin
	case (sel)
		3'b000: out = a;
		3'b001: out = a;
		3'b010: out = b;
		3'b011: out = b;
		3'b100: out = c;
		3'b101: out = d;
		3'b110: out = c;
		3'b111: out = d;
	endcase
end

endmodule : lru_mux4



module onehot_mux4 #(parameter width = 32) (
	input selA, selB, selC, selD,
	input [width-1:0] a, b, c, d,
	output logic [width-1:0] f
);

logic [width-1:0] out;
assign f = out;

always_comb
begin
	case ({selA, selB, selC, selD})
		4'b1000: out = a;
		4'b0100: out = b;
		4'b0010: out = c;
		4'b0001: out = d;
		default: out = {width{1'b0}};
	endcase
end

endmodule : onehot_mux4
