// Copyright (c) 2026 Jamie Blanks

module gamecom_touch
(
	input wire clk_sys_i,
	input wire ce_i,
	input wire reset_i,
	input wire [1:0] mode_i,
	input wire [1:0] speed_i,
	input wire tap_i,
	input wire [15:0] joystick_analog_i,
	input wire [24:0] ps2_mouse_i,

	output reg touch_active_o,
	output reg [3:0] touch_x_o,
	output reg [3:0] touch_y_o
);

	// Precomputed for the 20 MHz system clock. Stick magnitude selects a rate
	// within each menu speed without synthesizable division or multiplication.
	localparam [24:0] MOVE_DIV_1HZ = 25'd19999999;
	localparam [24:0] MOVE_DIV_2HZ = 25'd9999999;
	localparam [24:0] MOVE_DIV_3HZ = 25'd6666666;
	localparam [24:0] MOVE_DIV_4HZ = 25'd4999999;
	localparam [24:0] MOVE_DIV_5HZ = 25'd3999999;
	localparam [24:0] MOVE_DIV_8HZ = 25'd2499999;
	localparam [24:0] MOVE_DIV_10HZ = 25'd1999999;
	localparam [24:0] MOVE_DIV_15HZ = 25'd1333332;
	localparam [24:0] MOVE_DIV_20HZ = 25'd999999;
	localparam [1:0] MODE_MOUSE = 2'd0;
	localparam [1:0] MODE_STICK = 2'd1;
	localparam [1:0] MODE_BOTH = 2'd2;
	localparam [1:0] MODE_OFF = 2'd3;
	localparam [1:0] SPEED_NORMAL = 2'd0;
	localparam [1:0] SPEED_SLOW = 2'd1;
	localparam [1:0] SPEED_FAST = 2'd2;
	localparam [3:0] TOUCH_X_MAX = 4'd12;
	localparam [3:0] TOUCH_Y_MAX = 4'd9;

	reg mouse_stb_q;
	reg signed [9:0] mouse_acc_x_q;
	reg signed [9:0] mouse_acc_y_q;
	reg [24:0] move_x_div_q;
	reg [24:0] move_y_div_q;
	reg stick_x_negative_q;
	reg stick_y_negative_q;

	wire mouse_mode_w = (mode_i == MODE_MOUSE) || (mode_i == MODE_BOTH);
	wire stick_mode_w = (mode_i == MODE_STICK) || (mode_i == MODE_BOTH);

	// MiSTer's PS/2 packet uses bit 0 for the left button, signed deltas in
	// bits 15:8 and 23:16, and a packet toggle in bit 24. Bits 7:1 are not
	// needed by the touchscreen adapter.
	wire signed [7:0] mouse_dx_w = ps2_mouse_i[15:8];
	wire signed [7:0] mouse_dy_w = ps2_mouse_i[23:16];
	wire signed [7:0] stick_x_w = joystick_analog_i[7:0];
	wire signed [7:0] stick_y_w = joystick_analog_i[15:8];

	function [7:0] delta_magnitude;
		input signed [7:0] delta_i;
		begin
			delta_magnitude = delta_i[7] ? (~delta_i + 8'd1) : delta_i;
		end
	endfunction

	wire [7:0] stick_x_magnitude_w = delta_magnitude(stick_x_w);
	wire [7:0] stick_y_magnitude_w = delta_magnitude(stick_y_w);

	function [1:0] stick_zone;
		input [7:0] magnitude_i;
		begin
			if (magnitude_i >= 8'd96) begin
				stick_zone = 2'd3;
			end else if (magnitude_i >= 8'd64) begin
				stick_zone = 2'd2;
			end else if (magnitude_i >= 8'd24) begin
				stick_zone = 2'd1;
			end else begin
				stick_zone = 2'd0;
			end
		end
	endfunction

	function [24:0] stick_reload;
		input [1:0] speed_value_i;
		input [1:0] zone_value_i;
		begin
			case (speed_value_i)
				2'd0: begin
					case (zone_value_i)
						2'd1: stick_reload = MOVE_DIV_2HZ;
						2'd2: stick_reload = MOVE_DIV_5HZ;
						2'd3: stick_reload = MOVE_DIV_10HZ;
						default: stick_reload = 25'd0;
					endcase
				end
				2'd1: begin
					case (zone_value_i)
						2'd1: stick_reload = MOVE_DIV_1HZ;
						2'd2: stick_reload = MOVE_DIV_2HZ;
						2'd3: stick_reload = MOVE_DIV_4HZ;
						default: stick_reload = 25'd0;
					endcase
				end
				2'd2: begin
					case (zone_value_i)
						2'd1: stick_reload = MOVE_DIV_3HZ;
						2'd2: stick_reload = MOVE_DIV_8HZ;
						2'd3: stick_reload = MOVE_DIV_15HZ;
						default: stick_reload = 25'd0;
					endcase
				end
				default: begin
					case (zone_value_i)
						2'd1: stick_reload = MOVE_DIV_4HZ;
						2'd2: stick_reload = MOVE_DIV_10HZ;
						2'd3: stick_reload = MOVE_DIV_20HZ;
						default: stick_reload = 25'd0;
					endcase
				end
			endcase
		end
	endfunction

	wire [1:0] stick_x_zone_w = stick_zone(stick_x_magnitude_w);
	wire [1:0] stick_y_zone_w = stick_zone(stick_y_magnitude_w);
	wire [24:0] move_x_reload_w = stick_reload(speed_i, stick_x_zone_w);
	wire [24:0] move_y_reload_w = stick_reload(speed_i, stick_y_zone_w);

	// Mouse counts accumulate instead of being thresholded, so a slow drag still
	// tracks and a fast flick does not jump the whole pad. The touch grid is
	// 13 x 10 cells over a 200 x 160 dot screen, roughly 16 screen dots per
	// cell, so the Normal rate of 16 counts per cell moves the cursor about one
	// screen dot per mouse count.
	//
	//   counts:  0 . . . 15 | 16 . . . 31 | 32 . . .
	//   cell:    +0          | +1          | +2
	function [9:0] counts_to_cells;
		input [1:0] speed_value_i;
		input [9:0] counts_i;
		begin
			case (speed_value_i)
				SPEED_SLOW: counts_to_cells = counts_i >> 5;
				SPEED_FAST: counts_to_cells = counts_i >> 3;
				SPEED_NORMAL: counts_to_cells = counts_i >> 4;
				default: counts_to_cells = counts_i >> 2;   // Turbo
			endcase
		end
	endfunction

	// Counts left over after whole cells are taken out; they carry into the
	// next packet so fractional motion is never thrown away.
	function [9:0] counts_remainder;
		input [1:0] speed_value_i;
		input [9:0] counts_i;
		begin
			case (speed_value_i)
				SPEED_SLOW: counts_remainder = counts_i & 10'h01F;
				SPEED_FAST: counts_remainder = counts_i & 10'h007;
				SPEED_NORMAL: counts_remainder = counts_i & 10'h00F;
				default: counts_remainder = counts_i & 10'h003;   // Turbo
			endcase
		end
	endfunction

	wire signed [9:0] mouse_dx_ext_w = {{2{mouse_dx_w[7]}}, mouse_dx_w};
	// PS/2 Y counts up when the pointer moves up; flip it so positive is down.
	wire signed [9:0] mouse_dy_ext_w = -{{2{mouse_dy_w[7]}}, mouse_dy_w};
	wire signed [9:0] mouse_acc_x_next_w = mouse_acc_x_q + mouse_dx_ext_w;
	wire signed [9:0] mouse_acc_y_next_w = mouse_acc_y_q + mouse_dy_ext_w;
	wire [9:0] mouse_acc_x_mag_w = mouse_acc_x_next_w[9] ? (~mouse_acc_x_next_w + 10'd1) : mouse_acc_x_next_w;
	wire [9:0] mouse_acc_y_mag_w = mouse_acc_y_next_w[9] ? (~mouse_acc_y_next_w + 10'd1) : mouse_acc_y_next_w;
	wire [9:0] mouse_cells_x_w = counts_to_cells(speed_i, mouse_acc_x_mag_w);
	wire [9:0] mouse_cells_y_w = counts_to_cells(speed_i, mouse_acc_y_mag_w);
	wire [9:0] mouse_keep_x_w = counts_remainder(speed_i, mouse_acc_x_mag_w);
	wire [9:0] mouse_keep_y_w = counts_remainder(speed_i, mouse_acc_y_mag_w);

	// One packet can never ask for more than a full sweep of the grid.
	wire [3:0] mouse_step_x_w = (mouse_cells_x_w > 10'd15) ? 4'd15 : mouse_cells_x_w[3:0];
	wire [3:0] mouse_step_y_w = (mouse_cells_y_w > 10'd15) ? 4'd15 : mouse_cells_y_w[3:0];

	task automatic step_x;
		input move_right_i;
		input [3:0] steps_i;
		reg [4:0] sum;
		begin
			if (steps_i != 4'd0) begin
				if (move_right_i) begin
					sum = {1'b0, touch_x_o} + {1'b0, steps_i};
					touch_x_o <= (sum >= {1'b0, TOUCH_X_MAX}) ? TOUCH_X_MAX : sum[3:0];
				end else begin
					touch_x_o <= (touch_x_o <= steps_i) ? 4'd0 : (touch_x_o - steps_i);
				end
			end
		end
	endtask

	task automatic step_y;
		input move_down_i;
		input [3:0] steps_i;
		reg [4:0] sum;
		begin
			if (steps_i != 4'd0) begin
				if (move_down_i) begin
					sum = {1'b0, touch_y_o} + {1'b0, steps_i};
					touch_y_o <= (sum >= {1'b0, TOUCH_Y_MAX}) ? TOUCH_Y_MAX : sum[3:0];
				end else begin
					touch_y_o <= (touch_y_o <= steps_i) ? 4'd0 : (touch_y_o - steps_i);
				end
			end
		end
	endtask

	always @(posedge clk_sys_i) begin
		if (reset_i) begin
			// Track the live toggle so a stale packet does not replay on release.
			mouse_stb_q <= ps2_mouse_i[24];
			mouse_acc_x_q <= 10'sd0;
			mouse_acc_y_q <= 10'sd0;
			move_x_div_q <= 25'd0;
			move_y_div_q <= 25'd0;
			stick_x_negative_q <= 1'b0;
			stick_y_negative_q <= 1'b0;
			touch_active_o <= 1'b0;
			touch_x_o <= 4'd5;
			touch_y_o <= 4'd4;
		end else if (ce_i) begin
			mouse_stb_q <= ps2_mouse_i[24];

			if (mode_i == MODE_OFF) begin
				touch_active_o <= 1'b0;
			end else begin
				touch_active_o <= (mouse_mode_w && ps2_mouse_i[0]) || (stick_mode_w && tap_i);
			end

			if (mouse_mode_w && (mouse_stb_q != ps2_mouse_i[24])) begin
				step_x(!mouse_acc_x_next_w[9], mouse_step_x_w);
				step_y(!mouse_acc_y_next_w[9], mouse_step_y_w);
				mouse_acc_x_q <= mouse_acc_x_next_w[9] ? -$signed(mouse_keep_x_w) : $signed(mouse_keep_x_w);
				mouse_acc_y_q <= mouse_acc_y_next_w[9] ? -$signed(mouse_keep_y_w) : $signed(mouse_keep_y_w);
			end

			if (!stick_mode_w || (stick_x_zone_w == 2'd0)) begin
				move_x_div_q <= 25'd0;
				stick_x_negative_q <= stick_x_w[7];
			end else if (stick_x_negative_q != stick_x_w[7]) begin
				move_x_div_q <= 25'd0;
				stick_x_negative_q <= stick_x_w[7];
			end else if (move_x_div_q == 25'd0) begin
				move_x_div_q <= move_x_reload_w;
				step_x(!stick_x_w[7], 4'd1);
			end else if (move_x_div_q > move_x_reload_w) begin
				move_x_div_q <= move_x_reload_w;
			end else begin
				move_x_div_q <= move_x_div_q - 25'd1;
			end

			if (!stick_mode_w || (stick_y_zone_w == 2'd0)) begin
				move_y_div_q <= 25'd0;
				stick_y_negative_q <= stick_y_w[7];
			end else if (stick_y_negative_q != stick_y_w[7]) begin
				move_y_div_q <= 25'd0;
				stick_y_negative_q <= stick_y_w[7];
			end else if (move_y_div_q == 25'd0) begin
				move_y_div_q <= move_y_reload_w;
				step_y(!stick_y_w[7], 4'd1);
			end else if (move_y_div_q > move_y_reload_w) begin
				move_y_div_q <= move_y_reload_w;
			end else begin
				move_y_div_q <= move_y_div_q - 25'd1;
			end
		end
	end

endmodule
