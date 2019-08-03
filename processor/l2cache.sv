module l2cache (
	input	logic			clk,    // Clock
	output	logic			hit,
	output	logic			miss,

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

	logic dirty, evict, read, commit;
	assign hit = (mem_read | mem_write) & ~miss;

	cache_control cache_ctrl0(.*);
	l2cache_datapath cache_dp0(.*);

endmodule
