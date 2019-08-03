module cache_control (
	input	logic			clk,    // Clock

	input	logic			pmem_resp,
	input	logic			miss,
	input	logic			dirty,

	output	logic			evict,
	output	logic			read,
	output	logic			commit,

	output	logic			pmem_write,
	output	logic			pmem_read
);

enum int unsigned {
	s_hit,
	s_evict,
	s_read
} state, next_state;

always_comb
begin: state_actions
	/* Default output assignments */
	pmem_write = 1'b0;
	pmem_read = 1'b0;

	evict = 1'b0;
	read = 1'b0;
	commit = 1'b0;

	/* Actions for each state */
	case(state)
		s_hit: begin
		end
		
		s_evict: begin
			evict = 1'b1;
			pmem_write = 1'b1;
		end

		s_read: begin
			read = 1'b1;
			pmem_read = 1'b1;
			commit = pmem_resp;
		end
	endcase
end

always_comb
begin: next_state_logic
	next_state = state;
	case(state)
		s_hit: begin
			if (miss & dirty)
				next_state = s_evict; 
			else if (miss & ~dirty)
				next_state = s_read;
		end
		s_evict: if (pmem_resp)
			next_state = s_read;
		s_read: if (pmem_resp)
			next_state = s_hit;
		default: next_state = s_hit;
	endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
	state <= next_state;
end

endmodule