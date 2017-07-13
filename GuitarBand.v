// CSCB58 Winter 2017 Final Project
// Cave Catchers
// Names: Nathan Seebarran, Sadman Rafid, Kareem Hage-Ali, Raphael Ambegia 
// Description: Catch Yellows(+1)
//					 Catch Cyans(+5!)
//					 Avoid Reds(-10!!)
//					 gg
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
	
	assign left = SW[2];
	assign right = SW[0];
	
	
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

`define LANE_COUNT 2
`define LANE1_X 30
`define LANE2_X 90

`define HITBLOCK_Y 10

`define RED 3'b100
`define GREEN 3'b010
`define BLUE 3'b001
`define WHITE 3'b111
`define BLACK 3'b00

`define TICKS_PER_FRAME 250000
`define LANE_LENGTH 30


`define DRAW_COUNT 33

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
	 
	 
	//reg [4:0] ;
	reg pre_left;
	reg left_click;
	
	reg pre_right;
	reg right_click;
	
	reg [27:0] frame_counter;
	reg [3:0] lane_counter;
	reg [4:0] draw_counter;
	
    // output of the alu
   reg [7:0] x_alu;
	reg [6:0] y_alu;
	reg[4:0] count;
	reg[4:0] clear;
	reg[4:0] draw;
	
	// different falling blocks x and y registers
	reg clock_div;
	reg [7:0] blockX1;
	reg [6:0] blockY1;
	reg [7:0] blockX2;
	reg [6:0] blockY2;
	//reg [3:0] new_chord; // Register to store psuedo-random 4-bit number
	reg [3:0] f;
	initial begin 
		
		blockX1 <= `LANE1_X;
		blockY1 <= 0;
		blockX2 <= `LANE2_X;
		blockY2 <= 0;
		lane_counter <= 0;
		frame_counter <= 0;
		draw_counter <= 0;
		
		left_click <= 0;
		pre_left <= 1;
		right_click <= 0;
		pre_right <= 1;
		
		clock_div <= 0;
		//new_chord <= 4'b1011;
		
		f <= 4'b1011;
	end
	
	wire [0:0] clk_div; // Holds the value of the ratedivider clock
	//initial begin
		//assign new_chord = 4'b1001; // Seed for pseudo-randomness, change it later
	//end
	//rate_divider R(.clk(clk), .d(clk_div)); // The ratedivider clock is based off the clock provided to this module
	//LFSR L(.clk(clock_div), .d(new_chord)); // Pseudo-random number generator

	// All 4 lanes of the game are stored in these registers [3 2 1 0] and they are 8-bit registers by default
	// These 1-bit registers represent the value popped out of each register on the clock cycle
	wire s3_out;
	wire [0:0] s2_out;
	wire [0:0] s1_out;
	wire [0:0] s0_out;
	// These 8-bit registers represent the current values the registers hold, the 7th index being the top of the lane
	wire [`LANE_LENGTH:0] s3_byte;
	wire [`LANE_LENGTH:0] s2_byte;
	wire [`LANE_LENGTH:0] s1_byte;
	wire [`LANE_LENGTH:0] s0_byte;
	
	shift_register S3(.CLK(clock_div), .RST(resetn), .DATA_IN(f[3]), .BIT_OUT(s3_out), .BYTE_OUT(s3_byte)); // leftmost lane
	shift_register S2(.CLK(clock_div), .RST(resetn), .DATA_IN(f[2]), .BIT_OUT(s2_out), .BYTE_OUT(s2_byte)); // second leftmost lane
	//shift_register S1(.CLK(clock_div), .RST(resetn), .DATA_IN(f[1]), .BIT_OUT(s1_out), .BYTE_OUT(s1_byte)); // second rightmost lane
	//shift_register S0(.CLK(clock_div), .RST(resetn), .DATA_IN(f[0]), .BIT_OUT(s0_out), .BYTE_OUT(s0_byte)); // rightmost lane
	
	integer index;
	
	always@(posedge clk) begin
		f <= { f[2:0], f[3] ^ f[2] };
		if(draw_counter == `DRAW_COUNT) begin
			draw_counter <= 0;
			// If we process every lane
			lane_counter <= lane_counter + 1;
			if(lane_counter == `LANE_COUNT) begin
				lane_counter <= 0;
				// Once every lane is proccesed, increment tick
				frame_counter <= frame_counter + 1;
				// If we reach the ticks per frame
				if(frame_counter == `TICKS_PER_FRAME) begin
					frame_counter <= 0;
					clock_div <= 1;
				end
			end
		end
		if(frame_counter == 100000) begin
			clock_div <= 0;
		end

		
		// Update Lane 1
		if(lane_counter == 0) begin
			// Detect trigger point for button
			pre_left <= left;
			if(left == 1 && pre_left == 0) begin
				left_click <= 1;
			end
			// Draw blocks in a lane
			if(draw_counter < `LANE_LENGTH) begin
				x<= `LANE1_X;
				y<= 1 + draw_counter;
				if(s3_byte[draw_counter] == 1)
					colour <= `RED;
				else
					colour <= `BLACK;
			end
			// Delete block hitter at the end of frame
			if(draw_counter == `LANE_LENGTH && left_click == 0) begin
				if (frame_counter == 0) begin
					x <= `LANE1_X;
					y <= `LANE_LENGTH + 1;
					colour <= 3'b101;
				end
			end
			// Draw block hitte
			if(draw_counter == `LANE_LENGTH && left_click == 1) begin
				x <= `LANE1_X;
				y <= `LANE_LENGTH + 1;
				colour <= `WHITE;
				left_click <= 0;
				if (s3_byte[`LANE_LENGTH] == 1)
					data_result <= data_result + 1;
				else
					if(data_result > 5)
						data_result <= data_result - 5;
					else
						data_result <= 0;
			end

		end
		
		
		  //-----------//
		 //    Copy   //
		//-----------//
		// Update Lane 2
		/*
		else if(lane_counter == 1) begin
			pre_right <= right;
			if(right == 1 && pre_right == 0) begin
				right_click <= 1;
			end
	
			if(draw_counter == 0 && right_click == 0) begin
				if (frame_counter == 0) begin
					x <= `LANE2_X;
					y <= `HITBLOCK_Y;
					colour <= `BLACK;
				end
			end
			else if(draw_counter == 0 && right_click == 1) begin
				x <= `LANE2_X;
				y <= `HITBLOCK_Y;
				colour <= `WHITE;
				right_click <= 0;
			end
			/*
			else if(draw_counter == 1) begin
				x <= blockX2;
				y <= blockY2;			
				colour <= `GREEN;
				if (frame_counter == 0) begin
					blockY2 <= blockY2 + 1;		
				end
			end
		
			if(draw_counter > 3 && draw_counter < 24) begin
				x<= `LANE2_X;
				y<= 1 + draw_counter - 4;
				if(s2_byte[draw_counter - 4] == 1)
					colour <= `GREEN;
				else
					colour <= `BLACK;
			end
		end
		*/
		// Go to next draw
		draw_counter <= draw_counter + 1;
	end

endmodule

// hex display
module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
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
endmodule

