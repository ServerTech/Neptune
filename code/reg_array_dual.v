//*******************************************************************************************************************************************************/
//  Module Name: reg_array_dual
//  Module Type: Synchronous Dual Port Memory Array
//  Author: Shreyas Vinod
//  Purpose: General Purpose Register Array for Neptune I v3.0
//  Description: A synchronous unidirectional dual port general purpose register array with a simple fault mechanism to detect dual write single address
//               collisions.
//*******************************************************************************************************************************************************/

module reg_array_dual(clk, rst, we1, we2, add1, add2, wr1, wr2, mem_fault, rd1, rd2);

	// Parameter Definitions

	parameter width = 'd16; // Register Array Width
	parameter depth = 'd8; // Register Array Depth
	parameter add_width = 'd3; // Register Addressing Width

	// Inputs

	input wire clk /* System Clock */, rst /* System Reset. Resets Memory Fault Flag. */; // Management Interfaces
	input wire we1 /* Write Enable to Port I */, we2 /* Write Enable to Port II */; // Control Interfaces
	input wire [add_width-1:0] add1 /* Address for Port I */, add2 /* Address for Port I */;
	input [width-1:0] wr1 /* Write Port I */, wr2 /* Write Port II */;

	// Outputs

	output reg mem_fault /* Memory Write Collision Fault Flag */;
	output reg [width-1:0] rd1 /* Read Port I */, rd2 /* Read Port II */;

	// Internal

	reg [width-1:0] mem_arr [0:depth-1] /* Memory Array */;

	// Fault Logic

	always@(posedge clk) begin
		if(rst) mem_fault <= 1'b0;
		else if((we1 && we2) && (add1 && add2)) mem_fault <= 1'b1;
	end

	// Memory Read Block

	always@(posedge clk) begin
		rd1 [width-1:0] <= mem_arr[add1] [width-1:0]; // Read to Port I if re1 is true.
		rd2 [width-1:0] <= mem_arr[add2] [width-1:0]; // Read to Port II if re2 is true.
	end

	// Memory Write Block

	always@(posedge clk) begin
		if(we1) mem_arr[add1] [width-1:0] <= wr1 [width-1:0]; // Write from Port I if we1 is true.
		if(we2) mem_arr[add2] [width-1:0] <= wr2 [width-1:0]; // Write from Port II if we2 is true.
	end

endmodule