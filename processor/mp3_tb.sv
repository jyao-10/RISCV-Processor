
module mp3_tb;

timeunit 1ns;
timeprecision 1ns;

logic clk;

logic read, write;
logic [31:0] address;
logic [255:0] wdata;
logic resp;
logic [255:0] rdata;

logic read_a, write_a, read_b, write_b;
logic [31:0] address_a, address_b;
logic [255:0] wdata_b;
logic resp_a, resp_b;
logic [255:0] rdata_a, rdata_b;

logic halt;
logic [31:0] registers [32];
logic [31:0] pc;

logic IF_ID_stall, IF_ID_clear;
logic IF_ID2_stall;
logic ID_EX_stall;
logic EX_MEM_stall, EX_MEM_clear;
logic MEM_WB_clear;

/*

to test: run ./bin/rv_load_memory.sh ./testcode/mp3-cp3.s ./processor/simulation/modelsim/memory.lst 32

add wave -position end -radix hexadecimal -label registers sim:/mp3_tb/registers
add wave -position end -radix hexadecimal -label stall_EX  sim:/mp3_tb/dut/cpu0/dfu0/stall_EX
add wave -position end -radix hexadecimal -label rs1_outmux_sel sim:/mp3_tb/dut/cpu0/dfu0/rs1_outmux_sel
add wave -position end -radix hexadecimal -label rs2_outmux_sel  sim:/mp3_tb/dut/cpu0/dfu0/rs2_outmux_sel
add wave -position end -radix hexadecimal -label wdatabmux_sel  sim:/mp3_tb/dut/cpu0/dfu0/wdatabmux_sel

add wave -position end -radix hexadecimal -label br_en  sim:/mp3_tb/dut/cpu0/EX_br_en

add wave -position end -radix hexadecimal -label mem_rdy  sim:/mp3_tb/dut/cpu0/mem_ready
add wave -position end -radix hexadecimal -label mem_a_rdy sim:/mp3_tb/dut/cpu0/mem_a_ready
add wave -position end -radix hexadecimal -label mem_b_rdy  sim:/mp3_tb/dut/cpu0/mem_b_ready
add wave -position end -radix hexadecimal -label ctrl sim:/mp3_tb/dut/cpu0/ctrl_rom/ctrl
add wave -position end -radix hexadecimal -label regs sim:/mp3_tb/registers

add wave -position end -radix hexadecimal -label perf_counters sim:/mp3_tb/dut/cpu0/perfcounter0/dataout_sig

restart -f; run 1000ns

*/

/* Clock generator */
initial clk = 0;
always #5 clk = ~clk;

assign registers = dut.cpu0.regfile.data;
assign halt = ((dut.cpu0.ID_ir == 32'h00000063) | (dut.cpu0.ID_ir == 32'h0000006F));

assign pc = dut.cpu0.pcmux_out;

assign read_a = dut.cpu0.read_a;
assign write_a = dut.cpu0.write_a;
assign read_b = dut.cpu0.read_b;
assign write_b = dut.cpu0.write_b;
assign address_a = dut.cpu0.address_a;
assign address_b = dut.cpu0.address_b;
assign wdata_b = dut.cpu0.wdata_b;
assign resp_a = dut.cpu0.resp_a;
assign resp_b = dut.cpu0.resp_b;
assign rdata_a = dut.cpu0.rdata_a;
assign rdata_b = dut.cpu0.rdata_b;

assign IF_ID_stall = dut.cpu0.IF_ID.stall;
assign IF_ID_clear = dut.cpu0.IF_ID.clear;
assign IF_ID2_stall = dut.cpu0.IF_ID2.stall;
assign ID_EX_stall = dut.cpu0.ID_EX.stall;
assign EX_MEM_stall = dut.cpu0.EX_MEM.stall;
assign EX_MEM_clear = dut.cpu0.EX_MEM.clear;
assign MEM_WB_clear = dut.cpu0.MEM_WB.clear;

mp3 dut(
	.*
);

physical_memory memory (
    .*
);


endmodule : mp3_tb

