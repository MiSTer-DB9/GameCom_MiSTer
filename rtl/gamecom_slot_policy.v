// Copyright (c) 2026 Jamie Blanks

module gamecom_slot_policy
(
	input wire [1:0] mode_i,
	input wire slot1_loaded_i,
	input wire slot2_loaded_i,

	output wire slot1_visible_o,
	output wire slot2_visible_o
);

	localparam [1:0] MODE_SLOT1_ONLY = 2'd1;
	localparam [1:0] MODE_SLOT2_ONLY = 2'd2;

	assign slot1_visible_o = slot1_loaded_i && (mode_i != MODE_SLOT2_ONLY);
	assign slot2_visible_o = slot2_loaded_i && (mode_i != MODE_SLOT1_ONLY);

endmodule
