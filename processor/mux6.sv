module mux6 #(parameter width = 32)
(
	input [2:0] sel,
	input [width-1:0] a, b, c, d, e, f,
	output logic [width-1:0] g
);

logic [width-1:0] out;
assign g = out;

always_comb
begin
	if (sel == 3'b000)
		out = a;
	else if (sel == 3'b001)
		out = b;
	else if (sel == 3'b010)
		out = c;
	else if (sel == 3'b011)
		out = d;
	else if (sel == 3'b100)
		out = e;
	else // if (sel == 3'b101)
		out = f;
	end
endmodule : mux6
