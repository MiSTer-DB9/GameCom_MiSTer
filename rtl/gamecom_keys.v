// Copyright (c) 2026 Jamie Blanks

module gamecom_keys
(
	input wire clk_sys_i,
	input wire ce_i,
	input wire reset_i,
	input wire [10:0] ps2_key_i,

	output reg up_o,
	output reg down_o,
	output reg left_o,
	output reg right_o,
	output reg menu_o,
	output reg sound_o,
	output reg a_o,
	output reg b_o,
	output reg c_o,
	output reg d_o,
	output reg pause_o,
	output reg power_o
);

	reg key_toggle_q;
	wire key_pressed_w = ps2_key_i[9];
	wire key_extended_w = ps2_key_i[8];
	wire [7:0] key_code_w = ps2_key_i[7:0];

	always @(posedge clk_sys_i) begin
		if (reset_i) begin
			key_toggle_q <= 1'b0;
			up_o <= 1'b0;
			down_o <= 1'b0;
			left_o <= 1'b0;
			right_o <= 1'b0;
			menu_o <= 1'b0;
			sound_o <= 1'b0;
			a_o <= 1'b0;
			b_o <= 1'b0;
			c_o <= 1'b0;
			d_o <= 1'b0;
			pause_o <= 1'b0;
			power_o <= 1'b0;
		end else if (ce_i) begin
			if (key_toggle_q != ps2_key_i[10]) begin
				key_toggle_q <= ps2_key_i[10];

				if (key_extended_w) begin
					case (key_code_w)
						8'h75: up_o <= key_pressed_w;
						8'h72: down_o <= key_pressed_w;
						8'h6B: left_o <= key_pressed_w;
						8'h74: right_o <= key_pressed_w;
						default: ;
					endcase
				end else begin
					case (key_code_w)
						8'h3A: menu_o <= key_pressed_w;  // M
						8'h1B: sound_o <= key_pressed_w; // S
						8'h1A: a_o <= key_pressed_w;     // Z
						8'h22: b_o <= key_pressed_w;     // X
						8'h21: c_o <= key_pressed_w;     // C
						8'h23: d_o <= key_pressed_w;     // D
						8'h2A: pause_o <= key_pressed_w; // V
						8'h29: pause_o <= key_pressed_w; // Space
						8'h5A: pause_o <= key_pressed_w; // Enter
						8'h31: power_o <= key_pressed_w; // N
						default: ;
					endcase
				end
			end
		end
	end

endmodule
