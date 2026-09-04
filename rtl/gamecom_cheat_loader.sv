// Copyright (c) 2026 Jamie Blanks

module gamecom_cheat_loader
(
	input wire clk_sys_i,
	input wire cheat_download_i,
	input wire cart_download_i,
	input wire ioctl_wr_i,
	input wire [3:0] ioctl_addr_i,
	input wire [7:0] ioctl_dout_i,
	output reg clear_o = 1'b0,
	output reg [128:0] code_o = 129'd0
);

	reg cheat_download_q = 1'b0;
	reg cart_download_q = 1'b0;

	always @(posedge clk_sys_i) begin
		code_o[128] <= 1'b0;
		clear_o <= 1'b0;
		cheat_download_q <= cheat_download_i;
		cart_download_q <= cart_download_i;

		if ((cheat_download_i && !cheat_download_q) ||
				(cart_download_i && !cart_download_q)) begin
			clear_o <= 1'b1;
		end

		if (cheat_download_i && ioctl_wr_i) begin
			case (ioctl_addr_i)
				4'd0: code_o[103:96] <= ioctl_dout_i;
				4'd1: code_o[111:104] <= ioctl_dout_i;
				4'd2: code_o[119:112] <= ioctl_dout_i;
				4'd3: code_o[127:120] <= ioctl_dout_i;
				4'd4: code_o[71:64] <= ioctl_dout_i;
				4'd5: code_o[79:72] <= ioctl_dout_i;
				4'd6: code_o[87:80] <= ioctl_dout_i;
				4'd7: code_o[95:88] <= ioctl_dout_i;
				4'd8: code_o[39:32] <= ioctl_dout_i;
				4'd9: code_o[47:40] <= ioctl_dout_i;
				4'd10: code_o[55:48] <= ioctl_dout_i;
				4'd11: code_o[63:56] <= ioctl_dout_i;
				4'd12: code_o[7:0] <= ioctl_dout_i;
				4'd13: code_o[15:8] <= ioctl_dout_i;
				4'd14: code_o[23:16] <= ioctl_dout_i;
				default: begin
					code_o[31:24] <= ioctl_dout_i;
					code_o[128] <= 1'b1;
				end
			endcase
		end
	end

endmodule
