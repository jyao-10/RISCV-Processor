typedef enum bit [1:0] {
    st_idle    = 2'b00,
    st_write_b = 2'b01,
    st_read_b  = 2'b10,
    st_read_a  = 2'b11
} arbiter_status_t;

module arbiter
(
    input clk,

    /* Port A: Instructions */
    input logic read_a,
    input logic write_a,
    input logic [31:0] address_a,
    input logic [255:0] wdata_a,
    output logic resp_a,
    output logic [255:0] rdata_a,

    /* Port B: Data */
    input logic read_b,
    input logic write_b,
    input logic [31:0] address_b,
    input logic [255:0] wdata_b,
    output logic resp_b,
    output logic [255:0] rdata_b,

    /* Outputs */
    output logic read,
    output logic write,
    output logic [31:0] address,
    output logic [255:0] wdata,
    input logic resp,
    input logic [255:0] rdata
);
	/**
	 * Simplified arbiter status
	 * b takes priority over a
	 */
	logic is_b;
	assign is_b = read_b | write_b;

	// input a
	assign resp_a = ~is_b & resp;
	assign rdata_a = rdata;

	// input b
	assign resp_b = is_b & resp;
	assign rdata_b = rdata;

	// output
	assign read = ~write_b & (read_a | read_b);
	assign write = write_b;
	assign address = is_b ? address_b : address_a;
	assign wdata = wdata_b;
	
	/*
	// semi simplified arbiter
	assign read = ~write_b & (read_a | read_b);
	assign write = write_b;
	assign address = is_b ? address_b : address_a;
	assign wdata = wdata_b;

	always_ff @(posedge clk)
    begin
    	resp_b <= 1'b0;
    	resp_a <= 1'b0;
  
		if (is_b & resp) begin
			resp_b <= 1'b1;
			rdata_b <= rdata;
		end
		if (~is_b & resp) begin
			resp_a <= 1'b1;
			rdata_a <= rdata;
		end
    end
    */

    /*
     * The logic for the arbiter works as so:
     * 1) if not currently working, wait for a write or read signal, forward correct signals to output, and set status
     * 2) if currently working, wait for resp, forward correct signals to input, and set status
     */

	/*

    // status codes for the arbiter
    arbiter_status_t status, next_status;
    logic is_write_b, is_read_a, is_read_b;
    assign is_write_b = status == st_write_b;
    assign is_read_a = status == st_read_a;
    assign is_read_b = status == st_read_b;

    // port a
    assign resp_a = resp & is_read_a;
    assign rdata_a = rdata;
    // port b
    assign resp_b = resp & (is_read_b | is_write_b);
    assign rdata_b = rdata;
    // outputs
    assign read = is_read_a | is_read_b;
    assign write = is_write_b;
    assign address = is_read_a ? address_a : address_b;
    assign wdata = wdata_b;

    // if arbiter is currently not working, wait for a write/read signal
    // otherwise wait for resp
    always_comb
    begin : status_logic
        next_status = status;
        if (status == st_idle) begin
            if (write_b)
                next_status = st_write_b;
            else if (read_b)
                next_status = st_read_b;
            else if (read_a)
                next_status = st_read_a;
        end else if (resp)
            next_status = st_idle;
    end

    // update status every clock
    always_ff @(posedge clk)
    begin : next_status_logic
        status <= next_status;
    end

	*/

endmodule // arbiter
