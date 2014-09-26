//*******************************************************************************************************************************************************/
//  Module Name: alu
//  Module Type: Arithmetic Logic Unit
//  Author: Shreyas Vinod
//  Purpose: Arithmetic Logic Unit for Neptune I v3.0
//  Description: A simple synchronous Arithmetic Logic Unit. Supports only signed operations. Overflow/Underflow detection for addition, subtraction and
//               multiplication.
//*******************************************************************************************************************************************************/

module alu(clk, rst, en, opcode, a_in, b_in, o, z, n, cond, d_out);

	// Parameter Definitions

	parameter width = 'd16; // ALU Width

	// Inputs

	input wire clk /* System Clock */, rst /* System Reset. Resets Overflow Flag and Detection and Result Register */, en /* Arithmetic Logic Unit (ALU) Enable */; // Management Interfaces
	input wire [4:0] opcode /* 5-bit Operation Code for the ALU. Refer to documentation. */;
	input wire signed [width-1:0] a_in /* Operand A Input Port */, b_in /* Operand B Input Port */;

	// Outputs

	output reg o /* Overflow/Underflow/Carry Flag Register */;
	output wire z /* Zero Flag Register (Embedded in res_out) */, n /* Negative/Sign Flag Register */;
	output reg cond /* Conditional Flag Register */;
	output wire [width-1:0] d_out /* Data Output Port */;

	// Internals

	reg [1:0] chk_oflow /* Check for Overflow/Underflow */;
	reg signed [width+width:0] res_out /* ALU Process Result Register */;

	// Flag Logic

	assign z = ~|res_out; // Zero Flag
	assign n = res_out[width-1]; // Negative/Sign Flag

	// Output Logic

	assign d_out [width-1:0] = res_out [width-1:0];

	// Overflow/Underflow Detection Block

	always@(chk_oflow, res_out) begin
		case(chk_oflow) // synthesis parallel_case
			2'b00: o = 1'b0;
			2'b01: begin
				if(res_out [width:width-1] == (2'b01 || 2'b10)) o = 1'b1; // Scenario only possible on Overflow/Underflow.
				else o <= 1'b0;
			end
			2'b10: begin
				if((res_out[width+width]) && (~res_out [width+width-1:width-1] != 0)) o = 1'b1; // Multiplication result is negative.
				else if ((~res_out[width+width]) && (res_out [width+width-1:width-1] != 0)) o = 1'b1; // Multiplication result is positive.
				else o = 1'b0;
			end
			2'b11: o = 1'b0;
			default: o = 1'b0;
		endcase
	end

	// ALU Processing Block

	always@(posedge clk) begin
		if(rst) begin
			cond <= 1'b0;
			chk_oflow <= 2'b0;
			res_out [width+width:0] <= {width+width{1'b0}};
		end else if(en) begin
			case(opcode) // synthesis parallel_case
				5'b00000: res_out [width-1:0] <= 0; // Zero
				5'b00001: res_out [width-1:0] <= a_in [width-1:0]; // A
				5'b00010: res_out [width-1:0] <= b_in [width-1:0]; // B
				5'b00011: begin
					chk_oflow <= 2'b01;
					res_out [width:0] <= a_in [width-1:0] + 1'b1; // Increment A
				end
				5'b00100: begin
					chk_oflow <= 2'b01;
					res_out [width:0] <= a_in [width-1:0] - 1'b1; // Decrement A
				end
				5'b00101: begin
					chk_oflow <= 2'b01;
					res_out [width:0] <= {a_in[width-1], a_in [width-1:0]} + {b_in[width-1], b_in [width-1:0]}; // Add A + B
				end
				5'b00110: begin
					chk_oflow <= 2'b01;
					res_out [width:0] <= {a_in[width-1], a_in [width-1:0]} - {b_in[width-1], b_in [width-1:0]}; // Subtract A - B
				end
				5'b00111: begin
					chk_oflow <= 2'b10;
					res_out [width+width:0] <= a_in [width-1:0] * b_in [width-1:0]; // Multiply A * B
				end
				5'b01000: begin
					if(a_in [width-1:0] == b_in [width-1:0]) cond <= 1'b1; // Compare A == B, set Conditional Register as result
					else cond <= 1'b0;
				end
				5'b01001: begin
					if(a_in [width-1:0] < b_in [width-1:0]) cond <= 1'b1; // Compare A < B, set Conditional Register as result
					else cond <= 1'b0;
				end
				5'b01010: begin
					if(a_in [width-1:0] > b_in [width-1:0]) cond <= 1'b1;// Compare A > B, set Conditional Register as result
					else cond <= 1'b0;
				end
				5'b01011: res_out [width-1:0] <= ~a_in [width-1:0]; // One's Complement of A
				5'b01100: res_out [width-1:0] <= ~a_in [width-1:0] + 1'b1; // Two's Complement of A
				5'b01101: res_out [width-1:0] <= a_in [width-1:0] & b_in [width-1:0]; // Bitwise AND
				5'b01110: res_out [width-1:0] <= a_in [width-1:0] | b_in [width-1:0]; // Bitwise OR
				5'b01111: res_out [width-1:0] <= a_in [width-1:0] ^ b_in [width-1:0]; // Bitwise XOR
				5'b10000: res_out [width-1:0] <= {a_in [width-2:0], 1'b0}; // Logical Left Shift A
				5'b10001: res_out [width-1:0] <= {1'b0, a_in [width-1:1]}; // Logical Right Shift A
				5'b10010: res_out [width-1:0] <= {a_in [width-1], a_in [width-1:1]}; // Arithmetic Right Shift A
				5'b10011: res_out [width-1:0] <= {a_in [width-2:0], a_in [width-1]}; // Rotate Left A
				5'b10100: res_out [width-1:0] <= {a_in [0], a_in [width-1:1]}; // Rotate Right A
				default: begin
					cond <= 1'b0;
					res_out [width-1:0] <= 0;
				end
			endcase
		end
	end

endmodule
