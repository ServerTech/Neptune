//*******************************************************************************************************************************************************/
//  Module Name: mult
//  Module Type: Multiplexer
//  Author: Shreyas Vinod
//  Purpose: Multiplexers for Neptune I v3.0
//  Description: Combinatorial 2 to 1 and 4 to 1 multiplexers for use in Neptune I v3.0.
//*******************************************************************************************************************************************************/

module mult_2_to_1(sel, a_in, b_in, out);

	// Parameter Definitions

	parameter width = 'd16; // Data Width

	// Inputs

	input wire sel;
	input wire [width-1:0] a_in, b_in;

	// Outputs

	output reg [width-1:0] out;

	// Multiplexing Block

	always@(sel, a_in, b_in) begin
		case(sel) // synthesis parallel_case
			1'b0: out [width-1:0] = a_in [width-1:0];
			1'b1: out [width-1:0] = b_in [width-1:0];
			default: out [width-1:0] = {width{1'b0}};
		endcase
	end

endmodule

module mult_4_to_1(sel, a_in, b_in, c_in, d_in, out);

	// Parameter Definitions

	parameter width = 'd16; // Data Width

	// Inputs

	input wire [1:0] sel;
	input wire [width-1:0] a_in, b_in, c_in, d_in;

	// Outputs

	output reg [width-1:0] out;

	// Multiplexing Block

	always@(sel, a_in, b_in, c_in, d_in) begin
		case(sel) // synthesis parallel_case
			2'b00: out [width-1:0] = a_in [width-1:0];
			2'b01: out [width-1:0] = b_in [width-1:0];
			2'b10: out [width-1:0] = c_in [width-1:0];
			2'b11: out [width-1:0] = d_in [width-1:0];
			default: out [width-1:0] = {width{1'b0}};
		endcase
	end

endmodule