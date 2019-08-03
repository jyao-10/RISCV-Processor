module eviction_write_buffer(
	input	logic			clk,    // Clock

	// CPU signals
	input	logic	[31:0]	mem_address,
	output	logic	[255:0]	mem_rdata,
	input	logic	[255:0]	mem_wdata,
	input	logic			mem_read,
	input	logic			mem_write,
	output	logic			mem_resp,

	// Physical memory signals
	output	logic	[31:0]	pmem_address,
	input	logic	[255:0]	pmem_rdata,
	output	logic	[255:0]	pmem_wdata,
	output	logic			pmem_read,
	output	logic			pmem_write,
	input	logic			pmem_resp
);

/**
 * The eviction write buffer has two main functionalities.
 * 1) If the buffer is not filled, handle as so:
 * -> WRITE: load data directly into the buffer
 * -> OTHER: pass signals from physical memory directly
 * 2) If the buffer is filled, handle as so:
 * -> READ: pass signals through unless the mem_address == buffer_address
 * -> WRITE: flush buffer before loading data into the buffer unless mem_address == buffer_address
 * -> OTHER: flush buffer
 */

logic hit;
logic evict, full, write_to_buffer;
eviction_write_buffer_control ctrl0(.write(mem_write), .read(mem_read), .*);

logic [31:0] addr_buffer_out;
logic [255:0] data_buffer_out;
assign hit = addr_buffer_out == mem_address;

assign mem_rdata = full & hit ? data_buffer_out : pmem_rdata;
assign pmem_address = evict ? addr_buffer_out : mem_address;
assign pmem_wdata = evict ? data_buffer_out : mem_wdata;

register #(.width(32)) addr_buffer(.clk, .load(write_to_buffer), .in(mem_address), .out(addr_buffer_out));
register #(.width(256)) data_buffer(.clk, .load(write_to_buffer), .in(mem_wdata), .out(data_buffer_out));

endmodule // eviction_write_buffer
