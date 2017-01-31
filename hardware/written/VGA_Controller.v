
module VGA_Controller(
	input clk,
	input resetn,
	
	//avalon slave
	input [1:0]slave_address,
	input slave_read_en,
	input slave_write_en,
	output [31:0]slave_read_data,
	input [31:0]slave_write_data,
	
	//avalon master for accessing SDRAM
	output [31:0]master_address, 
	output master_read, 
	input [31:0]master_read_data, 
	input master_wait_request,
	input master_read_data_valid,
	
	output VGA_SYNC_N,
	output VGA_BLANK_N,
	output [7:0]VGA_R,
	output [7:0]VGA_G,
	output [7:0]VGA_B,
	output VGA_HS,
	output VGA_VS,
	input VGA_CLK
);

	//VGA state registers
	reg [31:0]fbAddr;
	reg [31:0]framesDone;
	
	//read requests
	reg [31:0]READ_REG;
	assign slave_read_data = READ_REG;
	always @ (*) begin
		if(slave_read_en) begin
			case(slave_address)
				2'd0: READ_REG = framesDone;
				2'd1: READ_REG = fbAddr;
				default: READ_REG = 32'd0;
			endcase
		end else begin
			READ_REG = 32'd0;
		end
	end
	
	//writing
	always @ (posedge clk or negedge resetn) begin
		if (!resetn) begin
			fbAddr <= 32'd0;
		end else begin
			if(slave_write_en) begin
				case(slave_address)
					2'd1: fbAddr <= slave_write_data;
				endcase
			end
		end
	end

	
	always @ (posedge clk or negedge resetn) begin
		if (!resetn) begin
			framesDone <= 32'd0;
		end else begin
			//clear the frame status when read
			if(slave_read_en && slave_address == 2'd0) begin
				framesDone <= frame_finished;
			end else begin
				framesDone <= framesDone + frame_finished;
			end
		end
	end
	
	
	
	wire frame_finished;
	VGA_driver VGA0(
		//sys_clk
		clk, 
		resetn, 
		fbAddr,
		frame_finished,
		
		master_address, 
		master_read, 
		master_read_data, 
		master_wait_request,
		master_read_data_valid,
		
		//vga_clk
		VGA_SYNC_N, 
		VGA_BLANK_N, 
		VGA_R, 
		VGA_G, 
		VGA_B, 
		VGA_HS, 
		VGA_VS, 
		VGA_CLK
	);

endmodule