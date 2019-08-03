
module regfile
(
    input clk,
    input load,
    input [31:0] in,
    input [4:0] src_a, src_b, dest,
    output logic [31:0] reg_a, reg_b
);

logic [31:0] data [32] /* synthesis ramstyle = "logic" */;

/* Altera device registers are 0 at power on. Specify this
 * so that Modelsim works as expected.
 */
initial
begin
    for (int i = 0; i < $size(data); i++)
    begin
        data[i] = 32'b0;
    end
end

always_ff @(posedge clk)
begin
    if (load && dest)
    begin
        data[dest] = in;
    end
end

always_comb
begin
    if (src_a == 5'd0) // register 0 is always 0
        reg_a = 32'b0;
    else // check if being loaded
        reg_a = load & (dest == src_a) ? in : data[src_a];

    if (src_b == 5'd0) // register 0 is always 0
        reg_b = 32'b0;
    else // check if being loaded
        reg_b = load & (dest == src_b) ? in : data[src_b];
end

endmodule : regfile
