`define BITS 30
module shift_register(
input CLK,
input RST,
input DATA_IN,
output BIT_OUT,
output [`BITS-1:0] BYTE_OUT
);

//--------------------------------------------------------------
// signal definitions
//--------------------------------------------------------------

//shift register signals
reg [`BITS-1:0] bitShiftReg;
reg [`BITS-1:0] byteShiftReg[11:0];
integer i;

//--------------------------------------------------------------
// shift register
//--------------------------------------------------------------

//shift register
always @(posedge CLK)
begin

//bit shift register
bitShiftReg <= {bitShiftReg[`BITS-2:0],DATA_IN};

//byte shift register
byteShiftReg[0] <= bitShiftReg;
for(i=1;i<12;i=i+1)
byteShiftReg[i] <= byteShiftReg[i-1];
end

//--------------------------------------------------------------
// outputs
//--------------------------------------------------------------

//module output wires
assign BIT_OUT = bitShiftReg[`BITS-1];
assign BYTE_OUT = byteShiftReg[11];
endmodule
