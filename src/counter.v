/*
	Simple counter with generic bitwidth
*/

`default_nettype none
`ifndef __COUNTER__
`define __COUNTER__

module counter
#(
	parameter BW = 8 // optional parameter
) (
	// define I/O's of the module
	input                clk_i,
	input                nrst_i,
	output wire [BW-1:0] counter_val_o
);

	// start the module implementation

	// register to store the counter value
	reg [BW-1:0] counter_val;
	
	// assign the counter value to the output
	assign counter_val_o = counter_val;
	
	always @(posedge clk_i) begin
		// gets active whenever a positive edge of the clock signal occurs
		
		if (nrst_i == 0'b1) begin // if reset is enabled
			counter_val <= {BW{1'b0}};
		end else begin
			counter_val <= counter_val + {{(BW-1){1'b0}}, 1'b1};
		end
	end
endmodule // counter

`endif
`default_nettype wire
