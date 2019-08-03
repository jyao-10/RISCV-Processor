module eviction_write_buffer_control (
	input	logic			clk,    // Clock

	input	logic			pmem_resp,
	input	logic			write,
	input	logic			read,
	input	logic			hit,

	output	logic			full,
	output	logic			evict,
	output	logic			write_to_buffer,
	output	logic			mem_resp,
	output	logic			pmem_read,
	output	logic			pmem_write
);

enum int unsigned {
	s_empty,
	s_full,
	s_evict
} state, next_state;

logic need_evict;
assign need_evict = (~read & ~write) | (~hit & write); 

always_comb
begin: state_actions
	/* Default output assignments */
	full = 1'b0;
	evict = 1'b0;
	write_to_buffer = write;
	mem_resp = pmem_resp;
	pmem_read = read;
	pmem_write = 1'b0;

	/* Actions for each state */
	case(state)
		s_empty: begin
			mem_resp = write | pmem_resp;
		end
		
		s_full: begin
			full = 1'b1;
			write_to_buffer = write & hit;
			mem_resp = need_evict ? 1'b0 : (hit | pmem_resp);
			pmem_read = ~hit & read;
			pmem_write = ~hit & write;
		end

		s_evict: begin
			evict = 1'b1;
			write_to_buffer = 1'b0;
			mem_resp = 1'b0;
			pmem_read = 1'b0;
			pmem_write = 1'b1;
		end
	endcase
end

always_comb
begin: next_state_logic
	next_state = state;
	case(state)
		s_empty: if (write)
			next_state = s_full;
		s_full: begin
			if (need_evict)
				next_state = s_evict;
			else
				next_state = s_full;
		end
		s_evict: begin
			if (pmem_resp)
				next_state = s_empty;
			else
				next_state = s_evict;
		end
		default: next_state = s_empty;
	endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
	state <= next_state;
end

endmodule
