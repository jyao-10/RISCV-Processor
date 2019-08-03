import rv32i_types::*;

module btb
(
	input clk,
	
	input btb_load,
	input rv32i_word pc,
	input rv32i_word ex_branch_pc,
	input rv32i_word branch_target, 

	output rv32i_word btb_branch_target,
	output logic btb_prediction
);

logic[26:0] btb_tag_out;
logic[31:0] btb_target_out;
logic btb_prediction_out;

always_comb begin
	btb_branch_target = 32'b0;
	btb_prediction = 1'b0;
	if (btb_tag_out == {pc[31:7], pc[1:0]}) begin
		btb_branch_target = btb_target_out;
		btb_prediction = btb_prediction_out;
	end

end



btb_array #(.width(27), .height(5)) btb_tag 
(
	.clk,
	.write(btb_load),
	.index(pc[6:2]), 
	.datain({ex_branch_pc[31:7], ex_branch_pc[1:0]}), 
	.dataout(btb_tag_out)
);


btb_array #(.width(32), .height(5)) btb_targetpc
(
	.clk,
	.write(btb_load),
	.index(pc[6:2]),
	.datain(branch_target),
	.dataout(btb_target_out)
);

btb_array #(.width(1), .height(5)) btb_pred
(
	.clk,
	.write(btb_load),
	.index(pc[6:2]), 
	.datain(btb_load), 
	.dataout(btb_prediction_out)
);


endmodule : btb