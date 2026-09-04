// Copyright (c) 2026 Jamie Blanks

module gamecom_status
(
	input wire clk_sys_i,
	input wire ce_i,
	input wire reset_i,
	input wire pll_locked_i,
	input wire bios_loaded_i,
	input wire slot1_loaded_i,
	input wire slot2_loaded_i,
	input wire cart_download_i,
	input wire ext_bios_download_i,
	input wire cart_access_pulse_i,
	input wire save_write_pulse_i,
	input wire save_pending_i,
	input wire save_busy_i,
	input wire serial_enable_i,
	input wire uart_rxd_i,
	input wire uart_txd_i,

	output wire led_user_o,
	output wire [1:0] led_disk_o
);

	localparam [19:0] ACTIVITY_HOLD = 20'hFFFFF;

	reg [24:0] heart_q;
	reg [19:0] cart_activity_q;
	reg [19:0] serial_activity_q;
	reg uart_rxd_q;
	reg uart_txd_q;

	wire any_cart_loaded_w = slot1_loaded_i || slot2_loaded_i;
	wire cart_event_w = cart_download_i || ext_bios_download_i ||
		cart_access_pulse_i || save_write_pulse_i;
	wire serial_event_w = serial_enable_i &&
		((uart_rxd_q != uart_rxd_i) || (uart_txd_q != uart_txd_i));
	wire cart_active_w = (cart_activity_q != 20'd0) || save_busy_i;
	wire serial_active_w = (serial_activity_q != 20'd0);

	// The disk LEDs report live cartridge/save activity and a pending save.
	// The user LED gives startup faults priority over serial and cart activity.
	assign led_disk_o = {cart_active_w, save_pending_i};
	assign led_user_o =
		!pll_locked_i ? 1'b0 :
		!bios_loaded_i ? heart_q[22] :
		!any_cart_loaded_w ? heart_q[24] :
		serial_active_w ? heart_q[21] :
		cart_active_w;

	always @(posedge clk_sys_i) begin
		if (reset_i) begin
			heart_q <= 25'd0;
			cart_activity_q <= 20'd0;
			serial_activity_q <= 20'd0;
			uart_rxd_q <= 1'b1;
			uart_txd_q <= 1'b1;
		end else if (ce_i) begin
			heart_q <= heart_q + 25'd1;
			uart_rxd_q <= uart_rxd_i;
			uart_txd_q <= uart_txd_i;

			if (cart_event_w) begin
				cart_activity_q <= ACTIVITY_HOLD;
			end else if (cart_activity_q != 20'd0) begin
				cart_activity_q <= cart_activity_q - 20'd1;
			end

			if (serial_event_w) begin
				serial_activity_q <= ACTIVITY_HOLD;
			end else if (serial_activity_q != 20'd0) begin
				serial_activity_q <= serial_activity_q - 20'd1;
			end
		end
	end

endmodule
