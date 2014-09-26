//*******************************************************************************************************************************************************/
//  Module Name: reg_array_single
//  Module Type: Synchronous Single Port Memory Array
//  Author: Shreyas Vinod
//  Purpose: Random Access Memory (RAM) for Neptune I v3.0
//  Description: A synchronous unidirectional single port general purpose register array.
//*******************************************************************************************************************************************************/

module reg_array_single(clk, we, add, wr, rd);

	// Parameter Definitions
	
	parameter width = 'd16; // Register Array Width
	parameter depth = 'd8192; // Register Array Depth
	parameter add_width = 'd13; // Register Addressing Width

	// Inputs

	input wire clk /* System Clock */; // Management Interfaces
	input wire we /* Write Enable */; // Control Interfaces
	input wire [add_width-1:0] add /* Address */;
	input wire [width-1:0] wr /* Write Port */;
	
	// Outputs
	
	output reg [width-1:0] rd /* Read Port */;

	// Internal

	reg [width-1:0] mem_arr [0:depth-1] /* Two-dimensional Memory Array (Width-Depth Matrix) */;

	// Memory Read Block

	always@(posedge clk) begin
		rd [width-1:0] <= mem_arr[add] [width-1:0]; // Assigns Port Read Storage Register the value of memory at add if re is true and we is false.
	end

	// Memory Write Block

	always@(posedge clk) begin
		if(we) mem_arr[add] [width-1:0] <= wr [width-1:0]; // Writes to memory at add the value at Port if we is true.
	end

endmodule