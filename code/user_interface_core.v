//*******************************************************************************************************************************************************/
//  Module Name: user_interface
//  Module Type: User Interface and External Communications Module
//  Author: Shreyas Vinod
//  Purpose: User Interface and External Communications Module for Neptune I v3.0
//  Description: A simplistic User Interface and Front Panel Communications and Translation Module that takes a small number of inputs from Neptune I's
//               Front Panel and converts it into a multitude of signals to communicate in perfect harmony with Neptune I's Control Matrix. It's able
//               to request for IO and Bus Access as well. It is also capable of driving two sets of five 7-segment displays with binary outputs that
//               can later be externally decoded into BCD or hexadecimal.
//*******************************************************************************************************************************************************/

module user_interface(clk, rst, dma_req, dma_appr, wr, add_wr, incr_add, clk_sel, entity_sel, pc_rd, mar_rd, rf_rd1, rf_rd2, ram_rd, stk_rd, alu_rd, data_in, sys_clk, sys_rst, sys_hrd_rst, sys_dma_req, mar_incr, we_out, d_out, add_out, data_out);

	// Parameter Definitions

	parameter width = 'd16; // Data Width
	parameter add_width = 'd13; // Address Width
	parameter disp_output_width = 'd20; // Display Driver Data Width

	// Inputs

	input wire clk /* External Clock */, rst /* External Reset Request */, dma_req /* External Direct Memory Access (DMA) Request */; // Management Interfaces
	input wire dma_appr /* External Direct Memory Access (DMA) Request Approval Notification */; // Notification Interfaces
	input wire wr /* External Write Request */, add_wr /* External Address Write Request */;
	input wire incr_add /* Increment Address Request */, clk_sel /* Clock Select Toggle */;
	input wire [2:0] entity_sel /* Read/Write Processor Entity Select */;
	input wire [add_width-1:0] mar_rd /* Memory Address Register (MAR) Read */;
	input wire [width-1:0] pc_rd /* Program Counter (PC) Read */, rf_rd1 /* Register File Port (RF) I Read */, rf_rd2 /* Register File (RF) Port II Read */, ram_rd /* Random Access Memory (RAM) Read */;
	input wire [width-1:0] stk_rd /* Stack Read */, alu_rd /* ALU Result Read */;
	input wire [width-1:0] data_in /* External Data Input Port */;

	// Outputs

	output wire sys_clk /* System Clock Output */, sys_rst /* System Reset Output */, sys_hrd_rst /* System Hard Reset Output */, sys_dma_req /* Request Direct Memory Access (DMA) from System */;
	output wire mar_incr /* Increment MAR Request */;
	output wire [2:0] we_out /* Control Matrix Write Enable Request */;
	output wire [width-1:0] d_out /* Data Output for Direct Memory Access (DMA) Write Requests */;
	output wire [disp_output_width-1:0] add_out /* External Address Output Port */;
	output wire [disp_output_width:0] data_out /* External Data Output Port */;

	// Internals

	reg sclk /* Slow Clock Driver */, rst_buf /* External Reset Request Buffer */, dma_req_buf /* External Direct Memory Access (DMA) Request Buffer */, wr_buf /* External Write Request Buffer */;
	reg add_wr_buf /* External Address Write Request Buffer */, incr_add_buf /* Increment Address Request Buffer */, incr_c /* Incrementation Complete Notification */;
	reg [2:0] entity_sel_buf /* Read/Write Processor Entity Select Buffer */, entity_sel_buf_t /* True Entity Select Buffer */;
	reg [3:0] stclk /* Reset LED State Clock */;
	reg [width-1:0] data_in_buf /* Data Input Buffer */, data_conv_buf /* Hex Conversion Data Buffer */;
	reg [disp_output_width:0] a_bus_disp; // Binary to Hex (Extended Binary, decoded by Display Driver) converted Address Output signal. Extra bit ignored.
	reg [disp_output_width:0] d_bus_disp; // Binary to Hex (Extended Binary, decoded by Display Driver) converted Data Output signals. One extra bit for sign notation.
	reg [23:0] counter /* Slow Clock Driver Counter */;

	// Initialization

	initial begin
		sclk <= 1'b0;
		stclk [3;0] <= 4'b0;
		counter [23:0] <= 24'b0;
	end

	// Slow Clock Driver Block

	always@(posedge clk) begin
		if(counter [23:0] < 5000000) counter [23:0] <= counter [23:0] + 1'b1;
		else begin
			sclk <= !sclk;
			counter [23:0] <= 24'b0;
		end
	end

	// Write Request

	assign we_out [2:0] = (wr_buf && dma_appr)?entity_sel_buf [2:0]:3'b0; 

	// Output Logic

	assign sys_clk = (clk_sel)?sclk:clk; // System Clock Select
	assign sys_rst = (rst_buf)?1'b1:1'b0; // Reset Enable
	assign sys_hrd_rst = (rst_buf && wr_buf && add_wr_buf && incr_add_buf && (entity_sel_buf == 3'b0))?1'b1:1'b0; // Hard Reset Enable Logic
	assign sys_dma_req = dma_req_buf; // Request Direct Memory Access (DMA) from Control Matrix
	assign mar_incr = incr_add_buf; // Increment MAR contents.
	assign d_out [width-1:0] = data_in_buf [width-1:0]; // Assigns the Direct Memory Access (DMA) Write Request Data Line based on input.
	assign add_out [disp_output_width-1:0] = a_bus_disp [disp_output_width-1:0]; // Assigns the Address Output Port the value of the Address Output buffer.
	assign data_out [disp_output_width:0] = d_bus_disp [disp_output_width:0]; // Assigns the Data Output Port the value of the Data Output buffer.

	// Buffer Logic

	always@(posedge sclk) begin
		rst_buf <= rst; // External Reset Request Buffer
		dma_req_buf <= dma_req; // External Direct Memory Access (DMA) Request Buffer
		wr_buf <= wr; // External Write Request Buffer
		add_wr_buf <= add_wr; // External Address Write Request Buffer
		data_in_buf <= data_in; // External Data Input Buffer

		// Entity Select

		entity_sel_buf_t [2:0] <= entity_sel [2:0]; // True Entity Select Buffer based on input.

		if(add_wr_buf) entity_sel_buf [2:0] <= 3'b101; // Select MAR to write address.
		else entity_sel_buf [2:0] <= entity_sel [2:0]; // Select Entity based on input.
	end

	// Data Conversion Buffer

	always@(entity_sel_buf_t, rf_rd1, rf_rd2, ram_rd, pc_rd, mar_rd, stk_rd, alu_rd) begin
		case(entity_sel_buf_t) // synthesis parallel_case
			3'b000: data_conv_buf [width-1:0] = {width{1'b0}};
			3'b001: data_conv_buf [width-1:0] = rf_rd1 [width-1:0];
			3'b010: data_conv_buf [width-1:0] = rf_rd2 [width-1:0];
			3'b011: data_conv_buf [width-1:0] = ram_rd [width-1:0];
			3'b100: data_conv_buf [width-1:0] = pc_rd [width-1:0];
			3'b101: data_conv_buf [width-1:0] = {{width-add_width{1'b0}}, mar_rd [add_width-1:0]};
			3'b110: data_conv_buf [width-1:0] = stk_rd [width-1:0];
			3'b111: data_conv_buf [width-1:0] = alu_rd [width-1:0];
			default: data_conv_buf [width-1:0] = {width{1'b0}};
		endcase
	end

	// Incrementation Logic and signal buffer

	// This block ensures that incrementation takes place only once for every increment request by using the 'Incrementation Complete (incr_c)' notification.

	always@(posedge sclk) begin
		if(!incr_add_buf && incr_add && !incr_c) incr_add_buf <= 1'b1;
		else if(incr_add_buf && incr_add) begin
			incr_add_buf <= 1'b0;
			incr_c <= 1'b1;
		end else if(!incr_add) begin
			incr_add_buf <= 1'b0;
			incr_c <= 1'b0;
		end
	end

	// Binary to Hex (Extended Binary, decoded by Display Driver) Conversion Block

	// Address Bus

	always@(mar_rd) begin
		a_bus_disp [disp_output_width:0] = {7'b0, mar_rd [add_width-1:0]};
	end

	// Data Bus

	always@(data_conv_buf) begin
		d_bus_disp [disp_output_width:0] = {data_conv_buf[width-1], 4'b0, data_conv_buf [width-2:0]};
	end

endmodule

