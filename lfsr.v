`define BITS 30

module LFSR (input clk, output reg [`BITS-1:0] d);
// Currently set up as a 4 bit psuedo-random register. Change BITS for a different register size.
reg [`BITS-1:0] f;
initial begin
	f <= 4'b1011;
end
always @(posedge clk) begin
    f <= { f[`BITS-2:0], f[`BITS-1] ^ f[`BITS-2] };
end
endmodule
