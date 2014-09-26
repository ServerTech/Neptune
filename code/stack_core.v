//*******************************************************************************************************************************************************/
//  Module Name: stack
//  Module Type: Last in First Out (LIFO) Stack Register
//  Author: Shreyas Vinod
//  Purpose: Stack for Neptune I v3.0
//  Description: A synchronous Last in Firt Out (LIFO) Stack Register specifically designed for Neptune I.
//*******************************************************************************************************************************************************/

module stack(clk, rst, pop, push, wr, mem_fault, rd);

	// Parameter Definitions

	parameter width = 'd16; // Stack Data Width
	parameter depth = 'd256; // Stack Depth
	parameter add_width = 'd8; // Stack Addressing Width

	// Inputs

	input wire clk /* System Clock */, rst /* System Reset, Resets stack location. */; // Management Interfaces
	input wire pop /* Stack Pop Enable */, push /* Stack Push Enable */; // Control Interfaces
	input wire [width-1:0] wr /* Write Port */;

	// Outputs

	output reg mem_fault /* Memory Fault */;
	output reg [width-1:0] rd /* Read Port */;

	// Internal

	reg [add_width-1:0] stk_loc /* Stack Location Register */;
	reg [width-1:0] rd_out /* Storage Register for Read */;
	reg [width-1:0] mem_arr [0:depth-1] /* Two-Dimensional Memory Array (Width-Depth Matrix) */;

	// Stack Location Controller

	always@(posedge clk) begin
		if(rst) begin
			mem_fault <= 1'b0; // Resets the mem_fault flag if rst is true.
			stk_loc [add_width-1] <= {width{1'b0}};
		end else if(push && !pop) stk_loc <= stk_loc + 1'b1; // Pushes the stack forward.
		else if(pop && !push) stk_loc <= stk_loc - 1'b1; // Pulls the stack backward.
		else if ((push && pop) && (stk_loc == 8'b0) || (push && (stk_loc = 8'b11111111))) mem_fault <= 1'b1; // Memory Fault instates itself on push-pop collision.
	end

	// Memory Read Block

	always@(posedge clk) begin
		rd [width-1:0] <= mem_arr[stk_loc] [width-1:0]; // Reads the contents of memory at every positive clock edge.
	end

	// Memory Write Block

	always@(posedge clk) begin
		if(push) mem_arr[stk_loc] [width-1:0] <= wr [width-1:0]; // Writes the value at wr to memory if push is true.
	end

endmodule