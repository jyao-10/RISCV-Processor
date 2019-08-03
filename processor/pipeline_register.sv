module pipeline_register #(parameter width = 32)
(
    input clk,
    input stall,
    input clear,
    input [width-1:0] in,
    output logic [width-1:0] out
);

logic [width-1:0] data;

/* Altera device registers are 0 at power on. Specify this
 * so that Modelsim works as expected.
 */
initial
begin
    data = 1'b0;
end

always_ff @(posedge clk)
begin
    // in all cases, do not clear the register if stalled
    if (~stall)
    begin
        data = clear ? {width{1'b0}} : in;
    end
end

always_comb
begin
    out = data;
end

endmodule : pipeline_register
