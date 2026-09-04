//
// ddram.v
// Copyright (c) 2019 Sorgelig
//
//
// This source file is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This source file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
// ------------------------------------------
//

module ddram
(
	input wire DDRAM_CLK,
	input wire DDRAM_BUSY,
	output wire [7:0] DDRAM_BURSTCNT,
	output wire [28:0] DDRAM_ADDR,
	input wire [63:0] DDRAM_DOUT,
	input wire DDRAM_DOUT_READY,
	output wire DDRAM_RD,
	output wire [63:0] DDRAM_DIN,
	output wire [7:0] DDRAM_BE,
	output wire DDRAM_WE,

	input wire [27:1] ch1_addr,
	output wire [63:0] ch1_dout,
	input wire [63:0] ch1_din,
	input wire ch1_req,
	input wire ch1_rnw,
	input wire [7:0] ch1_be,
	output wire ch1_ready
);

	localparam STATE_IDLE = 1'b0;
	localparam STATE_WAIT_READ = 1'b1;

	reg [63:0] read_data_q;
	reg [63:0] write_data_q;
	reg [24:0] address_q;
	reg read_q = 1'b0;
	reg write_q = 1'b0;
	reg [7:0] byte_enable_q;
	reg ready_q;
	reg state_q = STATE_IDLE;
	reg request_pending_q;

	// The bridge issues one 64-bit beat per request, so address bits 2:1 only
	// select bytes within that beat and are intentionally discarded.
	assign DDRAM_BURSTCNT = 8'd1;
	assign DDRAM_ADDR = {4'b0011, address_q}; // DDR3 window at 0x30000000.
	assign DDRAM_RD = read_q;
	assign DDRAM_DIN = write_data_q;
	assign DDRAM_BE = read_q ? 8'hFF : byte_enable_q;
	assign DDRAM_WE = write_q;

	assign ch1_dout = read_data_q;
	assign ch1_ready = ready_q;

	always @(posedge DDRAM_CLK) begin
		request_pending_q <= request_pending_q || ch1_req;
		ready_q <= 1'b0;

		if (!DDRAM_BUSY) begin
			write_q <= 1'b0;
			read_q <= 1'b0;

			case (state_q)
				STATE_IDLE: begin
					if (request_pending_q || ch1_req) begin
						request_pending_q <= 1'b0;
						write_data_q <= ch1_din;
						byte_enable_q <= ch1_be;
						address_q <= ch1_addr[27:3];
						if (ch1_rnw) begin
							read_q <= 1'b1;
							state_q <= STATE_WAIT_READ;
						end else begin
							write_q <= 1'b1;
							ready_q <= 1'b1;
						end
					end
				end

				STATE_WAIT_READ: begin
					if (DDRAM_DOUT_READY) begin
						read_data_q <= DDRAM_DOUT;
						ready_q <= 1'b1;
						state_q <= STATE_IDLE;
					end
				end
			endcase
		end
	end

endmodule
