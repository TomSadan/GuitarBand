// CSCB58 Winter 2017 Final Project
// GuitarBand
// Names: Tom Sadan, Vladlen Lyudogovs'ky
module GuitarBand
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B,   						//	VGA Blue[9:0]
		HEX0, 
		HEX1
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	
	output [6:0] HEX0, HEX1;

	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial ground
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(1'b1),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
	wire [6:0] datain;
	wire load_x, load_y, load_r, load_c, ld_alu_out;
	wire go, loadEn;
	
	wire left, right;
	
	assign left = KEY[3];
	assign right = KEY[2];
	
	
	main m1(CLOCK_50, resetn, left, right, x, y, colour, data_result);

	
	wire [7:0] data_result;

	hex_decoder H0(
        .hex_digit(data_result[3:0]), 
        .segments(HEX0)
        );
        
    hex_decoder H1(
        .hex_digit(data_result[7:4]), 
        .segments(HEX1)
        );
endmodule
	

module main(
    input clk,
	 input resetn,
	 input left,
	 input right,
    output reg [7:0] x,
	 output reg [6:0] y,
	 output reg [2:0] colour,
	 output reg [7:0] data_result
    ); 
	reg [4:0] bool;
	 
   // input registers
   reg [7:0] x_pos;
	reg [6:0] y_pos;
	
	reg [27:0] counter;
	reg [27:0] counter2;
	
    // output of the alu
   reg [7:0] x_alu;
	reg [6:0] y_alu;
	reg[4:0] count;
	reg[4:0] clear;
	reg[4:0] draw;
	
	// different falling blocks x and y registers
	reg [7:0] x_2;
	reg [6:0] y_2;
	reg [7:0] x_3;
	reg [6:0] y_3;
	reg [7:0] x_4;
	reg [6:0] y_4;

	wire [0:0] clk_div; // Holds the value of the ratedivider clock
	wire [3:0] new_chord; // Register to store psuedo-random 4-bit number
	//initial begin
		//assign new_chord = 4'b1001; // Seed for pseudo-randomness, change it later
	//end
	rate_divider R(.clk(clk), .d(clk_div)); // The ratedivider clock is based off the clock provided to this module
	LFSR L(.clk(clk_div), .d(new_chord)); // Pseudo-random number generator
	
	// All 4 lanes of the game are stored in these registers [3 2 1 0] and they are 8-bit registers by default
	// These 1-bit registers represent the value popped out of each register on the clock cycle
	wire [0:0] s3_out;
	wire [0:0] s2_out;
	wire [0:0] s1_out;
	wire [0:0] s0_out;
	// These 8-bit registers represent the current values the registers hold, the 0th index being the top of the lane
	wire [7:0] s3_byte;
	wire [7:0] s2_byte;
	wire [7:0] s1_byte;
	wire [7:0] s0_byte;
	
	shift_register S3(.CLK(clk_div), .RST(resetn), .DATA_IN(new_chord[3]), .BIT_OUT(s3_out), .BYTE_OUT(s3_byte)); // leftmost lane
	shift_register S2(.CLK(clk_div), .RST(resetn), .DATA_IN(new_chord[2]), .BIT_OUT(s2_out), .BYTE_OUT(s2_byte)); // second leftmost lane
	shift_register S1(.CLK(clk_div), .RST(resetn), .DATA_IN(new_chord[1]), .BIT_OUT(s1_out), .BYTE_OUT(s1_byte)); // second rightmost lane
	shift_register S0(.CLK(clk_div), .RST(resetn), .DATA_IN(new_chord[0]), .BIT_OUT(s0_out), .BYTE_OUT(s0_byte)); // rightmost lane
	
	always@(posedge clk) begin
	    if(!resetn) begin
			  bool <= 4'd0;
       end
		 else if (counter == 28'd50000) begin 
			  // set the initial position of the user's block
			  if(x_pos == 0) begin
						x_pos <= 30;
				end
				// if FSM = 0, sets the positions of the user's block
			  if (bool == 4'd0) begin 
					if(count == 4'd2) begin
						// movement left of the user's block		
						if (~left) begin
							if(x_pos == 30) begin
								x_pos <= 120;
							
							end
						
						else begin
								x_pos <= x_pos - 30;
						end
						// movement right of the user's block
						end if(~right) begin
								
								if(x_pos == 120) begin
									x_pos <= 30;
								end
								else begin
									x_pos <= x_pos + 30;
								end
						end
						
						count <= 4'd0;
					end

					y_pos <= 100;
					bool <= 1;
			  end
			  // if FSM = 1, draw the player's block and sets FSM to 3
			  else if(bool == 4'b1) begin
					y <= y_pos;
					x <= x_pos;
					colour <= 3'b111;
					bool <= 3;
					clear <=1;
			  end
				// if FSM = 4, wait state
			  else if (bool == 4'd4) begin
				
					bool <= 5;
			  end
			  // if FSM = 10, wait state
			  else if(bool == 4'd10) begin
			  
			  
					bool <= 2;
			  end
			  
			 
			  // if FSM = 9, updates the position for the falling blocks and checks the collisions
			  else if(bool == 4'd9) begin
					// collision for 1st block
					if(x_pos == x_2 && y_pos == y_2) begin
						// update the score
						data_result <= data_result + 1;
						// update the position
						if((x_pos + 30) > 120) begin
							
							x_2 <= 30;
							
						end
						else begin
							x_2 <= (x_pos + 30);
						end
						
						y_2 <= 0;
						
					end
					// collision for 2nd block
					else if(x_pos == x_3 && y_pos == y_3) begin
						// update the score
						data_result <= data_result + 5;
						// update the position
						if((x_pos - 30) < 0) begin
							
							x_3 <= 120;
							
						end
						else begin
							x_3 <= (x_pos - 30);
						end
						
						y_3 <= 0;

					end
					// collision for 3rd block
					else if(x_pos == x_4 && y_pos == y_4) begin 
						
						// decrease the score
						if(data_result >= 10) begin
						
							data_result <= data_result - 10;
						
						end
						else begin
						
						
							data_result <= 0;

						end
						
						// update the position
						if((x_2 + 30) > 120) begin
							
							x_4 <= 60;
							
						end
						else begin
							x_4 <= (x_2 + 30);
						end
						
						y_4 <= 0;
					
					end
					// if falling block reaches the bottom
					if(y_2 == 120) begin
					
						// update the position
						if((x_pos + 30) > 120 || (x_pos + 30) < 30) begin
							
							x_2 <= 60;
							
						end
						else begin
							x_2 <= (x_pos + 30);
						end

						y_2 <= 0;

					end
					// if falling block reaches the bottom
					else if(y_3 == 120) begin

						// update the position
						if((x_2 - 30) > 120 ||(x_2 - 30) < 0) begin
							x_3 <= 90;
						end
						else begin
							x_3 <= (x_2 - 30);
						end
						
						y_3 <= 0;

					end
					// if falling block reaches the bottom
					else if(y_4 == 120) begin
						// update the position
						if((x_3 + 30) > 120 ||(x_3 + 30) < 0) begin
							
							x_4 <= 90;
							
						end
						else begin
							
							x_4 <= (x_3 - 30);
						end
						
						y_4 <= 0;
					
					end 
		
					bool <= 0;
					
			  end
			  // if FSM = 5, wait state
			  else if(bool == 4'd5) begin
				

					bool <= 6;
			  end 
				// if FSM = 3, animate the position of the falling blocks
			  else if(bool == 4'd3) begin

					if(x_2 <= 0) begin
						x_2 <= 30;
					 end

					 if(x_3 <= 0) begin
						x_3 <= 90;
						y_3 <= 90;
					 end
	
					 if(x_4 <= 0) begin
						x_4 <= 120;
						y_4 <= 100;
					 end
					 
					 y_2 <= y_2 + 1;
					 y_3 <= y_3 + 1;
					 y_4 <= y_4 + 1;
					 
					 draw <= 1;
					 bool <= 4;
			  end
			  // if FSM = 2, erase the previous position of the player block
			  else if (bool == 4'd2)begin

					x <= x_pos;
					y <= y_pos;
					colour <= 3'b000;
					
					bool <= 9;
			  end
			  // if FSM = 6, wait state
			  else if (bool == 4'd6) begin
					
					 
					 
					 bool <= 7;
			  
			  end
			  // if FSM = 7, wait state
			  else if (bool == 4'd7) begin
					bool <= 8;
			  end
			  // if FSM = 8, wait state
			  else if (bool == 4'd8) begin
				
					bool <= 2;
			  end
			  
			  
			 
			  
			  // set the counter back to 0
			  counter <= 28'd0;
			  
			  
				// slow down the input, so the player block doesn't move too fast
			  count <= count + 1;

	    end
		 
		 else begin
			// this block operates outside of the rate divider and used for drawing and clearing falling blocks
			// increase counter, used as a rate divider
		 	counter <= counter + 1;
			
			// if clear = 1, signal for erasing the 1st falling block
			 if(clear == 4'd1) begin
			  
			  
					x <= x_2;
					y <= y_2;
					
					colour <= 1'b000;
					clear <= 2;
			  end
			  // if clear = 2, signal for erasing the 2nd falling block
			  else if(clear == 4'd2) begin
			  
			  
					x <= x_3;
					y <= y_3;
					clear <= 3;
			  end
			  // if clear = 3, signal for erasing the 3rd falling block
			  else if(clear == 4'd3) begin
			  
			  
					x <= x_4;
					y <= y_4;
					clear <= 0;
			  end
			  
			  
			  // if draw = 1, draw the 1st falling block
			  if(draw == 4'd1) begin
					x <= x_2;
					y <= y_2;
				

					colour <= 3'b110;
					draw <= 2;
			  
			  end
			  // if draw = 2, draw the 2nd falling block
			  else if(draw == 4'd2) begin
			  
					x <= x_3;
					y <= y_3;
				

					colour <= 3'b011;
					draw <= 3;
			  end
			  // if draw = 3, draw the 3rd falling block
			  else if(draw == 4'd3) begin
			  
					x <= x_4;
					y <= y_4;
				

					colour <= 3'b100;
					draw <= 0;
			  end
	    end
end
endmodule

// hex display
module hex_decoder(hex_digit, segments);
	input [3:0] hex_digit;
	output reg [6:0] segments;
	always @(*) begin
		case (hex_digit)
			4'h0: segments = 7'b100_0000;
			4'h1: segments = 7'b111_1001;
			4'h2: segments = 7'b010_0100;
			4'h3: segments = 7'b011_0000;
			4'h4: segments = 7'b001_1001;
			4'h5: segments = 7'b001_0010;
			4'h6: segments = 7'b000_0010;
			4'h7: segments = 7'b111_1000;
			4'h8: segments = 7'b000_0000;
			4'h9: segments = 7'b001_1000;
			4'hA: segments = 7'b000_1000;
			4'hB: segments = 7'b000_0011;
			4'hC: segments = 7'b100_0110;
			4'hD: segments = 7'b010_0001;
			4'hE: segments = 7'b000_0110;
			4'hF: segments = 7'b000_1110;   
			default: segments = 7'h7f;
		endcase
	end
endmodule
