// import rv32i_types::*;

module mp3
(
	input clk,

    output logic read,
    output logic write,
    output logic [31:0] address,
    output logic [255:0] wdata,
    input logic resp,
    input logic [255:0] rdata
);

    /* Hit Miss Counter signals */
    logic hit_a, miss_a, hit_b, miss_b, hit_l2, miss_l2;

    /* Port A: Instructions (CPU->L1) */
    logic read_a;
    logic write_a;
    logic [3:0] wmask_a;
    logic [31:0] address_a;
    logic [31:0] wdata_a;
    logic resp_a;
    logic [31:0] rdata_a;

    /* Port A: Instructions (L1->ARB) */
    logic read_a_arb;
    logic write_a_arb;
    logic [31:0] address_a_arb;
    logic [255:0] wdata_a_arb;
    logic resp_a_arb;
    logic [255:0] rdata_a_arb;

    /* Port B: Data (CPU->L1) */
    logic read_b;
    logic write_b;
    logic [3:0] wmask_b;
    logic [31:0] address_b;
    logic [31:0] wdata_b;
    logic resp_b;
    logic [31:0] rdata_b;

    /* Port B: Data (L1->ARB) */
    logic read_b_arb;
    logic write_b_arb;
    logic [31:0] address_b_arb;
    logic [255:0] wdata_b_arb;
    logic resp_b_arb;
    logic [255:0] rdata_b_arb;

    /* L2 Cache */
    logic read_l2;
    logic write_l2;
    logic [31:0] address_l2;
    logic [255:0] wdata_l2;
    logic resp_l2;
    logic [255:0] rdata_l2;

    /* Eviction write buffer */
    logic read_ewb;
    logic write_ewb;
    logic [31:0] address_ewb;
    logic [255:0] wdata_ewb;
    logic resp_ewb;
    logic [255:0] rdata_ewb;

    cpu cpu0(
    	.*
    );

    cache icache (
        .clk,
        .hit(hit_a),
        .miss(miss_a),
        // from CPU
        .mem_address(address_a),
        .mem_rdata(rdata_a),
        .mem_wdata(wdata_a),
        .mem_read(read_a),
        .mem_write(write_a),
        .mem_byte_enable(wmask_a),
        .mem_resp(resp_a),
        // to arb
        .pmem_address(address_a_arb),
        .pmem_rdata(rdata_a_arb),
        .pmem_wdata(wdata_a_arb),
        .pmem_read(read_a_arb),
        .pmem_write(write_a_arb),
        .pmem_resp(resp_a_arb)
    );

    cache dcache (
        .clk,
        .hit(hit_b),
        .miss(miss_b),
        // from CPU
        .mem_address(address_b),
        .mem_rdata(rdata_b),
        .mem_wdata(wdata_b),
        .mem_read(read_b),
        .mem_write(write_b),
        .mem_byte_enable(wmask_b),
        .mem_resp(resp_b),
        // to arb
        .pmem_address(address_b_arb),
        .pmem_rdata(rdata_b_arb),
        .pmem_wdata(wdata_b_arb),
        .pmem_read(read_b_arb),
        .pmem_write(write_b_arb),
        .pmem_resp(resp_b_arb)
    );

    arbiter arb0 (
        .clk,

        /* Port A: Instructions */
        .read_a(read_a_arb),
        .write_a(write_a_arb),
        .address_a(address_a_arb),
        .wdata_a(wdata_a_arb),
        .resp_a(resp_a_arb),
        .rdata_a(rdata_a_arb),

        /* Port B: Data */
        .read_b(read_b_arb),
        .write_b(write_b_arb),
        .address_b(address_b_arb),
        .wdata_b(wdata_b_arb),
        .resp_b(resp_b_arb),
        .rdata_b(rdata_b_arb),

        /* Outputs */
        .read(read_l2),
        .write(write_l2),
        .address(address_l2),
        .wdata(wdata_l2),
        .resp(resp_l2),
        .rdata(rdata_l2)
    );


    l2cache l2cache0(
        .clk,
        .hit(hit_l2),
        .miss(miss_l2),

        // Arbiter signals
        .mem_address(address_l2),
        .mem_rdata(rdata_l2),
        .mem_wdata(wdata_l2),
        .mem_read(read_l2),
        .mem_write(write_l2),
        .mem_resp(resp_l2),

        // Eviction Write Buffer signals
        .pmem_address(address_ewb),
        .pmem_rdata(rdata_ewb),
        .pmem_wdata(wdata_ewb),
        .pmem_read(read_ewb),
        .pmem_write(write_ewb),
        .pmem_resp(resp_ewb)
    );

    eviction_write_buffer write_buff(
        .clk,

        .mem_address(address_ewb),
        .mem_rdata(rdata_ewb),
        .mem_wdata(wdata_ewb),
        .mem_read(read_ewb),
        .mem_write(write_ewb),
        .mem_resp(resp_ewb),

        // Physical memory signals
        .pmem_address(address),
        .pmem_rdata(rdata),
        .pmem_wdata(wdata),
        .pmem_read(read),
        .pmem_write(write),
        .pmem_resp(resp)
    );

endmodule : mp3
