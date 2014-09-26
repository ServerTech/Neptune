//*******************************************************************************************************************************************************/
//	Module Name: bcd_converter
//  Module Type: Binary to BCD Conversion Module
//	Author: Shreyas Vinod
//	Purpose: Output User Interfacing Support Module
//	Description: A sequential Binary to BCD converter designed to act as a support module for Neptune I's Front Panel User Interface. It utilizes the
//               the 'Shift and Add Three' algorithm to convert the number to BCD. Negative numbers are converted back from two's complement for
//               BCD conversion, while the sign attribute represents that the converted number is negative.
//*******************************************************************************************************************************************************/

module bcd_converter(clk, wr, data_in, data_out);
	
	// Parameter Definitions

	parameter width = 'd16; // Data Width (Signed) (Maximum 16)

	// Inputs

	input wire clk /* Clock (Full Speed) */, wr /* Write Request Notification */;
	input wire [width-1:0] data_in /* Data Input Port */;

	// Outputs

	output wire [20:0] data_out /* Data Output Port */;

	// Internal

	reg sign /* Represents the sign of the number being currently converted */;
	reg [1:0] stclk /* State Clock, keeps track of the current conversion stage */;
	reg [4:0] shst /* Shift State, keeps track of the number of shifts completed */;
	reg [3:0] five, four, three, two, one; // These represent five BCD digits, four bits each.
	reg [width-1:0] data_in_buf /* Data Input Buffer */;
	reg [20:0] data_out_buf /* Data Output Buffer */;

	// Initialization

	initial begin
		stclk [1:0] <= 2'b0;
	end

	// Output Logic

	assign data_out = data_out_buf; // Data Output

	// Conversion Block ('Shift and Add Three'/'Double Dabble' algorithm. )

	always@(posedge clk) begin
		case(stclk) // synthesis parallel_case
			2'b00: begin
				if(!wr) begin
					stclk [1:0] <= 2'b01;
					data_in_buf [width-1:0] <= data_in [width-1:0]; // Current Input buffered in.
					sign <= 1'b0;
					shst [4:0] <= 5'b0;
					five [3:0] <= 4'b0;
					four [3:0] <= 4'b0;
					three [3:0] <= 4'b0;
					two [3:0] <= 4'b0;
					one [3:0] <= 4'b0;
				end
			end
			2'b01: begin
				stclk [1:0] <= 2'b10;
				if(data_in_buf[width-1]) begin
					sign <= 1'b1;
					data_in_buf [width-1:0] <= ~data_in_buf [width-1:0] + 1'b1; // Inverts and adds one if the number is negative to convert it back from two's complement.
				end
			end
			2'b10: begin
				stclk [1:0] <= 2'b11;
				shst [4:0] <= shst + 1'b1;
				{five, four, three, two, one, data_in_buf} <= {five, four, three, two, one, data_in_buf} << 1; // Shift Left
			end
			2'b11: begin
				if(shst [4:0] == (width)) begin
					stclk [1:0] <= 2'b00;
					data_out_buf [20:0] <= {sign, five, four, three, two, one};
				end else begin
					stclk [1:0] <= 2'b10;

					// Add three to those BCD registers whose current value is greater than or equal to five.

					if(five [3:0] >= 4'b0101) five [3:0] <= five [3:0] + 2'b11;
					if(four [3:0] >= 4'b0101) four [3:0] <= four [3:0] + 2'b11;
					if(three [3:0] >= 4'b0101) three [3:0] <= three [3:0] + 2'b11;
					if(two [3:0] >= 4'b0101) two [3:0] <= two [3:0] + 2'b11;
					if(one [3:0] >= 4'b0101) one [3:0] <= one [3:0] + 2'b11;
				end
			end
		endcase
	end

endmodule
