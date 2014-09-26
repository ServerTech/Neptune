//*******************************************************************************************************************************************************/
//  Module Name: smr_reg
//  Module Type: Synchronous Register
//  Author: Shreyas Vinod
//  Purpose: Memory Address Register (MAR) and Program Counter (PC) for Neptune I v3.0
//  Description: A synchronous register specifically designed for Neptune I's Memory Address Register (MAR) and Program Counter (PC) with memory reset
//               support.
//*******************************************************************************************************************************************************/

module smr_reg(clk, rst, we, incr, wr, rd);

	// Parameter Definitions

	parameter width = 'd16; // Register Width
	parameter add_width = 'd13; // Addressing Width, cannot be larger than the Data Width

	// Inputs

	input wire clk /* System Clock Input */, rst /* System Reset. Resets memory contents. */; // Management Interfaces
	input wire we /* Register Write Enable */, incr /* Increment contents */; // Control Interfaces
	input wire [width-1:0] wr /* Write Port */;

	// Outputs

	output wire [add_width-1:0] rd /* Read Port to A Bus */;

	// Internal

	reg [width-1:0] mem /* Register Memory */;

	// Read Logic

	assign rd [add_width-1:0] = mem [add_width-1:0];

	// Memory Write Block

	always@(posedge clk) begin
		if(rst) mem [width-1:0] <= {width{1'b0}}; // Resets the contents of memory if rst is true.
		else if(we) mem [width-1:0] <= wr [width-1:0]; // Writes the value at wr to memory if we is true.
		else if(incr) mem [width-1:0] <= mem [width-1:0] + 1'b1; // Increment Memory contents.
	end

endmodule