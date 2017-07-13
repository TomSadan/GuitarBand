`define BITS 4

module LFSR (input clk, output reg [`BITS-1:0] d);
// Currently set up as a 4 bit psuedo-random register. Change BITS for a different register size.
always @(posedge clk) begin
    d <= { d[`BITS-2:0], d[`BITS-1] ^ d[`BITS-2] };
end
endmodule
