import rv32i_types::*;

module cpu
(
    input clk,

    /* Hit Miss Counters */
    input logic hit_a, miss_a, hit_b, miss_b, hit_l2, miss_l2,

    /* Port A: Instructions */
    output logic read_a,
    output logic write_a,
    output logic [3:0] wmask_a,
    output logic [31:0] address_a,
    output logic [31:0] wdata_a,
    input logic resp_a,
    input logic [31:0] rdata_a,

    /* Port B: Data */
    output logic read_b,
    output logic write_b,
    output logic [3:0] wmask_b,
    output logic [31:0] address_b,
    output logic [31:0] wdata_b,
    input logic resp_b,
    input logic [31:0] rdata_b
);

assign read_a = 1'b1;
assign write_a = 1'b0;
assign wmask_a = 4'b0000;
assign wdata_a = 32'h0000_0000;

rv32i_word pcmux_out, pc_plus_4;

/*
 * ==============================================
 * Control Words + Variables
 * ==============================================
 * we save the PC for calculations in the EX stage (we might not need this)
 * we save the IR for calculations in the IR stage
 */
rv32i_control_word ID_ctrl;
rv32i_control_word EX_ctrl;
rv32i_control_word MEM_ctrl;
rv32i_control_word WB_ctrl;

rv32i_word ID_pc;
rv32i_word EX_pc;

rv32i_word ID_ir;
rv32i_word EX_ir;
rv32i_word MEM_ir;
rv32i_word WB_ir;

rv32i_word EX_br_pc; // expected branch pc
rv32i_word EX_jump_pc; // expected jump pc

rv32i_word WB_out; // output from the writeback stage

rv32i_word ID_rs1_out, ID_rs2_out; // rs1_out and rs2_out were fetched in the ID stage
rv32i_word EX_rs1_out, EX_rs2_out; // we need rs1_out and rs2_out in the EX stage
rv32i_word MEM_rs2_out; // we only need rs2_out in the MEM stage

rv32i_word EX_ex_out, MEM_ex_out, WB_ex_out; // we only need ex out in EX, MEM, and WB

rv32i_word MEM_data_out, WB_data_out; // we only need data out in MEM and WB

logic EX_br_en;

logic mem_a_ready, mem_b_ready;

logic stall_EX;

/*
 * ==============================================
 * Pipeline Stalling
 * ==============================================
 */
assign mem_a_ready = resp_a | ~(read_a | write_a);
assign mem_b_ready = resp_b | ~(read_b | write_b);

/*
 * ==============================================
 * Instruction Fetch Stage
 * ==============================================
 * This stage pulls instructions from the main memory at PC and sends the data
 * to the next stage (instruction decode).
 * We only have to pass two chunks of data to the next stage -- PC and IR.
 */

assign pc_plus_4 = ID_pc + 4;

logic [31:0] jump_addr;
mux2 jump_mux (
	.sel(EX_ctrl.is_jump),
	.a(EX_br_pc),
	.b(EX_jump_pc),
	.f(jump_addr)
);

logic pc_jump, pc_jump_ready;
assign pc_jump = (EX_ctrl.is_branch & EX_br_en) | EX_ctrl.is_jump;
assign pc_jump_ready = ~pc_jump | (pc_jump & mem_a_ready); // this signal is used to stall EX if mem_a is not ready

logic [31:0] btb_branch;
logic btb_prediction;
//btb
btb btb(
	.clk, 
	.btb_load(pc_jump),
	//.pc(ID_pc),
	.pc(pcmux_out),
	.ex_branch_pc(EX_pc),
	.branch_target(jump_addr), 
	
	.btb_branch_target(btb_branch),
	.btb_prediction(btb_prediction)

);

mux2 pcmux (
	.sel(pc_jump),
	.a(pc_plus_4),
	.b(jump_addr),
	.f(pcmux_out)
);

logic [31:0] branchmux_out;
mux2 branchmux (
	//.sel(), //prediction
	.sel(btb_prediction),
	.a(pcmux_out),
	.b(btb_branch),
	.f(branchmux_out)
);





// Set Memory Signals
assign address_a = branchmux_out;

// The pipeline register is split into two because we only want to clear ID if
// mem_a is not ready but stall PC (instead of clearing it too) 
pipeline_register #(.width($bits(rv32i_word))) IF_ID (
	.clk,
	.stall(~mem_b_ready | stall_EX),
	.clear(~mem_a_ready),
	.in(rdata_a),
	.out(ID_ir)
);

pipeline_register #(.width($bits(rv32i_word))) IF_ID2 (
	.clk,
	.stall(~mem_a_ready | ~mem_b_ready | stall_EX),
	.clear(1'b0),
	.in(branchmux_out),
	.out(ID_pc)
);

/*
 * ==============================================
 * Instruction Decode Stage
 * ==============================================
 */

// decode using control rom
rv32i_opcode opcode;
logic [2:0] funct3;
logic [6:0] funct7;

assign funct3 = ID_ir[14:12];
assign funct7 = ID_ir[31:25];
assign opcode = rv32i_opcode'(ID_ir[6:0]);

control_rom ctrl_rom (
	.opcode(opcode),
	.funct3(funct3),
	.funct7(funct7),
	.ctrl(ID_ctrl)
);

regfile regfile (
    .clk,
    .load(WB_ctrl.load_regfile),
    .in(WB_out),
    .src_a(ID_ir[19:15]), // ID -> rs1
    .src_b(ID_ir[24:20]), // ID -> rs2
    .dest(WB_ir[11:7]),
    .reg_a(ID_rs1_out),
    .reg_b(ID_rs2_out)
);

pipeline_register #(.width($bits(rv32i_word) * 4 + $bits(rv32i_control_word))) ID_EX (
	.clk,
	.stall(~mem_b_ready | stall_EX | ~pc_jump_ready),
	.clear(pc_jump),
	.in({ID_pc, ID_ir, ID_rs1_out, ID_rs2_out, ID_ctrl}),
	.out({EX_pc, EX_ir, EX_rs1_out, EX_rs2_out, EX_ctrl})
); 

/*
 * ==============================================
 * Execute Stage
 * ==============================================
 */

logic wdatabmux_sel;
logic [2:0] rs1_outmux_sel, rs2_outmux_sel;
rv32i_word EX_rs1_out_forwarded, EX_rs2_out_forwarded;

data_forwarding_unit dfu0 (
	.EX_ctrl,
	.MEM_ctrl,
	.WB_ctrl,

	.EX_ir,
	.MEM_ir,
	.WB_ir,

	.stall_EX,
	.rs1_outmux_sel,
	.rs2_outmux_sel,
	.wdatabmux_sel
);

mux4 rs1_outmux (
	.sel(rs1_outmux_sel),
	.a(EX_rs1_out),
	.b(MEM_ex_out),
	.c(WB_out),
	// UNUSED: .d(),
	.f(EX_rs1_out_forwarded)
);

mux4 rs2_outmux (
	.sel(rs2_outmux_sel),
	.a(EX_rs2_out),
	.b(MEM_ex_out),
	.c(WB_out),
	// UNUSED: .d(),
	.f(EX_rs2_out_forwarded)
);

logic [31:0] EX_jalr_temp_pc;

logic [31:0] EX_i_imm;
logic [31:0] EX_b_imm;
logic [31:0] EX_j_imm;
logic [31:0] EX_u_imm;
logic [31:0] EX_s_imm;

assign EX_i_imm = {{21{EX_ir[31]}}, EX_ir[30:20]};
assign EX_b_imm = {{20{EX_ir[31]}}, EX_ir[7], EX_ir[30:25], EX_ir[11:8], 1'b0};
assign EX_j_imm = {{12{EX_ir[31]}}, EX_ir[19:12], EX_ir[20], EX_ir[30:21], 1'b0};
assign EX_u_imm = {EX_ir[31:12], 12'h000};
assign EX_s_imm = {{21{EX_ir[31]}}, EX_ir[30:25], EX_ir[11:7]};
 
logic [31:0] alumux_out, alumux2_out;

mux8 alumux (
	.sel(EX_ctrl.alumux_sel),
	.a(EX_rs1_out_forwarded),
	.b(EX_pc),
	.c(32'h0000_0000),
	// UNUSED: .d(),
	// UNUSED: .e(),
	// UNUSED: .f(),
	// UNUSED: .g(),
	// UNUSED: .h(),
	.i(alumux_out)
);

mux8 alumux2 (
	.sel(EX_ctrl.alumux2_sel),
	.a(EX_i_imm),
	.b(EX_u_imm),
	.c(EX_s_imm),
	.d(EX_rs2_out_forwarded),
	// UNUSED: .e(),
	// UNUSED: .f(),
	// UNUSED: .g(),
	// UNUSED: .h(),
	.i(alumux2_out)
);

rv32i_word EX_alu_out;

alu alu0 (
	.aluop(EX_ctrl.aluop),
	.a(alumux_out),
	.b(alumux2_out),
    .f(EX_alu_out)
);

// writeback return address (pc + 4) from the jump
logic [31:0] EX_ret_pc;
assign EX_ret_pc = EX_pc + 4;

mux4 exoutmux (
	.sel(EX_ctrl.exoutmux_sel),
	.a(EX_alu_out),
	.b({{31{1'b0}}, EX_br_en}),
	.c(EX_ret_pc),
	// UNUSED: .d(),
	.f(EX_ex_out)
);

cmp cmp0 (
	.cmpop(EX_ctrl.cmpop),
	.a(EX_rs1_out_forwarded),
	.b(EX_rs2_out_forwarded),
	.enable(EX_br_en)
);

pipeline_register #(.width($bits(rv32i_word) * 3 + $bits(rv32i_control_word))) EX_MEM (
	.clk,
	.stall(~mem_b_ready),
	.clear(pc_jump | stall_EX | ~pc_jump_ready),
	.in({EX_ir, EX_ex_out, EX_rs2_out_forwarded, EX_ctrl}),
	.out({MEM_ir, MEM_ex_out, MEM_rs2_out, MEM_ctrl})
);

assign EX_br_pc = EX_b_imm + EX_pc;
assign EX_jalr_temp_pc = EX_rs1_out_forwarded + EX_i_imm;
assign EX_jump_pc = EX_ctrl.is_jalr ? ({EX_jalr_temp_pc[31:1], 1'b0}) : (EX_pc + EX_j_imm);

/*
 * ==============================================
 * Memory Stage
 * ==============================================
 */

logic [31:0] wdata_out, rdata_in;
logic perf_counter_hit, perf_counter_stall;
logic [31:0] perf_counter_out;

assign perf_counter_stall = ~mem_a_ready | ~mem_b_ready | stall_EX;

perf_counter #(.width(32)) perfcounter0 (
	.clk,
	.write(MEM_ctrl.write_data),
	.address(MEM_ex_out),
	.datain(wdata_out),

    .inc_instr_cache_hit(hit_a), // l1 instr
    .inc_instr_cache_miss(miss_a),
    .inc_data_cache_hit(hit_b), // l1 data
    .inc_data_cache_miss(miss_b),
    .inc_l2_cache_hit(hit_l2), // l2
    .inc_l2_cache_miss(miss_l2),
    .inc_branch_prediction_hit(EX_ctrl.is_branch & ~EX_br_en), // branch prediction
    .inc_branches(EX_ctrl.is_branch & ~perf_counter_stall),
    .inc_pipeline_stalls(perf_counter_stall), // pipeline stalls

    .hit(perf_counter_hit),
    .dataout(perf_counter_out)
);

// Set Memory Signals
assign write_b = MEM_ctrl.write_data & ~perf_counter_hit;
assign read_b = MEM_ctrl.read_data & ~perf_counter_hit;
assign address_b = MEM_ex_out;
assign wmask_b = MEM_ctrl.write_mask;
assign wdata_b = wdata_out;

mux2 wdatabmux (
	.sel(wdatabmux_sel),
	.a(MEM_rs2_out),
	.b(WB_out),
	.f(wdata_out)
);

assign rdata_in = perf_counter_hit ? perf_counter_out : rdata_b;

mux8 memmux (
	.sel(MEM_ctrl.load_type),
	.a(rdata_in), // full word
	.b({{16{1'b0}}, rdata_in[15:0]}), // half unsigned
	.c({{16{rdata_in[15]}}, rdata_in[15:0]}), // half
	.d({{24{1'b0}}, rdata_in[7:0]}), // byte unsigned
	.e({{24{rdata_in[7]}}, rdata_in[7:0]}), // byte
	// UNUSED: .f(),
	// UNUSED: .g(),
	// UNUSED: .h(),
	.i(MEM_data_out)
);

pipeline_register #(.width($bits(rv32i_word) * 3 + $bits(rv32i_control_word))) MEM_WB (
	.clk,
	.stall(1'b0),
	.clear(~mem_b_ready),
	.in({MEM_ir, MEM_ex_out, MEM_data_out, MEM_ctrl}),
	.out({WB_ir, WB_ex_out, WB_data_out, WB_ctrl})
); 

/*
 * ==============================================
 * Write Back Stage
 * ==============================================
 */

mux2 wbmux (
	.sel(WB_ctrl.wbmux_sel),
	.a(WB_ex_out),
	.b(WB_data_out),
	.f(WB_out)
);

endmodule : cpu
