//*******************************************************************************************************************************************************/
//  Module Name: Neptune_I
//  Module Type: 16-bit RISC Microprocessor Datapath
//  Author: Shreyas Vinod
//  Purpose: Neptune I Minicomputing v3.0
//  Description: A simplistic 16-bit microprocessor consisting of a 16-bit data bus and a 13-bit address bus. It features a RISC architecture. It has a
//               customised and simplified instruction set making programming the processor relatively easy. Powerful program flow altering capabilities
//               make hierarchical programming possible.
//*******************************************************************************************************************************************************/

module Neptune_I(clk, ui_rst, ui_dma_req, ui_wr, ui_add_wr, ui_incr_add, ui_clk_sel, ui_entity_sel, ui_data_in, clk_out, sys_dma_appr, sys_halt, prc, sys_intr_ack, ui_entity_out, ui_add_out, ui_data_out);

	// Parameter Definitions

	parameter width = 'd16; // Data Bus Width
	parameter rf_depth = 'd8; // Register File (RF) Depth
	parameter rf_add_width = 'd3; // Register File (RF) Addressing Width
	parameter ram_depth = 'd8192; // Random Access Memory (RAM) Depth
	parameter add_width = 'd13; // Addressing Width
	parameter stack_depth = 'd256; // Stack Depth
	parameter stack_add_width = 'd8; // Stack Address Width
	parameter disp_output_width = 'd20;  // Display Driver Data Width
	
	// Inputs

	input wire clk /* System Clock Input */, ui_rst /* External Reset Request */, ui_dma_req /* DMA Request */, ui_wr /* Write Request */, ui_add_wr /* Address Write Request */;
	input wire ui_incr_add /* Increment Address Request */, ui_clk_sel /* Clock Select */;
	input wire [2:0] ui_entity_sel /* Entity Select */;
	input wire [width-1:0] ui_data_in /* Data Input Port */;

	// Outputs

	output wire clk_out /* Clock Output for Display Driver peripherals */;
	output wire sys_dma_appr /* System DMA Approval Notification */, sys_halt /* System Halt Notification */, prc /* Process Notification */, sys_intr_ack /* Interrupt Acknowledge Notification */;
	output wire [2:0] ui_entity_out /* Entity Output Port */;
	output wire [4:0] ui_add_out /* Address Output Port */, ui_data_out /* Data Output Port */;

	// Internal

	wire sys_clk /* System Clock */, sys_rst /* System Reset */, sys_hrd_rst /* System Hard Reset */, sys_dma_req /* Direct Memory Access (DMA) Request from UI */; // System Control Internals
	wire [2:0] cm_we /* Control Matrix Write Enable Request */;
	wire [15:0] state /* 16-bit State Register (Stored by the Control Matrix) */;
	wire [disp_output_width-1:0] add_disp /* Address to Display */;
	wire [disp_output_width:0] data_disp /* Data to Display */;

	// Data Flow Nets

	wire [rf_add_width-1:0] fl_rf_add1 /* Register File (RF) Port I Addressing */;
	wire [add_width-1:0] fl_a_bus /* Memory Address Register (MAR) Read (Address Bus) */;
	wire [width-1:0] fl_dma /* Direct Memory Access (DMA) Data Flow */, fl_rfpi /* Register File (RF) Port I Read */, fl_rfpii /* Register File (RF) Port II Read */;
	wire [width-1:0] fl_rfpi_wr /* Register File (RF) Port I Write */, fl_rfpii_wr /* Register File (RF) Port II Write */;
	wire [width-1:0] fl_ram_rd /* Random Access Memory (RAM) Read */, fl_ram_wr /* Random Access Memory (RAM) Write */;
	wire [width-1:0] fl_pc_rd /* Program Counter (PC) Read */, fl_pc_wr /* Program Counter (PC) Write */;
	wire [width-1:0] fl_mar_wr /* Memory Address Register (MAR) Write */;
	wire [width-1:0] fl_stack_rd /* Stack Read */, fl_alu /* Arithmetic Logic Unit (ALU) Read */;

	// Flag Nets

	wire rf_mem_fault /* Register File (RF) Memory Fault, feedback to Control Matrix */, stack_mem_fault /* Stack Memory Fault, feedback to Control Matrix */;
	wire alu_o_flag /* ALU Overflow Flag, feedback to Control Matrix */, alu_z_flag /* ALU Zero Flag, feedback to Control Matrix */, alu_n_flag /* ALU Sign Flag, feedback to Control Matrix */;
	wire alu_cond_flag /* ALU Conditional Flag, feedback to Control Matrix */;

	// Internal Control Nets

	// Control Bits

	wire pc_we /* Program Counter (PC) Write Enable */, pc_incr /* Program Counter (PC) Increment */, mar_we /* Memory Address Register (MAR) Write Enable */;
	wire mar_incr /* Memory Address Register (MAR) Increment */, rf_we1 /* Register File Port I Write Enable */, rf_we2 /* Register File Port II Write Enable */;
	wire rf_mov /* Register File Cross-Layer Data Movement Enable */, ram_we /* Random Access Memory (RAM) Write Enable */, stack_pop /* Pop Stack contents */;
	wire stack_push /* Push Stack contents */;

	// Multiplexers

	wire pc_wr_src_sel /* Program Counter (PC) Write Source Select */, rf_add_src_sel /* Register File (RF) Port I Address Source Select */, ram_wr_src_sel /* Random Access Memory (RAM) Write Source Select */;
	wire [1:0] mar_wr_src_sel /* Memory Address Register (MAR) Write Source Select */, rf_wr_src_sel /* Register File (RF) Port I Write Source Select */;

	// Entity Control Interfaces

	wire ui_mar_incr /* Direct Memory Access (DMA) Memory Address Register (MAR) Increment Request */, alu_enable /* Arithmetic Logic Unit (ALU) Enable */;
	wire [rf_add_width-1:0] rf_add1, rf_add2; // Register File Port Addressing
	wire [4:0] alu_opcode /* Arithmetic Logic Unit (ALU) OPcode. Refer to documentation. */;

	// Control Net Assignments

	assign pc_we = state[15];
	assign pc_incr = state[14];
	assign mar_we = state[13];
	assign mar_incr = state[12];
	assign rf_we1 = state[11];
	assign rf_we2 = state[10];
	assign ram_we = state[9];
	assign stack_pop = state[8];
	assign stack_push = state[7];
	assign pc_wr_src_sel = state[6];
	assign mar_wr_src_sel [1:0] = state [5:4];
	assign rf_add_src_sel = state[3];
	assign rf_wr_src_sel [1:0] = state [2:1];
	assign ram_wr_src_sel = state[0];

	// Control Matrix Instantiation

	control_matrix control_matrix(
		.clk(sys_clk),
		.rst(sys_rst),
		.dma_req(sys_dma_req),
		.rf_mem_fault(rf_mem_fault),
		.stack_mem_fault(stack_mem_fault),
		.alu_o_flag(alu_o_flag),
		.alu_z_flag(alu_z_flag),
		.alu_n_flag(alu_n_flag),
		.alu_cond_flag(alu_cond_flag),
		.mar_incr(ui_mar_incr),
		.alu_enable(alu_enable),
		.we_in(cm_we),
		.ins_in(fl_ram_rd),
		.dma_appr(sys_dma_appr),
		.sys_halt(sys_halt),
		.prc(prc),
		.intr_ack(sys_intr_ack),
		.rf_add1(rf_add1),
		.rf_add2(rf_add2),
		.alu_opcode(alu_opcode),
		.state(state)
		);
		
	defparam control_matrix.width = width;
	defparam control_matrix.ins_width = width;
	defparam control_matrix.rf_add_width = rf_add_width;

	// User Interface Instantiation

	user_interface user_interface(
		.clk(clk),
		.rst(ui_rst),
		.dma_req(ui_dma_req),
		.dma_appr(sys_dma_appr),
		.sys_halt(sys_halt),
		.wr(ui_wr),
		.add_wr(ui_add_wr),
		.incr_add(ui_incr_add),
		.clk_sel(ui_clk_sel),
		.entity_sel(ui_entity_sel),
		.rf_rd1(fl_rfpi),
		.rf_rd2(fl_rfpii),
		.ram_rd(fl_ram_rd),
		.pc_rd(fl_pc_rd),
		.mar_rd(fl_a_bus),
		.stk_rd(fl_stack_rd),
		.alu_rd(fl_alu),
		.data_in(ui_data_in),
		.sys_clk(sys_clk),
		.sys_rst(sys_rst),
		.sys_hrd_rst(sys_hrd_rst),
		.sys_dma_req(sys_dma_req),
		.mar_incr(ui_mar_incr),
		.we_out(cm_we),
		.d_out(fl_dma),
		.add_out(add_disp),
		.data_out(data_disp)
		);

	defparam user_interface.width = width;
	defparam user_interface.add_width = add_width;
	defparam user_interface.disp_output_width = disp_output_width;

	// Display Driver

	module display_dirver(
		.clk(clk),
		.rst(sys_rst),
		.dma_appr(sys_dma_appr),
		.sys_halt(sys_halt),
		.entity_in(ui_entity_sel),
		.add_in(add_disp),
		.data_in(data_disp),
		.clk_out(clk_out),
		.entity_out(ui_entity_out),
		.add_out(ui_add_out),
		.data_out(ui_data_out)
		);

	// Register File (RF) Instantiation

	reg_array_dual register_file(
		.clk(sys_clk),
		.rst(sys_rst),
		.we1(rf_we1),
		.we2(rf_we2),
		.add1(fl_rf_add1),
		.add2(rf_add2),
		.wr1(fl_rfpi_wr),
		.wr2(fl_alu),
		.mem_fault(rf_mem_fault),
		.rd1(fl_rfpi),
		.rd2(fl_rfpii)
		);

	defparam register_file.width = width;
	defparam register_file.depth = rf_depth;
	defparam register_file.add_width = rf_add_width;

	// Random Access Memory (RAM) Instantiation

	reg_array_single ram(
		.clk(sys_clk),
		.we(ram_we),
		.add(fl_a_bus),
		.wr(fl_ram_wr),
		.rd(fl_ram_rd)
		);

	defparam ram.width = width;
	defparam ram.depth = ram_depth;
	defparam ram.add_width = add_width;

	// Special Purpose Registers Instantiation

	// Program Counter (PC)

	smr_reg pc(
		.clk(sys_clk),
		.rst(sys_hrd_rst),
		.we(pc_we),
		.incr(pc_incr),
		.wr(fl_pc_wr),
		.rd(fl_pc_rd)
		);

	defparam pc.width = width;
	defparam pc.add_width = width;

	// Memory Address Register (MAR)

	smr_reg mar(
		.clk(sys_clk),
		.rst(sys_hrd_rst),
		.we(mar_we),
		.incr(mar_incr),
		.wr(fl_mar_wr),
		.rd(fl_a_bus)
		);

	defparam mar.width = width;
	defparam mar.add_width = add_width;

	// Stack

	stack stack(
		.clk(sys_clk),
		.rst(sys_rst),
		.pop(stack_pop),
		.push(stack_push),
		.wr(fl_rfpi),
		.mem_fault(stack_mem_fault),
		.rd(fl_stack_rd)
		);

	defparam stack.width = width;
	defparam stack.depth = stack_depth;
	defparam stack.add_width = stack_add_width;

	// ALU Instantiation

	alu alu(
		.clk(sys_clk),
		.rst(sys_rst),
		.en(alu_enable),
		.opcode(alu_opcode),
		.a_in(fl_rfpi),
		.b_in(fl_rfpii),
		.o(alu_o_flag),
		.z(alu_z_flag),
		.n(alu_n_flag),
		.cond(alu_cond_flag),
		.d_out(fl_alu)
		);

	defparam alu.width = width;

	// Multiplexer Instantiation

	// Program Counter (PC) Write Source Multiplexer

	mult_2_to_1 pc_wr_src_mux(
		.sel(pc_wr_src_sel),
		.a_in(fl_dma),
		.b_in(fl_rfpi),
		.out(fl_pc_wr)
		);

	defparam pc_wr_src_mux.width = width;

	// Memory Address Register (MAR) Write Source Multiplexer

	mult_4_to_1 mar_wr_src_mux(
		.sel(mar_wr_src_sel),
		.a_in(fl_dma),
		.b_in(fl_pc_rd),
		.c_in(fl_rfpi),
		.d_in(fl_ram_rd),
		.out(fl_mar_wr)
		);

	defparam mar_wr_src_mux.width = width;

	// Register File (RF) Port I Address Source Multiplexer

	mult_2_to_1 rf_add_src_mux(
		.sel(rf_add_src_sel),
		.a_in(fl_a_bus[rf_add_width-1:0]),
		.b_in(rf_add1),
		.out(fl_rf_add1)
		);

	defparam rf_add_src_mux.width = rf_add_width;

	// Register File (RF) Port I Write Source Multiplexer

	mult_4_to_1 rf_wr_src_mux(
		.sel(rf_wr_src_sel),
		.a_in(fl_dma),
		.b_in(fl_rfpii),
		.c_in(fl_stack_rd),
		.d_in(fl_ram_rd),
		.out(fl_rfpi_wr)
		);

	defparam rf_wr_src_mux.width = width;

	// Random Access Memory (RAM) Write Source Multiplexer

	mult_2_to_1 ram_wr_src_mux(
		.sel(ram_wr_src_sel),
		.a_in(fl_dma),
		.b_in(fl_rfpi),
		.out(fl_ram_wr)
		);

	defparam ram_wr_src_mux.width = width;

endmodule