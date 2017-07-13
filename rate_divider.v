`define count 25000000
module rate_divider (input clk, output d);
	reg [27:0] counter;
	reg [1:0] b;
	initial begin
		counter <= 0;
	end
	always @(posedge clk) begin
		counter <= counter + 1;
		b <= 1'b0;
		if (counter == `count) begin
			counter <= 0;
			b <= 1'b1;
		end
	end
	assign d = b[0];
endmodule
