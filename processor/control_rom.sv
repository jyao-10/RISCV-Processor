import rv32i_types::*;

module control_rom (
	input rv32i_opcode opcode,
	input logic [2:0] funct3,
	input logic [6:0] funct7,
	output rv32i_control_word ctrl
);

logic bit30;
assign bit30 = funct7[5];

always_comb
begin
	/* Default assignments */
	ctrl.opcode = opcode;
	ctrl.load_regfile = 1'b0;

	ctrl.alumux_sel = 3'b000;
	ctrl.alumux2_sel = 3'b000;
	ctrl.exoutmux_sel = 2'b00;
	ctrl.aluop = alu_add;
	ctrl.cmpop = branch_funct3_t'(funct3);
	ctrl.is_branch = 1'b0;
	ctrl.is_jump = 1'b0;
	ctrl.is_jalr = 1'b0;

	ctrl.write_data = 1'b0;
	ctrl.read_data = 1'b0;
	ctrl.write_mask = 4'b1111;
	ctrl.load_type = 3'b000;
	
	ctrl.wbmux_sel = 1'b0;

	ctrl.instr_type_load = 1'b0;
	ctrl.instr_type_store = 1'b0;
	ctrl.forwarding_exempt = 1'b0;

	/* Assign control signals based on opcode */
	case(opcode)
		op_lui: begin
			ctrl.load_regfile = 1'b1;
			ctrl.alumux_sel = 3'd2;
			ctrl.alumux2_sel = 3'd1;
			ctrl.forwarding_exempt = 1'b1;
		end

		op_auipc: begin
			ctrl.load_regfile = 1'b1;
			ctrl.alumux_sel = 3'd1;
			ctrl.alumux2_sel = 3'd1;
			ctrl.forwarding_exempt = 1'b1;
		end
		
		op_jal: begin
			ctrl.is_jump = 1'b1;
			ctrl.exoutmux_sel = 2'b10;
			ctrl.load_regfile = 1'b1;
			ctrl.forwarding_exempt = 1'b1;
		end
		
		op_jalr: begin
			ctrl.is_jump = 1'b1;
			ctrl.is_jalr = 1'b1;
			ctrl.exoutmux_sel = 2'b10;
			ctrl.load_regfile = 1'b1;
		end
		
		op_br: begin
			ctrl.is_branch = 1;
		end
		
		op_load: begin
			ctrl.load_regfile = 1'b1;
			ctrl.read_data = 1'b1;
			ctrl.wbmux_sel = 1'b1;
			ctrl.instr_type_load = 1'b1;

			case(load_funct3_t'(funct3))
				lw: begin
					ctrl.load_type = 3'b000; // full word
				end
				lhu: begin
					ctrl.load_type = 3'b001; // half unsigned
				end
				lh: begin
					ctrl.load_type = 3'b010; // half signed
				end
				lbu: begin
					ctrl.load_type = 3'b011; // byte unsigned
				end
				lb: begin
					ctrl.load_type = 3'b100; // byte signed
				end
				default: $display("Unrecognized load: ", funct3);
			endcase
		end
		
		op_store: begin
			ctrl.alumux2_sel = 3'd2;
			ctrl.write_data = 1'b1;
			ctrl.instr_type_store = 1'b1;

			case(store_funct3_t'(funct3))
				sb: ctrl.write_mask = 4'b0001;
				sh: ctrl.write_mask = 4'b0011;
				sw: ctrl.write_mask = 4'b1111;
				default: $display("Unrecognized store: ", funct3);
			endcase
		end
		
		op_imm: begin
			ctrl.load_regfile = 1'b1;
			case(funct3)
				slt: ctrl.exoutmux_sel = 2'b01;
				sltu: ctrl.exoutmux_sel = 2'b01;
				sr: ctrl.aluop = bit30 ? alu_sra : alu_srl;
				default: ctrl.aluop = alu_ops'(funct3); // everything else
			endcase
		end
		
		op_reg: begin
			ctrl.load_regfile = 1'b1;
			ctrl.alumux2_sel = 3'd3;
			case(funct3)
				slt: ctrl.exoutmux_sel = 2'b01;
				sltu: ctrl.exoutmux_sel = 2'b01;
				sr: ctrl.aluop = bit30 ? alu_sra : alu_srl;
				add: ctrl.aluop = bit30 ? alu_sub : alu_add;
				default: ctrl.aluop = alu_ops'(funct3); // everything else
			endcase
		end
		
		op_csr: begin
			// TODO: implement cp3 (I type)
		end

		default: begin
			ctrl = 0; /* Unknown opcode, set control word to zero */
		end
	endcase
end

endmodule : control_rom

