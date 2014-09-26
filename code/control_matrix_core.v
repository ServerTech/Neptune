//*******************************************************************************************************************************************************/
//  Module Name: control_matrix
//  Module Type: Moore State Machine
//  Author: Shreyas Vinod
//  Purpose: Control Matrix for Neptune I v3.0
//  Description: A Moore State Machine designed to be Neptune I's Control Matrix. The next state is determined by comparing the current OPcode to the
//               State Clock Register, a four bit register that keeps track of the progress of the current instruction. The State Clock is incremented
//               after every microinstruction. The Instruction Register is built-in to the Control Matrix.
//*******************************************************************************************************************************************************/

module control_matrix(clk, rst, dma_req, rf_mem_fault, stack_mem_fault, alu_o_flag, alu_z_flag, alu_n_flag, alu_cond_flag, mar_incr, alu_enable, we_in, ins_in, dma_appr, sys_halt, prc, intr_ack, rf_add1, rf_add2, alu_opcode, state);
	
	// Parameter Definitions

	parameter width = 'd16; // Data Width
	parameter rf_add_width = 'd3; // Register File Depth
	parameter ins_width = 'd16; // Instruction Width, heavily impacts the Instruction Decode and Execute Process
	
	// Inputs

	input wire clk /* System Clock */, rst /* System Reset. Resets States, State Clock and Halt conditions */, dma_req /* Direct Memory Access (DMA) Request */; // Management Interfaces
	input wire rf_mem_fault /* Register File Memory Fault */, stack_mem_fault /* Stack Memory Fault */;
	input wire alu_o_flag /* ALU Overflow Flag */, alu_z_flag /* ALU Zero Flag */, alu_n_flag /* ALU Sign Flag */, alu_cond_flag /* ALU Conditional Flag */;
	input wire mar_incr /* Direct Memory Access (DMA) Increment Memory Address Register (MAR) Request */;
	input wire [2:0] we_in /* Direct Memory Access (DMA) External Write Enable Request */;
	input wire [width-1:0] ins_in /* Input Port for Instructions */;

	// Outputs

	output wire dma_appr /* DMA Approval Notification */, sys_halt /* System Halt Notification */, prc /* Process Notification */, intr_ack /* Interrupt Acknowledge Notification */;
	output reg alu_enable /* Arithmetic Logic Unit (ALU) Enable */;
	output reg [rf_add_width-1:0] rf_add1 /* Register File (RF) Port I Address */, rf_add2 /* Register File (RF) Port II Address */;
	output reg [4:0] alu_opcode /* Arithmetic Logic Unit (ALU) OPcode */;
	output reg [15:0] state /* 16-bit State Register */;

	// Internal

	wire sys_mem_fault /* System Fault Flag */;
	reg dma_appr_buf /* DMA Approval Notification Buffer */, hlt /* Halt Register */, intr_ack_buf /* Interrupt Acknowledge Notification Buffer */;
	reg [5:0] stclk /* State Clock */;
	reg [ins_width-1:0] ins_reg /* Instruction Register */;

	// Fault Logic

	assign sys_fault = rf_mem_fault || stack_mem_fault; // System Fault on Memory Fault

	// Notification Translation Logic

	assign dma_appr = dma_appr_buf; // DMA Approval Notification
	assign sys_halt = hlt; // System Halt Notification
	assign prc = |stclk; // Translate Process Notification Signal from State Clock.
	assign intr_ack = intr_ack_buf; // Interrupt Acknowledge Notification

	// State Logic

	always@(posedge clk) begin
		if(dma_req && rst) begin // DMA Mode
			dma_appr_buf <= 1'b1;
			intr_ack_buf <= 1'b0;
			hlt <= 1'b0;
			alu_enable <= 1'b1;
			stclk [5:0] <= 6'b0;

			// Direct Memory Access (DMA) Block

			if(mar_incr) state [15:0] <= 16'b0001000000000000; // Increment Memory Address Register (MAR)
			else begin
				case(we_in) // synthesis parallel_case
					3'b000: state [15:0] <= 16'b0; // No Write DMA Mode
					3'b001: state [15:0] <= 16'b0000100000000000; // Write to Register File (RF)
					3'b010: state [15:0] <= 16'b0; // No Write DMA Mode
					3'b011: state [15:0] <= 16'b0000001000000000; // Write to Random Access Memory (RAM)
					3'b100: state [15:0] <= 16'b1000000000000000; // Write to Program Counter (PC)
					3'b101: state [15:0] <= 16'b0010000000000000; // Write to Memory Address Register (MAR)
					3'b110: state [15:0] <= 16'b0; // No Write DMA Mode
					3'b111: state [15:0] <= 16'b0; // No Write DMA Mode
					default: state [15:0] <= 16'b0; // No Write DMA Mode
				endcase
			end
		end else if(rst || dma_req) begin // Reset
			dma_appr_buf <= 1'b0;
			intr_ack_buf <= 1'b0;
			hlt <= 1'b0;
			alu_enable <= 1'b0;
			stclk [5:0] <= 6'b0;
			rf_add1 [rf_add_width-1:0] <= {rf_add_width{1'b0}};
			rf_add2 [rf_add_width-1:0] <= {rf_add_width{1'b0}};
			alu_opcode [4:0] <= 5'b0;
			state [15:0] <= 16'b0;
		end else if(sys_fault) begin // Fault Encounter Interrupt
			dma_appr_buf <= 1'b0;
			intr_ack_buf <= 1'b1;
			hlt <= 1'b1;
			stclk [5:0] <= 6'b0;
			state [15:0] <= 16'b0;
		end else if(sys_halt) begin // Halt
			dma_appr_buf <= 1'b0;
			intr_ack_buf <= 1'b0;
			hlt <= 1'b1;
			stclk [5:0] <= 6'b0;
			state [15:0] <= 16'b0;
		end else begin // Process
			dma_appr_buf <= 1'b0;
			intr_ack_buf <= 1'b0;

			// Instruction Fetch Phase

			if(stclk [5:0] == 6'b0) begin // T0
				stclk [5:0] <= stclk [5:0] + 1'b1;
				state [15:0] <= 16'b0000000000010000; // Select MAR Write Source Multiplexer to PC
			end else if(stclk [5:0] == 6'b000001) begin // T1
				stclk [5:0] <= stclk [5:0] + 1'b1;
				state [15:0] <= 16'b0010000000010000; // Write to MAR
			end else if(stclk [5:0] == 6'b000010) begin // T2
				stclk [5:0] <= stclk [5:0] + 1'b1;
				state [15:0] <= 16'b0100000000010000; // RAM Read Time, Increment PC
			end else if(stclk [5:0] == 6'b000011) begin // T3
				stclk [5:0] <= stclk [5:0] + 1'b1;
				ins_reg [ins_width-1:0] <= ins_in [ins_width-1:0]; // Updates Instruction Register with value in the RAM Read Bus
				state [15:0] <= 16'b0000000001101111; // Fetch Instruction, Set Multiplexers to optimal modes

			end else begin

			// Instruction Execute Phase

				casez(ins_reg [ins_width-1:ins_width-4]) // synthesis parallel_case
					4'b10??: begin // Arithmetic
						case(stclk) // synthesis parallel_case
							6'b000100: begin // T4
								stclk [5:0] <= stclk [5:0] + 1'b1;
								rf_add1 [rf_add_width-1:0] <= ins_reg [8:6];
								rf_add2 [rf_add_width-1:0] <= ins_reg [5:3];
								alu_opcode [4:0] <= ins_reg [13:9];
							end
							6'b000101: begin // T5
								alu_enable <= 1'b1;
								stclk [5:0] <= stclk [5:0] + 1'b1;
							end
							6'b001010: begin // T10
								alu_enable <= 1'b0;
								stclk [5:0] <= stclk [5:0] + 1'b1;
							end
							6'b001011: begin // T11
								rf_add2 [rf_add_width-1:0] <= ins_reg [2:0];
								stclk [5:0] <= stclk [5:0] + 1'b1;
							end
							6'b001100: begin // T12
								stclk [5:0] <= 6'b0;
								state [15:0] <= 16'b0000010001101111; // Write to RFPII
							end
							default: begin
								stclk [5:0] <= stclk [5:0] + 1'b1;
							end
						endcase
					end

					4'b0110: begin // No Operation
						stclk [5:0] <= 6'b0;
						state [15:0] <= 16'b0000000001101111;
					end
					
					4'b0111: begin // Halt
						stclk [5:0] <= 6'b0;
						hlt <= 1'b1;
						state [15:0] <= 16'b0;	
					end

					default: begin // No Operation
						stclk [5:0] <= 6'b0;
						state [15:0] <= 16'b0000000001101111;
					end
				endcase
			end
		end
	end

endmodule