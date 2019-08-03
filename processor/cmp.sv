import rv32i_types::*;

module cmp
(
	input branch_funct3_t cmpop,
	input rv32i_word a, b,
	output logic enable
);

logic out;
assign enable = out;

always_comb
begin
	case(cmpop)
		beq: out = a == b;
		bne: out = a != b;
		blt: out = $signed(a) < $signed(b);
		bge: out = $signed(a) >= $signed(b);
		bltu: out = a < b;
		bgeu: out = a >= b;
		slt: out = $signed(a) < $signed(b);
		sltu: out = a < b;
		default: begin
			out = 1'b0;
			$display("Unrecognized cmp: ", cmpop);
		end
	endcase
end

endmodule
