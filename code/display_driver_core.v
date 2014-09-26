//*******************************************************************************************************************************************************/
//  Module Name: display_driver
//  Module Type: Serial Display Driver
//  Author: Shreyas Vinod
//  Purpose: Synchronous Serial Display Driver Controller for Neptune I v3.0
//  Description: A synchronous 16-bit serial display driver module capable of driving thirteen Common Anode (CA) 7-segment segment displays on Neptune I
//               v3. The state of each of the eight inputs (including dot/decimal point) on all 7-segment displays can be explicitly mentioned, making it
//               extremely versatile.
//*******************************************************************************************************************************************************/

module display_dirver(clk, rst, dma_appr, sys_halt, entity_in, add_in, data_in, clk_out, strobe, entity_out, add_out, data_out);

	// Inputs

	input wire clk /* Clock (Full Speed) */; // Management Interfaces
	input wire rst /* System Reset */, dma_appr /* Direct Memory Access (DMA) Approval */, sys_halt /* System Halt */; // Notification Interfaces
	input wire [2:0] entity_in /* Entity Select */;
	input wire [19:0] add_in /* Address Input */;
	input wire [20:0] data_in /* Data Input */;

	// Outputs

	output reg clk_out /* Clock Output for driver peripherals */, strobe /* Instructs the shift register to strobe the parallel output to update all displays. */;
	output reg [2:0] entity_out /* Entity Select Output */;
	output reg [4:0] add_out /* Address Output */, data_out /* Data output */;

	// Internals

	reg dclk /* Display Clock */;
	reg nxt /* Instructs the Data Decode mechanism to fetch new data. */;
	reg [1:0] stclk /* State Clock */;
	reg [2:0] entity_in_buf /* Entity Input Buffer */;
	reg [3:0] loc /* Keeps track of the bit being currently serially transferred. */;
	reg [6:0] counter /* Display Driver Clock Driver Counter */;
	reg [19:0] add_in_buf /* Address Input Buffer */;
	reg [20:0] data_in_buf /* Data Input Buffer */;
	reg [23:0] entity_disp_buf /* Entity Display Buffer */;
	reg [39:0] add_disp_buf /* Address Display Buffer */, data_disp_buf /* Data Display Buffer */;

	// Initialization

	initial begin
		dclk <= 1'b0;
		clk_out <= 1'b0;
		strobe <= 1'b0;
		nxt <= 1'b0;
		stclk [1:0] <= 2'b0;
		loc [3:0] <= 4'b0;
		counter [6:0] <= 7'b0;
		entity_disp_buf [23:0] <= 24'b0;
		add_disp_buf [39:0] <= 40'b0;
		data_disp_buf [39:0] <= 40'b0;
	end

	// Display Clock Driver Block

	always@(posedge clk) begin
		if(counter [6:0] < 100) counter [6:0] <= counter [6:0] + 1'b1;
		else begin
			dclk <= !dclk;
			counter [6:0] <= 7'b0; 
		end
	end

	// Buffer Logic

	always@(posedge clk) begin
		entity_in_buf [2:0] <= entity_in [2:0];
		add_in_buf [19:0] <= add_in [19:0];
		data_in_buf [20:0] <= data_in [20:0];
	end

	// Read Interfacing

	always@(posedge clk) begin
		if((rst && !dma_appr) || (dma_appr && !rst)) begin

			// LED Reset State 

			if(nxt) begin
				entity_disp_buf [23:0] <= 24'b111111111111111111111111;
				{data_disp_buf, add_disp_buf} <= 80'b10010011100111111111111101100111010011111111111111111111111111111111111111111111;
			end
		end else if(sys_halt && nxt) begin
			entity_disp_buf [23:0] <= 24'b111111111111111111111111;
			{data_disp_buf, add_disp_buf} <= 80'b10010001000100011110001111100001111111111111111111111111111111111111111111111111; // System Halt Notification
		end else if(nxt) begin

			// Entity Output

			case(entity_in_buf) // synthesis parallel_case
				3'b000: entity_disp_buf [23:0] <= 24'b111111111111111111111111;
				3'b001: entity_disp_buf [23:0] <= 24'b111101010111000110011111;
				3'b010: entity_disp_buf [23:0] <= 24'b111101010111000100100101;
				3'b011: entity_disp_buf [23:0] <= 24'b011000110001000101100011;
				3'b100: entity_disp_buf [23:0] <= 24'b111111110011000101100011;
				3'b101: entity_disp_buf [23:0] <= 24'b000100011000010110000101;
				3'b110: entity_disp_buf [23:0] <= 24'b010010011110000100010001;
				3'b111: entity_disp_buf [23:0] <= 24'b000100011110001110000011;
				default: entity_disp_buf [23:0] <= 24'b0;
			endcase

			// Address Output

			add_disp_buf [39:25] <= 8'b11111111;

			case(add_in_buf [15:12]) // synthesis parallel_case
				4'b0000: add_disp_buf [31:24] <= 8'b00000011;
				4'b0001: add_disp_buf [31:24] <= 8'b10011111;
				4'b0010: add_disp_buf [31:24] <= 8'b00100101;
				4'b0011: add_disp_buf [31:24] <= 8'b00001101;
				4'b0100: add_disp_buf [31:24] <= 8'b10011001;
				4'b0101: add_disp_buf [31:24] <= 8'b01001001;
				4'b0110: add_disp_buf [31:24] <= 8'b01000001;
				4'b0111: add_disp_buf [31:24] <= 8'b00011111;
				4'b1000: add_disp_buf [31:24] <= 8'b00000001;
				4'b1001: add_disp_buf [31:24] <= 8'b00011001;
				4'b1010: add_disp_buf [31:24] <= 8'b00010001;
				4'b1011: add_disp_buf [31:24] <= 8'b11000001;
				4'b1100: add_disp_buf [31:24] <= 8'b01100011;
				4'b1101: add_disp_buf [31:24] <= 8'b10000101;
				4'b1110: add_disp_buf [31:24] <= 8'b01100001;
				4'b1111: add_disp_buf [31:24] <= 8'b01110001;
				default: add_disp_buf [31:24] <= 8'b0;
			endcase

			case(add_in_buf [11:8]) // synthesis parallel_case
				4'b0000: add_disp_buf [23:16] <= 8'b00000011;
				4'b0001: add_disp_buf [23:16] <= 8'b10011111;
				4'b0010: add_disp_buf [23:16] <= 8'b00100101;
				4'b0011: add_disp_buf [23:16] <= 8'b00001101;
				4'b0100: add_disp_buf [23:16] <= 8'b10011001;
				4'b0101: add_disp_buf [23:16] <= 8'b01001001;
				4'b0110: add_disp_buf [23:16] <= 8'b01000001;
				4'b0111: add_disp_buf [23:16] <= 8'b00011111;
				4'b1000: add_disp_buf [23:16] <= 8'b00000001;
				4'b1001: add_disp_buf [23:16] <= 8'b00011001;
				4'b1010: add_disp_buf [23:16] <= 8'b00010001;
				4'b1011: add_disp_buf [23:16] <= 8'b11000001;
				4'b1100: add_disp_buf [23:16] <= 8'b01100011;
				4'b1101: add_disp_buf [23:16] <= 8'b10000101;
				4'b1110: add_disp_buf [23:16] <= 8'b01100001;
				4'b1111: add_disp_buf [23:16] <= 8'b01110001;
				default: add_disp_buf [23:16] <= 8'b0;
			endcase

			case(add_in_buf [7:4]) // synthesis parallel_case
				4'b0000: add_disp_buf [15:8] <= 8'b00000011;
				4'b0001: add_disp_buf [15:8] <= 8'b10011111;
				4'b0010: add_disp_buf [15:8] <= 8'b00100101;
				4'b0011: add_disp_buf [15:8] <= 8'b00001101;
				4'b0100: add_disp_buf [15:8] <= 8'b10011001;
				4'b0101: add_disp_buf [15:8] <= 8'b01001001;
				4'b0110: add_disp_buf [15:8] <= 8'b01000001;
				4'b0111: add_disp_buf [15:8] <= 8'b00011111;
				4'b1000: add_disp_buf [15:8] <= 8'b00000001;
				4'b1001: add_disp_buf [15:8] <= 8'b00011001;
				4'b1010: add_disp_buf [15:8] <= 8'b00010001;
				4'b1011: add_disp_buf [15:8] <= 8'b11000001;
				4'b1100: add_disp_buf [15:8] <= 8'b01100011;
				4'b1101: add_disp_buf [15:8] <= 8'b10000101;
				4'b1110: add_disp_buf [15:8] <= 8'b01100001;
				4'b1111: add_disp_buf [15:8] <= 8'b01110001;
				default: add_disp_buf [15:8] <= 8'b0;
			endcase

			case(add_in_buf [3:0]) // synthesis parallel_case
				4'b0000: add_disp_buf [7:0] <= 8'b00000011;
				4'b0001: add_disp_buf [7:0] <= 8'b10011111;
				4'b0010: add_disp_buf [7:0] <= 8'b00100101;
				4'b0011: add_disp_buf [7:0] <= 8'b00001101;
				4'b0100: add_disp_buf [7:0] <= 8'b10011001;
				4'b0101: add_disp_buf [7:0] <= 8'b01001001;
				4'b0110: add_disp_buf [7:0] <= 8'b01000001;
				4'b0111: add_disp_buf [7:0] <= 8'b00011111;
				4'b1000: add_disp_buf [7:0] <= 8'b00000001;
				4'b1001: add_disp_buf [7:0] <= 8'b00011001;
				4'b1010: add_disp_buf [7:0] <= 8'b00010001;
				4'b1011: add_disp_buf [7:0] <= 8'b11000001;
				4'b1100: add_disp_buf [7:0] <= 8'b01100011;
				4'b1101: add_disp_buf [7:0] <= 8'b10000101;
				4'b1110: add_disp_buf [7:0] <= 8'b01100001;
				4'b1111: add_disp_buf [7:0] <= 8'b01110001;
				default: add_disp_buf [7:0] <= 8'b0;
			endcase

			// Data Output

			if(data_in_buf[20] == 1'b1) data_disp_buf [39:32] <= 8'b11111101; // Negative
			else data_disp_buf [39:32] <= 8'b11111111; // Positive

			case(data_in_buf [15:12]) // synthesis parallel_case
				4'b0000: data_disp_buf [31:24] <= 8'b00000011;
				4'b0001: data_disp_buf [31:24] <= 8'b10011111;
				4'b0010: data_disp_buf [31:24] <= 8'b00100101;
				4'b0011: data_disp_buf [31:24] <= 8'b00001101;
				4'b0100: data_disp_buf [31:24] <= 8'b10011001;
				4'b0101: data_disp_buf [31:24] <= 8'b01001001;
				4'b0110: data_disp_buf [31:24] <= 8'b01000001;
				4'b0111: data_disp_buf [31:24] <= 8'b00011111;
				4'b1000: data_disp_buf [31:24] <= 8'b00000001;
				4'b1001: data_disp_buf [31:24] <= 8'b00011001;
				4'b1010: data_disp_buf [31:24] <= 8'b00010001;
				4'b1011: data_disp_buf [31:24] <= 8'b11000001;
				4'b1100: data_disp_buf [31:24] <= 8'b01100011;
				4'b1101: data_disp_buf [31:24] <= 8'b10000101;
				4'b1110: data_disp_buf [31:24] <= 8'b01100001;
				4'b1111: data_disp_buf [31:24] <= 8'b01110001;
				default: data_disp_buf [31:24] <= 8'b0;
			endcase

			case(data_in_buf [11:8]) // synthesis parallel_case
				4'b0000: data_disp_buf [23:16] <= 8'b00000011;
				4'b0001: data_disp_buf [23:16] <= 8'b10011111;
				4'b0010: data_disp_buf [23:16] <= 8'b00100101;
				4'b0011: data_disp_buf [23:16] <= 8'b00001101;
				4'b0100: data_disp_buf [23:16] <= 8'b10011001;
				4'b0101: data_disp_buf [23:16] <= 8'b01001001;
				4'b0110: data_disp_buf [23:16] <= 8'b01000001;
				4'b0111: data_disp_buf [23:16] <= 8'b00011111;
				4'b1000: data_disp_buf [23:16] <= 8'b00000001;
				4'b1001: data_disp_buf [23:16] <= 8'b00011001;
				4'b1010: data_disp_buf [23:16] <= 8'b00010001;
				4'b1011: data_disp_buf [23:16] <= 8'b11000001;
				4'b1100: data_disp_buf [23:16] <= 8'b01100011;
				4'b1101: data_disp_buf [23:16] <= 8'b10000101;
				4'b1110: data_disp_buf [23:16] <= 8'b01100001;
				4'b1111: data_disp_buf [23:16] <= 8'b01110001;
				default: data_disp_buf [23:16] <= 8'b0;
			endcase

			case(data_in_buf [7:4]) // synthesis parallel_case
				4'b0000: data_disp_buf [15:8] <= 8'b00000011;
				4'b0001: data_disp_buf [15:8] <= 8'b10011111;
				4'b0010: data_disp_buf [15:8] <= 8'b00100101;
				4'b0011: data_disp_buf [15:8] <= 8'b00001101;
				4'b0100: data_disp_buf [15:8] <= 8'b10011001;
				4'b0101: data_disp_buf [15:8] <= 8'b01001001;
				4'b0110: data_disp_buf [15:8] <= 8'b01000001;
				4'b0111: data_disp_buf [15:8] <= 8'b00011111;
				4'b1000: data_disp_buf [15:8] <= 8'b00000001;
				4'b1001: data_disp_buf [15:8] <= 8'b00011001;
				4'b1010: data_disp_buf [15:8] <= 8'b00010001;
				4'b1011: data_disp_buf [15:8] <= 8'b11000001;
				4'b1100: data_disp_buf [15:8] <= 8'b01100011;
				4'b1101: data_disp_buf [15:8] <= 8'b10000101;
				4'b1110: data_disp_buf [15:8] <= 8'b01100001;
				4'b1111: data_disp_buf [15:8] <= 8'b01110001;
				default: data_disp_buf [15:8] <= 8'b0;
			endcase

			case(data_in_buf [3:0]) // synthesis parallel_case
				4'b0000: data_disp_buf [7:0] <= 8'b00000011;
				4'b0001: data_disp_buf [7:0] <= 8'b10011111;
				4'b0010: data_disp_buf [7:0] <= 8'b00100101;
				4'b0011: data_disp_buf [7:0] <= 8'b00001101;
				4'b0100: data_disp_buf [7:0] <= 8'b10011001;
				4'b0101: data_disp_buf [7:0] <= 8'b01001001;
				4'b0110: data_disp_buf [7:0] <= 8'b01000001;
				4'b0111: data_disp_buf [7:0] <= 8'b00011111;
				4'b1000: data_disp_buf [7:0] <= 8'b00000001;
				4'b1001: data_disp_buf [7:0] <= 8'b00011001;
				4'b1010: data_disp_buf [7:0] <= 8'b00010001;
				4'b1011: data_disp_buf [7:0] <= 8'b11000001;
				4'b1100: data_disp_buf [7:0] <= 8'b01100011;
				4'b1101: data_disp_buf [7:0] <= 8'b10000101;
				4'b1110: data_disp_buf [7:0] <= 8'b01100001;
				4'b1111: data_disp_buf [7:0] <= 8'b01110001;
				default: data_disp_buf [7:0] <= 8'b0;
			endcase
		end
	end

	// Serial Communications Block

	always@(posedge dclk) begin
		case(stclk) // synthesis parallel_case
			2'b00: begin
				nxt <= 1'b0;
				strobe <= 1'b0;
				stclk [1:0] <= 2'b01;
				loc [3:0] <= 4'b0;
			end
			2'b01: begin

				// Entity Out

				entity_out[2] <= entity_disp_buf[loc+5'd16];
				entity_out[1] <= entity_disp_buf[loc+4'd8];
				entity_out[0] <= entity_disp_buf[loc];

				// Address Out

				add_out[4] <= add_disp_buf[loc+5'd32];
				add_out[3] <= add_disp_buf[loc+5'd24];
				add_out[2] <= add_disp_buf[loc+5'd16];
				add_out[1] <= add_disp_buf[loc+4'd8];
				add_out[0] <= add_disp_buf[loc];

				// Data Out

				data_out[4] <= data_disp_buf[loc+5'd32];
				data_out[3] <= data_disp_buf[loc+5'd24];
				data_out[2] <= data_disp_buf[loc+5'd16];
				data_out[1] <= data_disp_buf[loc+4'd8];
				data_out[0] <= data_disp_buf[loc];

				loc [3:0] <= loc [3:0] + 1'b1;
				stclk [1:0] <= 2'b10;
			end
			2'b10: begin
				clk_out <= 1'b1;
				stclk [1:0] <= 2'b11;
			end
			2'b11: begin
				clk_out <= 1'b0;
				if(loc [3:0] == 4'b1000) begin
					nxt <= 1'b1;
					strobe <= 1'b1;
					stclk [1:0] <= 2'b0;
				end else stclk [1:0] <= 2'b01;
			end
		endcase
	end

endmodule