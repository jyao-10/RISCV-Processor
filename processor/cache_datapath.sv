module cache_datapath (
	input	logic			clk,    // Clock

	output	logic			miss,
	output	logic			dirty,

	input	logic			evict,
	input	logic			read,
	input	logic			commit,

	input	logic	[31:0]	mem_address,
	output	logic	[31:0]	mem_rdata,
	input	logic	[31:0]	mem_wdata,
	input	logic			mem_read,
	input	logic			mem_write,
	input	logic	[3:0]	mem_byte_enable,
	output	logic			mem_resp,

	// Physical memory signals
	output	logic	[31:0]	pmem_address,
	input	logic	[255:0]	pmem_rdata,
	output	logic	[255:0]	pmem_wdata
);
	// split memory address
	logic [23:0] tag;
	assign tag = mem_address[31:8];
	logic [2:0] index;
	assign index = mem_address[7:5];
	logic [4:0] block_offset;
	assign block_offset = mem_address[4:0];
	logic [2:0] word_offset;
	assign word_offset = mem_address[4:2];
	logic [1:0] byte_offset;
	assign byte_offset = mem_address[1:0];

	// internal wires
	logic way;
	logic tag_write_enable, tag_write_enable0, tag_write_enable1;
	logic [23:0] tag_in, tag_out0, tag_out1, tag_out;
	logic data_write_enable, data_write_enable0, data_write_enable1;
	logic [255:0] data_in, data_out0, data_out1, data_out;
	logic valid_write_enable, valid_write_enable0, valid_write_enable1;
	logic valid_in, valid_out0, valid_out1, valid_out;
	logic dirty_write_enable, dirty_write_enable0, dirty_write_enable1;
	logic dirty_in, dirty_out0, dirty_out1, dirty_out;
	logic lru_write_enable;
	logic lru_in, lru_out;

	// cache hit signals
	logic hit, hit0, hit1;
	assign hit0 = (tag_out0 == tag) & valid_out0;
	assign hit1 = (tag_out1 == tag) & valid_out1;
	assign hit = hit0 | hit1;

	// control unit signals
	assign miss = (mem_read | mem_write) & ~hit;
	assign dirty = lru_out ? (dirty_out1 & valid_out1) : (dirty_out0 & valid_out0); // if miss, way isn't valid -- hence this "hack"

	// other signals
	assign way = (evict | read) ? lru_out : hit1;

	assign mem_resp = hit & (mem_read | mem_write);
	logic [255:0] temp_out;
	assign temp_out = (data_out >> (8 * $unsigned(block_offset))) & 32'hFFFFFFFF;
	assign mem_rdata = temp_out[31:0];

	assign pmem_address = evict ? {tag_out, index, 5'b00000} : {tag, index, 5'b00000};
	assign pmem_wdata = data_out;

	assign tag_in = tag;
	assign valid_in = 1'b1;
	assign dirty_in = ~read; // read ? 1'b0 : 1'b1;
	assign lru_in = ~way;

	assign data_write_enable = read ? commit : (hit & mem_write & valid_out);
	assign dirty_write_enable = read ? commit : (hit & mem_write & valid_out);
	assign tag_write_enable = commit;
	assign valid_write_enable = commit;
	assign lru_write_enable = read ? commit : (hit & (mem_write | mem_read) & valid_out);

	// masking/shifting for the data_in
	/*
	logic [31:0] byte_mask;
	logic [255:0] line_data;
	logic [255:0] line_mask;
	assign byte_mask = {{8{mem_byte_enable[3]}}, {8{mem_byte_enable[2]}}, {8{mem_byte_enable[1]}}, {8{mem_byte_enable[0]}}};
	assign line_data = (mem_wdata & byte_mask) << (8 * $unsigned(word_offset));
	assign line_mask = (~byte_mask) << (8 * $unsigned(word_offset));
	assign data_in = (read) ? pmem_rdata : ((data_out & ~line_mask) | (line_data & line_mask));
	*/
	logic [31:0] byte_mask;
	logic [255:0] byte_mask_full, input_full;
	assign byte_mask = {{8{mem_byte_enable[3]}}, {8{mem_byte_enable[2]}}, {8{mem_byte_enable[1]}}, {8{mem_byte_enable[0]}}};
	assign byte_mask_full = byte_mask << (8 * $unsigned(block_offset));
	assign input_full = mem_wdata << (8 * $unsigned(block_offset));	
	assign data_in = read ? pmem_rdata : ((data_out & ~byte_mask_full) | (input_full & byte_mask_full));

	// tag
	assign tag_write_enable0 = tag_write_enable & ~way;
	assign tag_write_enable1 = tag_write_enable & way;
	array #(.width(24)) tag_store_arr0(.clk, .write(tag_write_enable0), .index, .datain(tag_in), .dataout(tag_out0));
	array #(.width(24)) tag_store_arr1(.clk, .write(tag_write_enable1), .index, .datain(tag_in), .dataout(tag_out1));
	mux2 #(.width(24)) tag_out_mux(.sel(way), .a(tag_out0), .b(tag_out1), .f(tag_out));

	// data
	assign data_write_enable0 = data_write_enable & ~way;
	assign data_write_enable1 = data_write_enable & way;
	array #(.width(256)) data_store_arr0(.clk, .write(data_write_enable0), .index, .datain(data_in), .dataout(data_out0));
	array #(.width(256)) data_store_arr1(.clk, .write(data_write_enable1), .index, .datain(data_in), .dataout(data_out1));
	mux2 #(.width(256)) data_out_mux(.sel(way), .a(data_out0), .b(data_out1), .f(data_out));

	// valid
	assign valid_write_enable0 = valid_write_enable & ~way;
	assign valid_write_enable1 = valid_write_enable & way;
	array #(.width(1)) valid_store_arr0(.clk, .write(valid_write_enable0), .index, .datain(valid_in), .dataout(valid_out0));
	array #(.width(1)) valid_store_arr1(.clk, .write(valid_write_enable1), .index, .datain(valid_in), .dataout(valid_out1));
	mux2 #(.width(1)) valid_out_mux(.sel(way), .a(valid_out0), .b(valid_out1), .f(valid_out));

	// dirty
	assign dirty_write_enable0 = dirty_write_enable & ~way;
	assign dirty_write_enable1 = dirty_write_enable & way;
	array #(.width(1)) dirty_store_arr0(.clk, .write(dirty_write_enable0), .index, .datain(dirty_in), .dataout(dirty_out0));
	array #(.width(1)) dirty_store_arr1(.clk, .write(dirty_write_enable1), .index, .datain(dirty_in), .dataout(dirty_out1));
	mux2 #(.width(1)) dirty_out_mux(.sel(way), .a(dirty_out0), .b(dirty_out1), .f(dirty_out));

	// lru
	array #(.width(1)) lru_store_arr(.clk, .write(lru_write_enable), .index, .datain(lru_in), .dataout(lru_out));

endmodule
