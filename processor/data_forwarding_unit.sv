import rv32i_types::*;

module data_forwarding_unit (
	input rv32i_control_word EX_ctrl,
	input rv32i_control_word MEM_ctrl,
	input rv32i_control_word WB_ctrl,

	input rv32i_word EX_ir,
	input rv32i_word MEM_ir,
	input rv32i_word WB_ir,

	output logic stall_EX,
	output logic [2:0] rs1_outmux_sel,
	output logic [2:0] rs2_outmux_sel,
	output logic wdatabmux_sel
);

logic [4:0] EX_rs1, EX_rs2;
logic [4:0] MEM_rs2, MEM_dr;
logic [4:0] WB_dr;

assign EX_rs1 = EX_ir[19:15];
assign EX_rs2 = EX_ir[24:20];
assign MEM_rs2 = MEM_ir[24:20];
assign MEM_dr = MEM_ir[11:7];
assign WB_dr = WB_ir[11:7];

logic is_MEMMEM;

/*
 * ==============================================
 * Stalling
 * ==============================================
 * Stalling happens when there is a load in the MEM stage into register != r0
 * and there is an operation consuming rd in EX stage.
 */

logic stall_condition, stall_match_rs1, stall_match_rs2;

assign stall_condition = MEM_ctrl.load_regfile & MEM_ctrl.instr_type_load
	& ~(MEM_dr == 0) & ~EX_ctrl.forwarding_exempt; 
assign stall_match_rs1 = EX_rs1 == MEM_dr;
assign stall_match_rs2 = EX_rs2 == MEM_dr;
assign stall_EX = stall_condition & (stall_match_rs1 | stall_match_rs2);

/*
 * ==============================================
 * EX -> EX Forwarding
 * ==============================================
 * EX -> EX forwarding happens when a non-load instruction is in the MEM stage
 * into register rd != r0 and there is an operation consuming rd in the EX
 * stage.
 */

logic exex_condition, exex_match_rs1, exex_match_rs2;

assign exex_condition = MEM_ctrl.load_regfile & ~MEM_ctrl.instr_type_load
	& ~(MEM_dr == 0) & ~EX_ctrl.forwarding_exempt; 
assign exex_match_rs1 = EX_rs1 == MEM_dr; // WARN: duplicate of stall_match_rs1
assign exex_match_rs2 = EX_rs2 == MEM_dr; // WARN: duplicate of stall_match_rs2

/*
 * ==============================================
 * MEM -> EX Forwarding
 * ==============================================
 * MEM -> EX forwarding happens when an instruction is in the WB stage into
 * register rd != r0 and there is an operation consuming rd in the EX stage.
 * EX -> EX takes precendence over MEM -> EX
 */

logic memex_condition, memex_match_rs1, memex_match_rs2;

assign memex_condition = WB_ctrl.load_regfile & ~(WB_dr == 0)
	& ~EX_ctrl.forwarding_exempt;
assign memex_match_rs1 = EX_rs1 == WB_dr;
assign memex_match_rs2 = EX_rs2 == WB_dr;

/*
 * ==============================================
 * MEM -> MEM Forwarding
 * ==============================================
 * MEM -> MEM forwarding happens when there is a load instruction in the WB
 * stage into register rd != r0 and there is a store operation consuming rd in
 * the MEM stage for rs2. The rs1 case is handled by MEM -> EX since the MEM
 * stage never directly consumes rs1.
 */

logic memmem_condition, memmem_match_rs1, memmem_match_rs2;

assign memmem_condition = WB_ctrl.load_regfile & WB_ctrl.instr_type_load
	& ~(WB_dr == 0) & MEM_ctrl.instr_type_store;
assign memmem_match_rs2 = MEM_rs2 == WB_dr; // WARN: duplicate of memex_match_rs2
assign is_MEMMEM = memmem_condition & memmem_match_rs2;

always_comb
begin
	if (exex_condition & exex_match_rs1)
		rs1_outmux_sel = 2'b01;
	else if (memex_condition & memex_match_rs1)
		rs1_outmux_sel = 2'b10;
	else
		rs1_outmux_sel = 2'b00;

	if (exex_condition & exex_match_rs2)
		rs2_outmux_sel = 2'b01;
	else if (memex_condition & memex_match_rs2)
		rs2_outmux_sel = 2'b10;
	else
		rs2_outmux_sel = 2'b00;
end

assign wdatabmux_sel = is_MEMMEM;

endmodule : data_forwarding_unit
