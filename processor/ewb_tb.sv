
module ewb_tb;

timeunit 1ns;
timeprecision 1ns;

logic clk;

logic	[31:0]	mem_address;
logic	[255:0]	mem_rdata;
logic	[255:0]	mem_wdata;
logic			mem_read;
logic			mem_write;
logic			mem_resp;

// Physical memory signals
logic	[31:0]	pmem_address;
logic	[255:0]	pmem_rdata;
logic	[255:0]	pmem_wdata;
logic			pmem_read;
logic			pmem_write;
logic			pmem_resp;

/* Clock generator */
initial clk = 0;
always #5 clk = ~clk;

eviction_write_buffer ewb0(
	.*
);

/*

add wave -position end -radix hexadecimal sim:/ewb_tb/ewb0/evict
add wave -position end -radix hexadecimal sim:/ewb_tb/ewb0/full
add wave -position end -radix hexadecimal sim:/ewb_tb/ewb0/hit
add wave -position end -radix hexadecimal sim:/ewb_tb/ewb0/addr_buffer_out
add wave -position end -radix hexadecimal sim:/ewb_tb/ewb0/data_buffer_out
add wave -position end  sim:/ewb_tb/ewb0/ctrl0/next_state
add wave -position end  sim:/ewb_tb/ewb0/ctrl0/state

restart -f
run 750ns

*/

initial begin : TEST_VECTORS
	// defaults
	mem_address = 32'h0000_0000;
	mem_wdata = 256'd0;
	mem_read = 1'b0;
	mem_write = 1'b0;
	pmem_rdata = 256'd0;
	pmem_resp = 1'b0;
	
	// test empty read
	mem_address = 32'h0000_1234;
	pmem_rdata = 256'h00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000;
	#100 mem_read = 1'b1;
	#10 pmem_resp = 1'b1;
	#10 pmem_resp = 1'b0;
	mem_read = 1'b0;

	// test empty write
	mem_address = 32'h0000_5678;
	mem_wdata = 256'h11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111;
	#100 mem_write = 1'b1;
	// shouldnt need to set pmem_resp since it goes into the WB
	// #10 pmem_resp = 1'b1;
	// #10 pmem_resp = 1'b0;
	#10 mem_write = 1'b0;
	
	// test fill read (hit) -- we do this immediately so it doesn't try to evict
	mem_address = 32'h0000_5678;
	#0 mem_read = 1'b1;
	#10 mem_read = 1'b0;
	
	// test fill read (miss) -- we do this immediately so it doesn't try to evict
	mem_address = 32'h0000_1234;
	pmem_rdata = 256'h00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000;
	#0 mem_read = 1'b1;
	#10 pmem_resp = 1'b1;
	#10 pmem_resp = 1'b0;
	mem_read = 1'b0;
	
	// test write (hit) -- we do this immediately so it doesn't try to evict
	mem_address = 32'h0000_5678;
	mem_wdata = 256'h22222222_22222222_22222222_22222222_22222222_22222222_22222222_22222222;
	#0 mem_write = 1'b1;
	// shouldnt need to set pmem_resp since it goes into the WB
	// #10 pmem_resp = 1'b1;
	// #10 pmem_resp = 1'b0;
	#10 mem_write = 1'b0;
	
	// test write (miss) -- we do this immediately so it doesn't try to evict
	mem_address = 32'h0000_1234;
	mem_wdata = 256'h33333333_33333333_33333333_33333333_33333333_33333333_33333333_33333333;
	#0 mem_write = 1'b1;
	#10 pmem_resp = 1'b1;
	#10 pmem_resp = 1'b0;
	#10 mem_write = 1'b0;
	
	// evicted 2222222...
	// buffer should have 333.....
	// then it should evict 333...
end

endmodule : ewb_tb

