module perf_counter #(parameter width = 32)
(
    input   logic               clk,
    input   logic               write,
    input   logic [31:0]        address,

    input   logic [width-1:0]   datain,

    input   logic               inc_instr_cache_hit, // l1 instr
    input   logic               inc_instr_cache_miss,
    input   logic               inc_data_cache_hit, // l1 data
    input   logic               inc_data_cache_miss,
    input   logic               inc_l2_cache_hit, // l2
    input   logic               inc_l2_cache_miss,
    input   logic               inc_branch_prediction_hit, // branch prediction
    input   logic               inc_branches,
    input   logic               inc_pipeline_stalls, // pipeline stalls

    output  logic               hit,
    output  logic [width-1:0]   dataout
);

    /**
     * The perf_counter module holds a hardware performance counter that is memory mapped.
     * If write is high, then the value in datain is written to the register at address.
     * Otherwise, if an input signal inc_* is high, the counter for that signal is incremented.
     *
     * address | value
     * ------- | --------------------
     * 0x0000    L1 (instr) Cache Hit
     * 0x0001    L1 (instr) Cache Miss
     * 0x0002    L1 (data) Cache Hit
     * 0x0003    L1 (data) Cache Miss
     * 0x0004    L2 Cache Hit
     * 0x0005    L2 Cache Miss
     * 0x0006    Branch Prediction Miss
     * 0x0007    Branch Prediction Branch Total
     * 0x0008    Number of Pipeline Stalls
     */

    logic [8:0] hit_sig;
    logic [8:0] in_sig;
    logic [width-1:0] dataout_sig [8:0];

    assign hit = ~(hit_sig == 8'd0);

    assign in_sig[0] = inc_instr_cache_hit; // perf_counter_switch sw00(.clk, .in(inc_instr_cache_hit), .out(in_sig[0]));
    perf_counter_switch sw01(.clk, .in(inc_instr_cache_miss), .out(in_sig[1]));
    assign in_sig[2] = inc_data_cache_hit; // perf_counter_switch sw02(.clk, .in(inc_data_cache_hit), .out(in_sig[2]));
    perf_counter_switch sw03(.clk, .in(inc_data_cache_miss), .out(in_sig[3]));
    assign in_sig[4] = inc_l2_cache_hit; // perf_counter_switch sw04(.clk, .in(inc_l2_cache_hit), .out(in_sig[4]));
    perf_counter_switch sw05(.clk, .in(inc_l2_cache_miss), .out(in_sig[5]));
    assign in_sig[6] = inc_branch_prediction_hit; // perf_counter_switch sw06(.clk, .in(inc_branch_prediction_hit), .out(in_sig[6]));
    assign in_sig[7] = inc_branches; // perf_counter_switch sw07(.clk, .in(inc_branches), .out(in_sig[7]));
    assign in_sig[8] = inc_pipeline_stalls; // perf_counter_switch sw08(.clk, .in(inc_pipeline_stalls), .out(in_sig[8]));
	
    perf_counter_register #(
        .width(width),
        .MMaddress(32'h0000_0000)
    ) counter00(.hit(hit_sig[0]), .dataout(dataout_sig[0]), .increment(in_sig[0]), .*);

    perf_counter_register #(
        .width(width),
        .MMaddress(32'h0000_0001)
    ) counter01(.hit(hit_sig[1]), .dataout(dataout_sig[1]), .increment(in_sig[1]), .*);

    perf_counter_register #(
        .width(width),
        .MMaddress(32'h0000_0002)
    ) counter02(.hit(hit_sig[2]), .dataout(dataout_sig[2]), .increment(in_sig[2]), .*);

    perf_counter_register #(
        .width(width),
        .MMaddress(32'h0000_0003)
    ) counter03(.hit(hit_sig[3]), .dataout(dataout_sig[3]), .increment(in_sig[3]), .*);

    perf_counter_register #(
        .width(width),
        .MMaddress(32'h0000_0004)
    ) counter04(.hit(hit_sig[4]), .dataout(dataout_sig[4]), .increment(in_sig[4]), .*);

    perf_counter_register #(
        .width(width),
        .MMaddress(32'h0000_0005)
    ) counter05(.hit(hit_sig[5]), .dataout(dataout_sig[5]), .increment(in_sig[5]), .*);

    perf_counter_register #(
        .width(width),
        .MMaddress(32'h0000_0006)
    ) counter06(.hit(hit_sig[6]), .dataout(dataout_sig[6]), .increment(in_sig[6]), .*);

    perf_counter_register #(
        .width(width),
        .MMaddress(32'h0000_0007)
    ) counter07(.hit(hit_sig[7]), .dataout(dataout_sig[7]), .increment(in_sig[7]), .*);

    perf_counter_register #(
        .width(width),
        .MMaddress(32'h0000_0008)
    ) counter08(.hit(hit_sig[8]), .dataout(dataout_sig[8]), .increment(in_sig[8]), .*);

    always_comb
    begin
        unique case (address)
            32'h0000_0000 : dataout = dataout_sig[0];
            32'h0000_0001 : dataout = dataout_sig[1];
            32'h0000_0002 : dataout = dataout_sig[2];
            32'h0000_0003 : dataout = dataout_sig[3];
            32'h0000_0004 : dataout = dataout_sig[4];
            32'h0000_0005 : dataout = dataout_sig[5];
            32'h0000_0006 : dataout = dataout_sig[6];
            32'h0000_0007 : dataout = dataout_sig[7];
            32'h0000_0008 : dataout = dataout_sig[8];
            default : dataout = {width{1'b0}};
        endcase
    end

endmodule // perf_counter

module perf_counter_switch (
	input   logic   clk,
	input   logic   in,
	output  logic   out
);
    /**
     * The switch will hold the `out` signal high for one clock whenever `in` turns high
     */
	logic last;
	assign out = in & ~last;

	always_ff @(posedge clk)
	begin
		last = in;
	end
endmodule // perf_counter_switch

module perf_counter_register #(
    parameter MMaddress = 32'h0000_0000,
    parameter width = 32
) (
    input   logic               clk,
    input   logic               write,
    input   logic [31:0]        address,
    input   logic               increment,
    input   logic [width-1:0]   datain,
    output  logic               hit,
    output  logic [width-1:0]   dataout
);

    logic override;
    assign hit = address == MMaddress;
    assign override = write & hit;

    register #(.width(width)) counter(
        .clk,
        .load(override | increment),
        .in(override ? datain : dataout + 32'd1),
        .out(dataout)
    );

endmodule // perf_counter_register
