// Copyright (c) 2026 Jamie Blanks

module gamecom_cart_cfg
(
	input wire clk_sys_i,
	input wire ce_i,
	input wire clear_i,
	input wire download_i,
	input wire wr_i,
	input wire [26:0] addr_i,
	input wire [7:0] data_i,

	output wire header_valid_o,
	output wire checksum_valid_o,
	output wire security_valid_o,
	output wire cart_valid_o,
	output wire data_only_o,
	output wire [7:0] flags_o,
	output wire [7:0] entry_bank_o,
	output wire [15:0] entry_addr_o,
	output wire [7:0] icon_bank_o,
	output wire [15:0] icon_loc_o,
	output wire [71:0] program_name_o,
	output wire [15:0] program_id_o,
	output wire [7:0] security_checksum_o,
	output wire header_hi_o
);

	reg [7:0] entry_bank0_q;
	reg [15:0] entry_addr0_q;
	reg [7:0] flags0_q;
	reg [8:0] string0_match_q;
	reg [7:0] icon_bank0_q;
	reg [15:0] icon_loc0_q;
	reg [71:0] program_name0_q;
	reg [15:0] program_id0_q;
	reg [7:0] security_checksum0_q;

	reg [7:0] entry_bank4_q;
	reg [15:0] entry_addr4_q;
	reg [7:0] flags4_q;
	reg [8:0] string4_match_q;
	reg [7:0] icon_bank4_q;
	reg [15:0] icon_loc4_q;
	reg [71:0] program_name4_q;
	reg [15:0] program_id4_q;
	reg [7:0] security_checksum4_q;

	reg [7:0] security_byte0_q [0:15];
	reg [7:0] security_byte1_q [0:15];
	reg [7:0] security_byte2_q [0:15];
	reg [2:0] security_seen_q [0:15];

	integer index_v;

	wire header0_valid_w = &string0_match_q;
	wire header4_valid_w = &string4_match_q;
	wire use_header4_w = !header0_valid_w && header4_valid_w;
	wire header_valid_w = header0_valid_w || header4_valid_w;

	wire [7:0] entry_bank_w = use_header4_w ? entry_bank4_q : entry_bank0_q;
	wire [15:0] entry_addr_w = use_header4_w ? entry_addr4_q : entry_addr0_q;
	wire [7:0] flags_w = use_header4_w ? flags4_q : flags0_q;
	wire [7:0] icon_bank_w = use_header4_w ? icon_bank4_q : icon_bank0_q;
	wire [15:0] icon_loc_w = use_header4_w ? icon_loc4_q : icon_loc0_q;
	wire [71:0] program_name_w = use_header4_w ? program_name4_q : program_name0_q;
	wire [15:0] program_id_w = use_header4_w ? program_id4_q : program_id0_q;
	wire [7:0] security_checksum_w = use_header4_w ? security_checksum4_q : security_checksum0_q;
	wire [7:0] checksum_expected_w = (program_id_w[15:8] + program_id_w[7:0]) ^ 8'hA5;
	wire checksum_valid_w = header_valid_w && (checksum_expected_w == security_checksum_w);

	reg [2:0] security_seen_r;
	reg [7:0] security_sum_r;
	wire [3:0] security_index_w = security_checksum_w[3:0];
	wire security_triplet_valid_w = &security_seen_r;
	wire security_valid_w = checksum_valid_w &&
		security_triplet_valid_w && (security_sum_r == 8'h5A);

	assign header_valid_o = header_valid_w;
	assign checksum_valid_o = checksum_valid_w;
	assign security_valid_o = security_valid_w;
	assign cart_valid_o = security_valid_w;
	assign data_only_o = header_valid_w && flags_w[2];
	assign flags_o = flags_w;
	assign entry_bank_o = entry_bank_w;
	assign entry_addr_o = entry_addr_w;
	assign icon_bank_o = icon_bank_w;
	assign icon_loc_o = icon_loc_w;
	assign program_name_o = program_name_w;
	assign program_id_o = program_id_w;
	assign security_checksum_o = security_checksum_w;
	assign header_hi_o = use_header4_w;

	always @(*) begin
		security_seen_r = security_seen_q[security_index_w];
		security_sum_r = security_byte0_q[security_index_w] +
			security_byte1_q[security_index_w] +
			security_byte2_q[security_index_w];
	end

	task apply_header_byte;
		input header_hi_i;
		input [4:0] offset_i;
		input [7:0] value_i;
		begin
			case (offset_i)
				5'h01: begin
					if (header_hi_i) entry_bank4_q <= value_i;
					else entry_bank0_q <= value_i;
				end
				5'h02: begin
					if (header_hi_i) entry_addr4_q[15:8] <= value_i;
					else entry_addr0_q[15:8] <= value_i;
				end
				5'h03: begin
					if (header_hi_i) entry_addr4_q[7:0] <= value_i;
					else entry_addr0_q[7:0] <= value_i;
				end
				5'h04: begin
					if (header_hi_i) flags4_q <= value_i;
					else flags0_q <= value_i;
				end
				5'h05: begin
					if (header_hi_i) string4_match_q[0] <= (value_i == 8'h54);
					else string0_match_q[0] <= (value_i == 8'h54);
				end
				5'h06: begin
					if (header_hi_i) string4_match_q[1] <= (value_i == 8'h69);
					else string0_match_q[1] <= (value_i == 8'h69);
				end
				5'h07: begin
					if (header_hi_i) string4_match_q[2] <= (value_i == 8'h67);
					else string0_match_q[2] <= (value_i == 8'h67);
				end
				5'h08: begin
					if (header_hi_i) string4_match_q[3] <= (value_i == 8'h65);
					else string0_match_q[3] <= (value_i == 8'h65);
				end
				5'h09: begin
					if (header_hi_i) string4_match_q[4] <= (value_i == 8'h72);
					else string0_match_q[4] <= (value_i == 8'h72);
				end
				5'h0A: begin
					if (header_hi_i) string4_match_q[5] <= (value_i == 8'h44);
					else string0_match_q[5] <= (value_i == 8'h44);
				end
				5'h0B: begin
					if (header_hi_i) string4_match_q[6] <= (value_i == 8'h4D);
					else string0_match_q[6] <= (value_i == 8'h4D);
				end
				5'h0C: begin
					if (header_hi_i) string4_match_q[7] <= (value_i == 8'h47);
					else string0_match_q[7] <= (value_i == 8'h47);
				end
				5'h0D: begin
					if (header_hi_i) string4_match_q[8] <= (value_i == 8'h43);
					else string0_match_q[8] <= (value_i == 8'h43);
				end
				5'h0E: begin
					if (header_hi_i) icon_bank4_q <= value_i;
					else icon_bank0_q <= value_i;
				end
				5'h0F: begin
					if (header_hi_i) icon_loc4_q[15:8] <= value_i;
					else icon_loc0_q[15:8] <= value_i;
				end
				5'h10: begin
					if (header_hi_i) icon_loc4_q[7:0] <= value_i;
					else icon_loc0_q[7:0] <= value_i;
				end
				5'h11: begin
					if (header_hi_i) program_name4_q[71:64] <= value_i;
					else program_name0_q[71:64] <= value_i;
				end
				5'h12: begin
					if (header_hi_i) program_name4_q[63:56] <= value_i;
					else program_name0_q[63:56] <= value_i;
				end
				5'h13: begin
					if (header_hi_i) program_name4_q[55:48] <= value_i;
					else program_name0_q[55:48] <= value_i;
				end
				5'h14: begin
					if (header_hi_i) program_name4_q[47:40] <= value_i;
					else program_name0_q[47:40] <= value_i;
				end
				5'h15: begin
					if (header_hi_i) program_name4_q[39:32] <= value_i;
					else program_name0_q[39:32] <= value_i;
				end
				5'h16: begin
					if (header_hi_i) program_name4_q[31:24] <= value_i;
					else program_name0_q[31:24] <= value_i;
				end
				5'h17: begin
					if (header_hi_i) program_name4_q[23:16] <= value_i;
					else program_name0_q[23:16] <= value_i;
				end
				5'h18: begin
					if (header_hi_i) program_name4_q[15:8] <= value_i;
					else program_name0_q[15:8] <= value_i;
				end
				5'h19: begin
					if (header_hi_i) program_name4_q[7:0] <= value_i;
					else program_name0_q[7:0] <= value_i;
				end
				5'h1A: begin
					if (header_hi_i) program_id4_q[15:8] <= value_i;
					else program_id0_q[15:8] <= value_i;
				end
				5'h1B: begin
					if (header_hi_i) program_id4_q[7:0] <= value_i;
					else program_id0_q[7:0] <= value_i;
				end
				5'h1C: begin
					if (header_hi_i) security_checksum4_q <= value_i;
					else security_checksum0_q <= value_i;
				end
				default: ;
			endcase
		end
	endtask

	task apply_security_byte;
		input [3:0] index_i;
		input [1:0] slot_i;
		input [7:0] value_i;
		begin
			case (slot_i)
				2'd0: begin
					security_byte0_q[index_i] <= value_i;
					security_seen_q[index_i][0] <= 1'b1;
				end
				2'd1: begin
					security_byte1_q[index_i] <= value_i;
					security_seen_q[index_i][1] <= 1'b1;
				end
				default: begin
					security_byte2_q[index_i] <= value_i;
					security_seen_q[index_i][2] <= 1'b1;
				end
			endcase
		end
	endtask

	always @(posedge clk_sys_i) begin
		if (clear_i) begin
			entry_bank0_q <= 8'h00;
			entry_addr0_q <= 16'h0000;
			flags0_q <= 8'h00;
			string0_match_q <= 9'h000;
			icon_bank0_q <= 8'h00;
			icon_loc0_q <= 16'h0000;
			program_name0_q <= 72'h000000000000000000;
			program_id0_q <= 16'h0000;
			security_checksum0_q <= 8'h00;
			entry_bank4_q <= 8'h00;
			entry_addr4_q <= 16'h0000;
			flags4_q <= 8'h00;
			string4_match_q <= 9'h000;
			icon_bank4_q <= 8'h00;
			icon_loc4_q <= 16'h0000;
			program_name4_q <= 72'h000000000000000000;
			program_id4_q <= 16'h0000;
			security_checksum4_q <= 8'h00;

			for (index_v = 0; index_v < 16; index_v = index_v + 1) begin
				security_byte0_q[index_v] <= 8'h00;
				security_byte1_q[index_v] <= 8'h00;
				security_byte2_q[index_v] <= 8'h00;
				security_seen_q[index_v] <= 3'b000;
			end
		end else if (ce_i && download_i && wr_i) begin
			if (addr_i[26:5] == 22'd0) begin
				apply_header_byte(1'b0, addr_i[4:0], data_i);
			end else if (addr_i[26:5] == 22'h02000) begin
				apply_header_byte(1'b1, addr_i[4:0], data_i);
			end

			if (addr_i[26:17] == 10'd0) begin
				case (addr_i[16:0])
					17'h033E4: apply_security_byte(4'h0, 2'd0, data_i);
					17'h05757: apply_security_byte(4'h0, 2'd1, data_i);
					17'h06666: apply_security_byte(4'h0, 2'd2, data_i);
					17'h01245: apply_security_byte(4'h1, 2'd0, data_i);
					17'h03505: apply_security_byte(4'h1, 2'd1, data_i);
					17'h04707: apply_security_byte(4'h1, 2'd2, data_i);
					17'h02267: apply_security_byte(4'h2, 2'd0, data_i);
					17'h0635A: apply_security_byte(4'h2, 2'd1, data_i);
					17'h07ABC: apply_security_byte(4'h2, 2'd2, data_i);
					17'h01AC2: apply_security_byte(4'h3, 2'd0, data_i);
					17'h036BB: apply_security_byte(4'h3, 2'd1, data_i);
					17'h084E3: apply_security_byte(4'h3, 2'd2, data_i);
					17'h04F27: apply_security_byte(4'h4, 2'd0, data_i);
					17'h056E1: apply_security_byte(4'h4, 2'd1, data_i);
					17'h07FDB: apply_security_byte(4'h4, 2'd2, data_i);
					17'h008A7: apply_security_byte(4'h5, 2'd0, data_i);
					17'h06B41: apply_security_byte(4'h5, 2'd1, data_i);
					17'h05673: apply_security_byte(4'h5, 2'd2, data_i);
					17'h00245: apply_security_byte(4'h6, 2'd0, data_i);
					17'h033BE: apply_security_byte(4'h6, 2'd1, data_i);
					17'h08B6F: apply_security_byte(4'h6, 2'd2, data_i);
					17'h01743: apply_security_byte(4'h7, 2'd0, data_i);
					17'h05F7E: apply_security_byte(4'h7, 2'd1, data_i);
					17'h06376: apply_security_byte(4'h7, 2'd2, data_i);
					17'h02875: apply_security_byte(4'h8, 2'd0, data_i);
					17'h03764: apply_security_byte(4'h8, 2'd1, data_i);
					17'h04FD0: apply_security_byte(4'h8, 2'd2, data_i);
					17'h0230F: apply_security_byte(4'h9, 2'd0, data_i);
					17'h044E7: apply_security_byte(4'h9, 2'd1, data_i);
					17'h067B1: apply_security_byte(4'h9, 2'd2, data_i);
					17'h02209: apply_security_byte(4'hA, 2'd0, data_i);
					17'h034F1: apply_security_byte(4'hA, 2'd1, data_i);
					17'h03AA8: apply_security_byte(4'hA, 2'd2, data_i);
					17'h0200D: apply_security_byte(4'hB, 2'd0, data_i);
					17'h033C9: apply_security_byte(4'hB, 2'd1, data_i);
					17'h063EC: apply_security_byte(4'hB, 2'd2, data_i);
					17'h039A7: apply_security_byte(4'hC, 2'd0, data_i);
					17'h05F4B: apply_security_byte(4'hC, 2'd1, data_i);
					17'h06078: apply_security_byte(4'hC, 2'd2, data_i);
					17'h01327: apply_security_byte(4'hD, 2'd0, data_i);
					17'h0224C: apply_security_byte(4'hD, 2'd1, data_i);
					17'h07086: apply_security_byte(4'hD, 2'd2, data_i);
					17'h02903: apply_security_byte(4'hE, 2'd0, data_i);
					17'h04F72: apply_security_byte(4'hE, 2'd1, data_i);
					17'h06600: apply_security_byte(4'hE, 2'd2, data_i);
					17'h01108: apply_security_byte(4'hF, 2'd0, data_i);
					17'h03ABB: apply_security_byte(4'hF, 2'd1, data_i);
					17'h0590A: apply_security_byte(4'hF, 2'd2, data_i);
					default: ;
				endcase
			end
		end
	end

endmodule
