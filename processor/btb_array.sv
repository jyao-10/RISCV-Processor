module btb_array #(parameter width = 256, parameter height = 5)
(
    input clk,
    input write,
    input [4:0] index,
    input [width-1:0] datain,
    output logic [width-1:0] dataout
);

logic [width-1:0] data [2**height-1:0]; /* synthesis ramstyle = "logic" */

/* Initialize array */
initial
begin
    for (int i = 0; i < $size(data); i++)
    begin
        data[i] = 1'b0;
    end
end

always_ff @(posedge clk)
begin
    if (write == 1)
    begin
        data[index] = datain;
    end
end

assign dataout = data[index];

endmodule : btb_array
