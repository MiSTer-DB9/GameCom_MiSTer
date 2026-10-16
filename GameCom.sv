//============================================================================
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler
	output        VGA_DISABLE, // analog out is off

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,
	output        HDMI_BLACKOUT,
	output        HDMI_BOB_DEINT,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: USER_OSD + per-pin push-pull mask, USER_IO widened to 8 bits
	output        USER_OSD,
	output  [7:0] USER_PP,
	input   [7:0] USER_IN,
	output  [7:0] USER_OUT,
	// [MiSTer-DB9 END]

	input         OSD_STATUS
);

///////// Default values for ports not used in this core /////////

assign ADC_BUS  = 'Z;
// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: USER_PP driven by wrapper; USER_OUT driven by joydb (USER_OUT_DRIVE) below
assign USER_PP = USER_PP_DRIVE;
// [MiSTer-DB9 END]
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;

assign VGA_F1 = 0;
assign VGA_SCALER  = 0;
assign VGA_DISABLE = 0;
assign HDMI_FREEZE = savestate_pause_active_q;
assign HDMI_BLACKOUT = 0;
assign HDMI_BOB_DEINT = 0;

assign BUTTONS = 0;

//////////////////////////////////////////////////////////////////

wire [1:0] ar = status[122:121];
wire [2:0] scale = status[3:1];
wire [2:0] scanline_level = (scale != 3'd0) ? (scale - 3'd1) : 3'd0;

// 200x160 dots are square, so the original ratio is 5:4.
wire [11:0] video_arx = (ar == 2'd0) ? 12'd5 : {10'd0, (ar - 2'd1)};
wire [11:0] video_ary = (ar == 2'd0) ? 12'd4 : 12'd0;
wire  [2:0] video_scale = {1'b0, status[120:119]};
assign VGA_SL = scanline_level[1:0];

// Cart slot 1 is FS1 because the S is required for save states updating their mounted files. Consequently,
// only slot 1 supports save states, not slot 2.
`include "build_id.v"
localparam CONF_STR = {
	"Gamecom;SS3E000000:200000,UART115200:9600,Modem;",
	"-;",
	"FS1,TGC,Load Cartridge 1;",
	"F2,TGC,Load Cartridge 2 (No SS);",
	"-;",
	"O[46:45],Savestate Slot,1,2,3,4;",
	"d7rA,Save state(Alt+F1-F4);",
	"d7rB,Restore state(F1-F4);",
	"-;",
	"C,Cheats;",
	"-;",
	"P1,Input;",
	"P1-;",
	"P1O[18:17],Touch Control,Mouse,Stick,Hybrid,Off;",
	"P1O[20:19],Touch Speed,Normal,Slow,Fast,Turbo;",
	"P1O[23],Touch Cursor,On,Off;",
	"P1O[21],Serial Port,On,Off;",
	"P1O[26],Serial Route,Internal,SNAC;",
	"P2,Video;",
	"P2-;",
	"P2O[25],Video Output,Buffered 60Hz,Native 75Hz;",
	"P2O[3:1],Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"P2O[122:121],Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"P2O[120:119],Scale,Normal,V-Integer,Narrower HV-Integer,Wider HV-Integer;",
	"P2O[6:5],Custom Palette,Kit.com,Greenish,Greyish,Custom;",
	"H0P2FC3,GBP,Load Palette;",
	"P3,Advanced;",
	"P3-;",
	"P3O[22],Stop-Free Boot,On,Off;",
	"P3O[27],Cart SDRAM ROM,2-Cycle,Wait Ready;",
	"P3O[24],Reset During Cart Load,Off,On;",
	"P3OD,Autosave,On,Off;",
	"P3O[44],Savestates to SDCard,On,Off;",
	"-;",
	// [MiSTer-DB9-Pro BEGIN] - Saturn-first joy_type (canonical bit notation)
	"O[127:126],UserIO Joystick,Off,Saturn,DB9MD,DB15;",
	// [MiSTer-DB9-Pro END]
	"R0,Reset;",
	"J1,A,B,C,D,Pause,Menu,Sound,Power,Touch Tap,Savestates;",
	// OSD banner lines, indexed 1-based. savestate_ui asks for 5 (chord help),
	// 6+slot (slot picked) and 10+{slot,load} (saved / restored), so entries
	// 2-4 are placeholders: the index is a position in this list, not a name.
	"I,External BIOS is expected as boot.rom and arrives on ioctl index 0.,",
	"-,",
	"-,",
	"-,",
	"Slot=L/R Load=U Save=D,",
	"Active Slot 1,",
	"Active Slot 2,",
	"Active Slot 3,",
	"Active Slot 4,",
	"Save to state 1,",
	"Restore state 1,",
	"Save to state 2,",
	"Restore state 2,",
	"Save to state 3,",
	"Restore state 3,",
	"Save to state 4,",
	"Restore state 4;",
	"v,7;", // [optional] config version 0-99.
	// If CONF_STR options are changed in incompatible way, then change version number too,
	// so all options will get default values on first start.
	"V,v",`BUILD_DATE
};

wire   [1:0] buttons;
wire [127:0] status;
wire [31:0] joystick_0;
wire [15:0] joystick_l_analog_0;
wire [24:0] ps2_mouse;
wire  [10:0] ps2_key;
wire ioctl_download;
wire [15:0] ioctl_index;
wire ioctl_wr;
wire [26:0] ioctl_addr;
wire [7:0] ioctl_dout;
wire [31:0] sd_lba[2];
wire [5:0] sd_blk_cnt[2];
wire [1:0] sd_rd;
wire [1:0] sd_wr;
wire [1:0] sd_ack;
wire [8:0] sd_buff_addr;
wire [7:0] sd_buff_dout;
wire [7:0] sd_buff_din[2];
wire sd_buff_wr;
wire [1:0] img_mounted;
wire img_readonly;
wire [63:0] img_size;
wire cart_loader_wait;
wire palette_download = ioctl_download && (ioctl_index == 16'd3);
wire [64:0] rtc;
wire savestate_menu_enabled;
wire custom_palette_menu_enabled;
wire clk_sys;
wire clk_vid;
wire vga_de;
wire [1:0] savestate_slot;
wire [7:0] savestate_info;
wire savestate_info_req;
wire savestate_status_update;
wire forced_scandoubler;
wire [21:0] gamma_bus;

// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: joydb wrapper
wire         CLK_JOY = CLK_50M;                 // Assign clock between 40-50Mhz
wire   [1:0] joy_type_raw    = status[127:126]; // 0=Off, 1=Saturn, 2=DB9MD, 3=DB15
wire         joy_2p          = 1'b0;          // 1P-only: joy_2p unused
// SNAC cores: replace 1'b0 with the core's SNAC enable expression so SNAC
// preempts the joydb wrapper on shared USER_IO pins. Default 1'b0 is no-op.
wire         snac_active     = serial_snac_enable;
// MT32-pi cores on primary USER_IO: replace 1'b0 with the core's MT32-active
// expression (e.g. `mt32_use` under `ifndef SECOND_MT32`, `~mt32_disable` for
// TRS-80's inverted polarity). Suppresses the OSD-open autodetect probe so it
// doesn't read the RPi's I2C master traffic as a ghost Saturn signature.
wire         mt32_primary_active = 1'b0;
wire   [1:0] joy_type        = snac_active ? 2'd0 : joy_type_raw;
wire         joy_db9md_en    = (joy_type == 2'd2);
wire         joy_db15_en     = (joy_type == 2'd3);
wire         joy_any_en      = |joy_type;
// [MiSTer-DB9 END]

// [MiSTer-DB9-Pro BEGIN] - Saturn key gate
wire         saturn_unlocked;                   // driven by hps_io UIO_DB9_KEY (0xFE)
// [MiSTer-DB9-Pro END]

// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: joydb wrapper wires + instance
wire   [7:0] USER_OUT_DRIVE;
wire   [7:0] USER_PP_DRIVE;
wire  [15:0] joydb_1, joydb_2;
wire         joydb_1ena, joydb_2ena;
wire  [15:0] joy_raw_payload;
// Programmable-remap matrix (joydb_remap inside joydb): clk_sys carries the
// 0xFD selector load (HPS-bus domain). joydb_*_mapped are the MiSTer-standard
// joystick words the core consumes at its joy0_USB merge point. db9_remap_*
// are driven by the hps_io instance (see the .db9_remap_* bindings there).
// Until a core consumes joydb_*_mapped (Layer B), the matrix stays at identity
// and synthesis prunes it -- binding these is dormant + fleet-safe.
wire  [15:0] joydb_1_mapped, joydb_2_mapped;
wire         db9_remap_cmd;
wire   [5:0] db9_remap_byte_cnt;
wire  [15:0] db9_remap_din;

// [MiSTer-DB9 BEGIN] - DB9 remap factory default (used until Main_MiSTer streams UIO 0xFD)
// Derived from CONF_STR J1, same rule as db9_map.cpp; lets the core work on a stock MiSTer binary.
// DB15:  A=A, B=B, C=C, D=D, Pause=-, Menu=E, Sound=F, Power=-, Touch Tap=-
// DB9MD: A=A, B=B, C=C, D=X, Pause=START, Menu=Y, Sound=Z, Power=-, Touch Tap=-
wire  [35:0] db9_remap_default_db15  = 36'hFF98F7654;
wire  [35:0] db9_remap_default_db9md = 36'hFF98A7654;
// [MiSTer-DB9 END]
joydb joydb (
  .clk             ( CLK_JOY         ),
  .clk_sys         ( clk_sys            ),
  .USER_IN         ( USER_IN         ),
  .OSD_STATUS          ( OSD_STATUS          ),
  .snac_active         ( snac_active         ),
  .mt32_primary_active ( mt32_primary_active ),
  .joy_type        ( joy_type        ),
  .joy_2p          ( joy_2p          ),
  .saturn_unlocked ( saturn_unlocked ),
  .USER_OUT_DRIVE  ( USER_OUT_DRIVE  ),
  .USER_PP_DRIVE   ( USER_PP_DRIVE   ),
  .USER_OSD        ( USER_OSD        ),
  .joydb_1         ( joydb_1         ),
  .joydb_2         ( joydb_2         ),
  .joydb_1ena      ( joydb_1ena      ),
  .joydb_2ena      ( joydb_2ena      ),
  .remap_cmd       ( db9_remap_cmd      ),
  .remap_byte_cnt  ( db9_remap_byte_cnt ),
  .remap_din       ( db9_remap_din      ),
  .remap_default_db15  ( db9_remap_default_db15  ),
  .remap_default_db9md ( db9_remap_default_db9md ),
  .joydb_1_mapped  ( joydb_1_mapped     ),
  .joydb_2_mapped  ( joydb_2_mapped     ),
  .joy_raw         ( joy_raw_payload )
);

// USER_OUT is composed with the upstream SNAC serial route below.
// [MiSTer-DB9 END]

// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: rename USB joystick wires
wire [31:0] joystick_0_USB;
// [MiSTer-DB9 END]

hps_io #(.CONF_STR(CONF_STR), .VDNUM(2)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),
	.EXT_BUS(),
	.gamma_bus(gamma_bus),

	.forced_scandoubler(forced_scandoubler),

	.buttons(buttons),
	.status(status),
	.status_menumask({8'd0, savestate_menu_enabled, 6'd0, custom_palette_menu_enabled}),
	.status_in({status[127:47], savestate_slot, status[44:0]}),
	.status_set(savestate_status_update),
	.joystick_0(joystick_0_USB),
	.joystick_l_analog_0(joystick_l_analog_0),
	.ps2_mouse(ps2_mouse),

	.ps2_key(ps2_key),

	.ioctl_download(ioctl_download),
	.ioctl_index(ioctl_index),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_upload_req(1'b0),
	.ioctl_upload_index(8'h00),
	.ioctl_din(8'h00),
	.ioctl_wait(cart_loader_wait),

	.sd_lba(sd_lba),
	.sd_blk_cnt(sd_blk_cnt),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(sd_buff_din),
	.sd_buff_wr(sd_buff_wr),
	.img_mounted(img_mounted),
	.img_readonly(img_readonly),
	.img_size(img_size),
	.info_req(savestate_info_req),
	.info(savestate_info),
	.RTC(rtc),
	.sdram_sz(),
	// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: joy_raw
	.joy_raw(joy_raw_payload),
	// programmable remap matrix selector load (UIO_DB9_MAP 0xFD)
	.db9_remap_cmd(db9_remap_cmd),
	.db9_remap_byte_cnt(db9_remap_byte_cnt),
	.db9_remap_din(db9_remap_din),
	// [MiSTer-DB9 END]
	// [MiSTer-DB9-Pro BEGIN] - Saturn key gate
	.saturn_unlocked(saturn_unlocked)
	// [MiSTer-DB9-Pro END]
);

// [MiSTer-DB9-Pro BEGIN] - DB controllers muted while OSD is open
// joydb_*_mapped is already in MiSTer-standard J1 order, identical to the USB
// joystick word, so it replaces the USB input as-is.
assign joystick_0 = joydb_1ena ? (OSD_STATUS ? 16'b0 : joydb_1_mapped) : joystick_0_USB;
// [MiSTer-DB9-Pro END]

///////////////////////   CLOCKS   ///////////////////////////////

wire clk_ram;
wire pll_locked;
pll pll
(
	.refclk(CLK_50M),
	.rst(1'b0),
	.outclk_0(clk_sys), // 20 MHz clock
	.outclk_1(clk_ram), // 80 MHz clock for SDRAM
	.outclk_2(clk_vid), // 60 MHz video clock
	.locked(pll_locked)
);

reg [1:0] phi_div = 0;
localparam [25:0] TOUCH_CURSOR_IDLE_CLKS = 26'd39321600;
always @(posedge clk_sys) begin
	phi_div <= phi_div + 1'd1;
end

wire phi0 = phi_div == 2'b00; // fCK/2, the 5 MHz leading edge
wire phi1 = phi_div == 2'b10; // the trailing edge, half a cycle later
wire phi0_core = phi0 && !savestate_pause_active_q;
wire phi1_core = phi1 && !savestate_pause_active_q;

localparam [20:0] EXT_BIOS_SIZE = 21'd262144;
// The CPU exposes the console NVRAM / extended RAM window
// at E000-FFFF. Keep MiSTer persistence sized to that hardware-visible region
// instead of implying cartridge-local save SRAM.
localparam integer NVRAM_BYTES = 8192;
localparam [31:0] NVRAM_BLOCKS = 32'd16;
localparam [7:0] SDRAM_REFRESH_PERIOD = 8'd155;
localparam [4:0] WARM_BOOT_HOLD_CYCLES = 5'd31;
// Savestate payload length in 32-bit words, excluding the two header words:
// the internal register block (1 x 64-bit) plus every SAVETYPE region.
localparam integer GAMECOM_SAVESTATE_SIZE = 6722;
// statemanager shifts a 32-bit word address, so a slot spans 4 << SHIFT bytes.
// This must equal the per-slot size in the CONF_STR SS token, 0x200000.
localparam integer GAMECOM_SAVESTATE_SLOT_SHIFT = 19;
localparam integer GAMECOM_SAVESTATE_BASE = 32'h03800000;
localparam integer GAMECOM_REWIND_BASE = 32'h02000000;
localparam integer GAMECOM_SS_INTERNAL_WORDS = 1;
localparam integer GAMECOM_SS_CPU_STATE_BYTES = 2048;
// Five RGB888 LCD pens, ordered white through black.
localparam [119:0] DEFAULT_CUSTOM_PALETTE = 120'hE7E8D6D4D8BAA7AF86737D5E424B3B;
localparam [119:0] PALETTE_GREENISH       = 120'hE1E0D4C9C8B6A4A48A7A7A5F4C4D3C;
localparam [119:0] PALETTE_GRAYISH        = 120'hEDE7D8DED4C0B9AC908C80685A5141;

localparam [3:0] GBP_PALETTE_FOUR_COLOR_BYTES = 4'd12;
localparam [3:0] GAMECOM_PALETTE_COLOR_BYTES = 4'd15;

wire cart1_download = ioctl_download && (ioctl_index == 16'd1);
wire cart2_download = ioctl_download && (ioctl_index == 16'd2);
wire cart_download = cart1_download || cart2_download;
wire ext_bios_download = ioctl_download && (ioctl_index == 16'd0);
wire cheat_download = ioctl_download && (ioctl_index == 16'd255);
wire save_loading;
wire save_pending;
wire save_busy;
wire savestate_ram_active;
wire savestate_save_ram_sel;
wire savestate_core_mem_active;
wire savestate_pause_ready;
wire savestate_savestate;
wire savestate_loadstate;
wire savestate_busy;
wire saving_savestate;
wire loading_savestate;
wire sleep_savestate;
wire savestate_ui_save;
wire savestate_ui_load;
integer savestate_address;
wire [63:0] savestate_ddr_dout;
wire [63:0] savestate_ddr_din;
wire [27:2] savestate_ddr_addr;
wire [7:0] savestate_ddr_be;
wire savestate_ddr_rnw;
wire savestate_ddr_req;
wire savestate_ddr_ack;
wire [63:0] SaveStateBus_Dout = 64'h0000000000000000;
wire [24:0] Savestate_RAMAddr;
wire Savestate_RAMRdEn;
wire Savestate_RAMWrEn;
wire [7:0] Savestate_RAMWriteData;
wire [7:0] Savestate_RAMReadData;
wire [2:0] Savestate_RAMType;
wire [7:0] core_savestate_mem_rdata;
wire [1:0] touch_mode = status[18:17];
wire [1:0] touch_speed = status[20:19];
wire serial_enable = !status[21];
wire stop_disable = !status[22];
wire show_touch_cursor = !status[23] && (touch_mode != 2'b11);
wire reset_while_cart_loading = status[24];
wire video_60hz = !status[25];
wire serial_snac = status[26];
wire cart_sdram_fixed_2cycle = !status[27];
wire warm_reset_request = pll_locked && (RESET | status[0] | buttons[1]);
wire cold_reset_request = !pll_locked;
wire system_reset = cold_reset_request | warm_reset_request;
wire reset;

wire HBlank;
wire HSync;
wire VBlank;
wire VSync;
wire ce_pix;
wire [2:0] shade;
wire [20:0] cart_addr;
wire cart_rd;
wire cart_wr;
wire cart_slot1_sel;
wire cart_slot2_sel;
wire [15:0] board_audio;
wire board_txdb;
wire board_uart_rts;
wire board_uart_dtr;
wire [12:0] save_addr;
wire [7:0] save_dout;
wire save_rd;
wire save_wren;
wire save_load_wren;
wire touch_active;
wire [3:0] touch_x;
wire [3:0] touch_y;
wire touch_cursor_enable;
wire [7:0] cart_din;
wire ext_bios_wr;
wire [7:0] ext_bios_data;
wire cart_sdram_busy;
wire cart_sdram_refresh_seen_w;
wire [7:0] cart_sdram_dout;
wire key_up;
wire key_down;
wire key_left;
wire key_right;
wire key_menu;
wire key_sound;
wire key_a;
wire key_b;
wire key_c;
wire key_d;
wire key_pause;
wire key_power;
// Holding Savestates turns the d-pad into slot select and save/load, so keep
// those presses away from the console while the chord is down. The keyboard
// F-keys reach savestate_ui on their own and need no such guard.
wire savestate_chord = joystick_0[13];
wire dpad_enable = ~savestate_chord;
wire button_up = (joystick_0[3] & dpad_enable) | key_up;
wire button_down = (joystick_0[2] & dpad_enable) | key_down;
wire button_left = (joystick_0[1] & dpad_enable) | key_left;
wire button_right = (joystick_0[0] & dpad_enable) | key_right;
wire button_menu = joystick_0[9] | key_menu;
wire button_sound = joystick_0[10] | key_sound;
wire button_a = joystick_0[4] | key_a;
wire button_b = joystick_0[5] | key_b;
wire button_c = joystick_0[6] | key_c;
wire button_d = joystick_0[7] | key_d;
wire button_pause = joystick_0[8] | key_pause;
// Keep keyboard Power and line the pad bits up with the J1 declaration.
wire button_power = joystick_0[11] | key_power;
// Keep touchscreen taps independent from the console's A matrix input. A
// simultaneous tap can otherwise win the software scan even when the cursor
// overlay is hidden.
wire touch_tap = joystick_0[12];
wire serial_internal_enable = serial_enable && !serial_snac;
wire serial_snac_enable = serial_enable && serial_snac;
// SNAC/User I/O serial route:
// USER_IO[0]=RXD input, USER_IO[1]=TXD output, USER_IO[2]=CTS input,
// USER_IO[3]=RTS output, USER_IO[4]=DSR input, USER_IO[5]=DTR output,
// USER_IO[6]=unused/released. USER_OUT follows MiSTer's open-drain
// convention: 0 pulls the pin low, 1 releases it for input/high.
wire uart_rxd_core = serial_enable ? (serial_snac ? USER_IN[0] : UART_RXD) : 1'b1;
wire uart_cts_core = serial_enable ? (serial_snac ? USER_IN[2] : UART_CTS) : 1'b1;
wire uart_dsr_core = serial_enable ? (serial_snac ? USER_IN[4] : UART_DSR) : 1'b1;
wire [1:0] led_disk;
wire led_user;
reg prev_cart_rd = 1'b0;
reg cart1_download_r = 1'b0;
reg cart2_download_r = 1'b0;
reg ext_bios_download_r = 1'b0;
reg cart1_loaded_q = 1'b0;
reg cart2_loaded_q = 1'b0;
reg palette_download_r = 1'b0;
reg [7:0] cart_sdram_refresh_div_q = 8'd0;
reg cart_sdram_refresh_pending_q = 1'b0;
reg cart1_seen_write_q = 1'b0;
reg cart2_seen_write_q = 1'b0;
reg [119:0] custom_palette_q = DEFAULT_CUSTOM_PALETTE;
reg [87:0] custom_palette_load_q = 88'd0;
reg [3:0] palette_download_byte_count_q = 4'd0;
reg ext_bios_loaded_q = 1'b0;
reg ext_bios_seen_wr_q = 1'b0;
reg [25:0] touch_cursor_idle_q = 26'd0;
reg [3:0] touch_cursor_prev_x_q = 4'd5;
reg [3:0] touch_cursor_prev_y_q = 4'd4;
reg touch_cursor_visible_q = 1'b0;
reg [4:0] warm_boot_hold_q = 5'd0;
reg [23:0] slot1_addr_mask_q = 24'd0;
reg [23:0] slot2_addr_mask_q = 24'd0;
reg [17:0] ext_bios_addr_q = 18'd0;
reg [12:0] save_addr_q = 13'd0;
reg savestate_pause_active_q = 1'b0;

wire [119:0] current_palette = status[6:5] == 2'b00 ? DEFAULT_CUSTOM_PALETTE :
	(status[6:5] == 2'b01 ? PALETTE_GREENISH :
	status[6:5] == 2'b10 ? PALETTE_GRAYISH : custom_palette_q);
// A zero fifth color marks a conventional four-color palette. Active pixels
// then use the first four entries directly instead of selecting four of the
// Game.com's five physical LCD pens through LCC gradation.
wire palette_four_color_w = current_palette[23:0] == 24'h000000;

wire cart_ext_bios_sel = (cart_addr < EXT_BIOS_SIZE);
wire cart_sdram_sel = !cart_ext_bios_sel;
wire cart_sdram_loader_owned_w = cart_download;
// The SM8521 only exposes a ROM-class chip select (MCE0B). On the Game.com
// board, external BIOS vs cartridge is therefore a downstream decode on that
// ROM bus rather than a separate CPU pin.
wire board_bios_cycle_w = (cart_rd || cart_wr) && cart_ext_bios_sel;
wire board_cart_read_w = cart_rd && cart_sdram_sel;
wire board_slot1_selected_w = cart_slot1_sel;
wire board_slot2_selected_w = cart_slot2_sel && !cart_slot1_sel;
wire slot1_loading_w = cart1_download;
wire slot2_loading_w = cart2_download;
// P3[7:6] is the hardware slot-select output. Presence only determines
// whether the selected slot actually responds on the ROM bus.
wire board_slot1_active = board_slot1_selected_w && cart1_loaded_q;
wire board_slot2_active = board_slot2_selected_w && cart2_loaded_q;
// While HPS owns the cart SDRAM port for a download, the console side must not
// issue any live ROM accesses. Treat both slots as absent until the download is
// fully complete so loader writes plus refresh are the only SDRAM activity.
wire board_cart_present = !cart_sdram_loader_owned_w &&
	(board_slot1_active || board_slot2_active);
wire board_selected_slot_loading_w =
	(board_slot1_selected_w && slot1_loading_w) ||
	(board_slot2_selected_w && slot2_loading_w);
wire [23:0] board_cart_addr_mask_w = board_slot2_selected_w ? slot2_addr_mask_q : slot1_addr_mask_q;
// Treat cart SDRAM as ROM backing. Default to a ready-qualified sample hold,
// with an Advanced menu option to force the datasheet-style setup/sample cadence.
wire ext_bios_port_active_w = ext_bios_wr || board_bios_cycle_w;
wire [17:0] ext_bios_addr_hold_w = ext_bios_wr ? ioctl_addr[17:0] :
	(board_bios_cycle_w ? cart_addr[17:0] : ext_bios_addr_q);
wire save_port_active_w = save_rd || save_wren;
wire [12:0] save_addr_hold_w = save_port_active_w ? save_addr : save_addr_q;

// HPS writes are the only permitted cart-SDRAM accesses during a download.
// Backpressure follows the controller busy signal so every loader byte is kept.
assign cart_loader_wait = cart_download && cart_sdram_busy;
assign ext_bios_wr = ioctl_download && (ioctl_index == 16'd0) && ioctl_wr &&
	(ioctl_addr[26:18] == 9'd0);
assign cart_din = board_cart_read_w ?
	(board_selected_slot_loading_w ? 8'hFF :
	(board_cart_present ? cart_sdram_dout : 8'hFF)) :
	ext_bios_data;
assign sd_blk_cnt[0] = 6'd0;
assign sd_blk_cnt[1] = 6'd0;
assign sd_rd[0] = 1'b0;
assign sd_wr[0] = 1'b0;
assign sd_lba[0] = 32'd0;
assign save_load_wren = sd_buff_wr && sd_ack[1] && save_loading;
assign savestate_menu_enabled = ext_bios_loaded_q && (cart1_loaded_q || cart2_loaded_q) &&
	!cart_download && !save_loading;
assign custom_palette_menu_enabled = status[6:5] != 2'b11;
assign touch_cursor_enable = show_touch_cursor && touch_cursor_visible_q;
assign savestate_ram_active = saving_savestate || loading_savestate;
assign savestate_save_ram_sel = savestate_ram_active && (Savestate_RAMType == 3'd0);
assign savestate_core_mem_active = savestate_ram_active && (Savestate_RAMType != 3'd0);
assign Savestate_RAMReadData = savestate_save_ram_sel ? save_ram_hps_q : core_savestate_mem_rdata;
// BIOS and NVRAM transfers reset the console while video timing keeps running.
// Cartridge downloads normally make both slots absent until the image completes;
// the Advanced option can also hold the console core in reset for that interval.
// Savestate restore uses the pause gate and dedicated memory replay ports.
assign reset = system_reset | ext_bios_download | save_loading | !ext_bios_loaded_q |
	(reset_while_cart_loading && cart_download);
wire warm_boot_effective = warm_reset_request || (warm_boot_hold_q != 5'd0);

function [23:0] custom_palette_color;
	input [119:0] palette_i;
	input [2:0] shade_i;
	begin
		// Palette payloads carry five 24-bit Game.com LCD pens.
		case (shade_i)
			3'd4: custom_palette_color = palette_i[119:96];
			3'd3: custom_palette_color = palette_i[95:72];
			3'd2: custom_palette_color = palette_i[71:48];
			3'd1: custom_palette_color = palette_i[47:24];
			default: custom_palette_color = palette_i[23:0];
		endcase
	end
endfunction

wire [23:0] video_rgb = custom_palette_color(current_palette, shade);
wire [12:0] save_ram_hps_addr = {sd_lba[1][3:0], sd_buff_addr};
wire [7:0] save_ram_hps_q;
wire [7:0] save_ram_core_q;
wire [128:0] cheat_code_w;
wire cheat_clear_w;
wire [12:0] save_ram_port_a_addr = savestate_save_ram_sel ? Savestate_RAMAddr[12:0] : save_ram_hps_addr;
wire save_ram_port_a_wren = savestate_save_ram_sel ? Savestate_RAMWrEn : save_load_wren;
wire [7:0] save_ram_port_a_wdata = savestate_save_ram_sel ? Savestate_RAMWriteData : sd_buff_dout;
wire cart1_sdram_we_w = cart1_download && ioctl_wr;
wire cart2_sdram_we_w = cart2_download && ioctl_wr;
wire cart_sdram_we_w = cart1_sdram_we_w || cart2_sdram_we_w;
wire cart_sdram_rd_w = board_cart_read_w && board_cart_present &&
	!board_selected_slot_loading_w && !cart_sdram_we_w;
wire cart_sdram_refresh_w = !cart_sdram_loader_owned_w &&
	!cart_sdram_we_w && !cart_sdram_rd_w &&
	!cart_sdram_busy && cart_sdram_refresh_pending_q;
wire [23:0] board_cart_real_addr_w = {3'd0, cart_addr} & board_cart_addr_mask_w;
// Slot select is modeled as the top SDRAM address bit. The remaining bits are
// the raw mirrored ROM address with no loader-side offset interpretation.
wire [24:0] board_cart_live_sdram_addr_w = {board_slot2_selected_w, board_cart_real_addr_w};
wire [24:0] cart_sdram_addr_w = cart1_sdram_we_w ? {1'b0, ioctl_addr[23:0]} :
	(cart2_sdram_we_w ? {1'b1, ioctl_addr[23:0]} :
	(cart_sdram_rd_w ? board_cart_live_sdram_addr_w : 25'd0));
wire [7:0] cart_sdram_din_w = cart_sdram_we_w ? ioctl_dout : 8'h00;
wire cart_sdram_ready_w = !board_cart_read_w || !board_cart_present ||
	board_selected_slot_loading_w || !cart_sdram_busy;
wire rom_read_ready_w = cart_sdram_fixed_2cycle ? 1'b1 : cart_sdram_ready_w;
wire [63:0] save_mount_size = {50'd0, NVRAM_BYTES[13:0]};

gamecom_cheat_loader u_cheat_loader (
	.clk_sys_i(clk_sys),
	.cheat_download_i(cheat_download),
	.cart_download_i(cart_download),
	.ioctl_wr_i(ioctl_wr),
	.ioctl_addr_i(ioctl_addr[3:0]),
	.ioctl_dout_i(ioctl_dout),
	.clear_o(cheat_clear_w),
	.code_o(cheat_code_w)
);

gamecom_touch u_touch (
	.clk_sys_i(clk_sys),
	.ce_i(1'b1),
	.reset_i(system_reset),
	.mode_i(touch_mode),
	.speed_i(touch_speed),
	.tap_i(touch_tap),
	.joystick_analog_i(joystick_l_analog_0),
	.ps2_mouse_i(ps2_mouse),
	.touch_active_o(touch_active),
	.touch_x_o(touch_x),
	.touch_y_o(touch_y)
);

gamecom_keys u_keys (
	.clk_sys_i(clk_sys),
	.ce_i(1'b1),
	.reset_i(system_reset),
	.ps2_key_i(ps2_key),
	.up_o(key_up),
	.down_o(key_down),
	.left_o(key_left),
	.right_o(key_right),
	.menu_o(key_menu),
	.sound_o(key_sound),
	.a_o(key_a),
	.b_o(key_b),
	.c_o(key_c),
	.d_o(key_d),
	.pause_o(key_pause),
	.power_o(key_power)
);

gamecom_status u_status (
	.clk_sys_i(clk_sys),
	.ce_i(1'b1),
	.reset_i(system_reset),
	.pll_locked_i(pll_locked),
	.bios_loaded_i(ext_bios_loaded_q),
	.slot1_loaded_i(cart1_loaded_q),
	.slot2_loaded_i(cart2_loaded_q),
	.cart_download_i(cart_download),
	.ext_bios_download_i(ext_bios_download),
	.cart_access_pulse_i(!prev_cart_rd && cart_rd),
	.save_write_pulse_i(save_wren),
	.save_pending_i(save_pending),
	.save_busy_i(save_busy),
	.serial_enable_i(serial_enable),
	.uart_rxd_i(uart_rxd_core),
	.uart_txd_i(board_txdb),
	.led_user_o(led_user),
	.led_disk_o(led_disk)
);

cache_ram_dp #(
	.ADDR_WIDTH(13),
	.DATA_WIDTH(8),
	.CROSS_PORT_FORWARD(1'b1)
) u_save_ram (
	.clk_i(clk_sys),
	.addr_a_i(save_ram_port_a_addr),
	.wren_a_i(save_ram_port_a_wren),
	.wdata_a_i(save_ram_port_a_wdata),
	.q_a_o(save_ram_hps_q),
	.addr_b_i(save_addr_hold_w),
	.wren_b_i(save_wren),
	.wdata_b_i(save_dout),
	.q_b_o(save_ram_core_q)
);

save_slot #(
	.MAX_BLOCKS(NVRAM_BLOCKS)
) u_save_slot (
	.clk_sys(clk_sys),
	.invalidate_pulse(1'b0),
	// Console storage is boot1.vhd, auto-mounted by the framework on slot 1.
	.mount_pulse(img_mounted[1]),
	.mount_readonly(img_readonly),
	.mount_size(img_mounted[1] ? img_size : save_mount_size),
	.load_req(status[9]),
	.save_req(status[10]),
	.autosave_disable(status[13]),
	.osd_status(OSD_STATUS),
	.dirty_pulse(save_wren),
	.mounted_writable(),
	.pending(save_pending),
	.busy(save_busy),
	.loading(save_loading),
	.sd_lba(sd_lba[1]),
	.sd_rd(sd_rd[1]),
	.sd_wr(sd_wr[1]),
	.sd_ack(sd_ack[1])
);

assign sd_buff_din[0] = 8'h00;
assign sd_buff_din[1] = save_ram_hps_q;

assign DDRAM_CLK = clk_sys;

ddram u_savestate_ddram (
	.DDRAM_CLK(clk_sys),
	.DDRAM_BUSY(DDRAM_BUSY),
	.DDRAM_BURSTCNT(DDRAM_BURSTCNT),
	.DDRAM_ADDR(DDRAM_ADDR),
	.DDRAM_DOUT(DDRAM_DOUT),
	.DDRAM_DOUT_READY(DDRAM_DOUT_READY),
	.DDRAM_RD(DDRAM_RD),
	.DDRAM_DIN(DDRAM_DIN),
	.DDRAM_BE(DDRAM_BE),
	.DDRAM_WE(DDRAM_WE),
	.ch1_addr({savestate_ddr_addr, 1'b0}),
	.ch1_dout(savestate_ddr_dout),
	.ch1_din(savestate_ddr_din),
	.ch1_req(savestate_ddr_req),
	.ch1_rnw(savestate_ddr_rnw),
	.ch1_be(savestate_ddr_be),
	.ch1_ready(savestate_ddr_ack)
);

savestate_ui #(
	.INFO_TIMEOUT_BITS(25)
) u_savestate_ui (
	.clk(clk_sys),
	.ps2_key(ps2_key),
	.allow_ss(savestate_menu_enabled),
	// Directions come from joystick_0 raw: the chord must see exactly the
	// presses that dpad_enable is keeping out of the console.
	.joySS(savestate_chord),
	.joyRight(joystick_0[0]),
	.joyLeft(joystick_0[1]),
	.joyDown(joystick_0[2]),
	.joyUp(joystick_0[3]),
	.joyStart(1'b0),
	.joySaveState(savestate_chord),
	.status_slot(status[46:45]),
	.OSD_saveload(status[43:42]),
	.ss_save(savestate_ui_save),
	.ss_load(savestate_ui_load),
	.ss_info_req(savestate_info_req),
	.ss_info(savestate_info),
	.statusUpdate(savestate_status_update),
	.selected_slot(savestate_slot)
);

statemanager #(
	.Softmap_SaveState_ADDR(GAMECOM_SAVESTATE_BASE),
	.Softmap_Rewind_ADDR(GAMECOM_REWIND_BASE),
	.SAVESTATE_SHIFT(GAMECOM_SAVESTATE_SLOT_SHIFT)
) u_statemanager (
	.clk(clk_sys),
	.reset(reset),
	.rewind_on(1'b0),
	.rewind_active(1'b0),
	.savestate_number({30'd0, savestate_slot}),
	.save(savestate_ui_save),
	.load(savestate_ui_load),
	.sleep_rewind(),
	.vsync(VSync),
	.request_savestate(savestate_savestate),
	.request_loadstate(savestate_loadstate),
	.request_address(savestate_address),
	.request_busy(savestate_busy)
);

savestates #(
	.STATESIZE_PARAM(GAMECOM_SAVESTATE_SIZE),
	.SETTLECOUNT_PARAM(16),
	.INTERNALSCOUNT_PARAM(GAMECOM_SS_INTERNAL_WORDS),
	.SAVETYPESCOUNT_PARAM(5),
	.SAVETYPE0_OFFSET(25'd0),
	.SAVETYPE1_OFFSET(25'd0),
	.SAVETYPE2_OFFSET(25'd0),
	.SAVETYPE3_OFFSET(25'd0),
	.SAVETYPE4_OFFSET(25'd0),
	.SAVETYPE0_SIZE(NVRAM_BYTES),
	.SAVETYPE1_SIZE(256),
	.SAVETYPE2_SIZE(8192),
	.SAVETYPE3_SIZE(8192),
	.SAVETYPE4_SIZE(GAMECOM_SS_CPU_STATE_BYTES)
) u_savestates (
	.clk(clk_sys),
	.reset_in(reset),
	.reset_ss(),
	.reset_delay(),
	.load_done(),
	.increaseSSHeaderCount(!status[44]),
	.save(savestate_savestate),
	.load(savestate_loadstate),
	.savestate_address(savestate_address),
	.savestate_busy(savestate_busy),
	.paused(savestate_pause_active_q),
	.BUS_Din(),
	.BUS_Adr(),
	.BUS_wren(),
	.BUS_rst(),
	.BUS_Dout(SaveStateBus_Dout),
	.loading_savestate(loading_savestate),
	.saving_savestate(saving_savestate),
	.sleep_savestate(sleep_savestate),
	.Save_RAMAddr(Savestate_RAMAddr),
	.Save_RAMRdEn(Savestate_RAMRdEn),
	.Save_RAMWrEn(Savestate_RAMWrEn),
	.Save_RAMWriteData(Savestate_RAMWriteData),
	.Save_RAMReadData(Savestate_RAMReadData),
	.Save_RAMType(Savestate_RAMType),
	.bus_out_Din(savestate_ddr_din),
	.bus_out_Dout(savestate_ddr_dout),
	.bus_out_Adr(savestate_ddr_addr),
	.bus_out_rnw(savestate_ddr_rnw),
	.bus_out_ena(savestate_ddr_req),
	.bus_out_be(savestate_ddr_be),
	.bus_out_done(savestate_ddr_ack)
);

cache_ram #(
	.ADDR_WIDTH(18),
	.DATA_WIDTH(8)
) u_ext_bios (
	.clk_i(clk_sys),
	.addr_i(ext_bios_addr_hold_w),
	.wren_i(ext_bios_wr),
	.wdata_i(ioctl_dout),
	.q_o(ext_bios_data)
);

sdram u_cart_sdram (
	.init(!pll_locked),
	.clk(clk_ram),
	.SDRAM_DQ(SDRAM_DQ),
	.SDRAM_A(SDRAM_A),
	.SDRAM_DQML(SDRAM_DQML),
	.SDRAM_DQMH(SDRAM_DQMH),
	.SDRAM_BA(SDRAM_BA),
	.SDRAM_nCS(SDRAM_nCS),
	.SDRAM_nWE(SDRAM_nWE),
	.SDRAM_nRAS(SDRAM_nRAS),
	.SDRAM_nCAS(SDRAM_nCAS),
	.SDRAM_CKE(SDRAM_CKE),
	.SDRAM_CLK(SDRAM_CLK),
	.ch0_addr(cart_sdram_addr_w),
	.ch0_rd(cart_sdram_rd_w),
	.ch0_wr(cart_sdram_we_w),
	.ch0_din(cart_sdram_din_w),
	.ch0_dout(cart_sdram_dout),
	.ch0_busy(cart_sdram_busy),
	.ch1_addr(25'd0),
	.ch1_rd(1'b0),
	.ch1_wr(1'b0),
	.ch1_din(8'h00),
	.ch1_dout(),
	.ch1_busy(),
	.ch2_addr(25'd0),
	.ch2_rd(1'b0),
	.ch2_wr(1'b0),
	.ch2_din(8'h00),
	.ch2_dout(),
	.ch2_busy(),
	.refresh(cart_sdram_refresh_w),
	.refresh_issued(cart_sdram_refresh_seen_w),
	.ss_in(16'h0000),
	.ss_load(1'b0),
	.ss_out()
);

always @(posedge clk_sys) begin
	if (system_reset || !sleep_savestate) begin
		savestate_pause_active_q <= 1'b0;
	end else if (savestate_pause_ready) begin
		savestate_pause_active_q <= 1'b1;
	end
end

always @(posedge clk_sys) begin
	prev_cart_rd <= cart_rd;
	cart1_download_r <= cart1_download;
	cart2_download_r <= cart2_download;
	ext_bios_download_r <= ext_bios_download;
	palette_download_r <= palette_download;

	if (!pll_locked) begin
		cart1_download_r <= 1'b0;
		cart2_download_r <= 1'b0;
		ext_bios_download_r <= 1'b0;
		cart1_loaded_q <= 1'b0;
		cart2_loaded_q <= 1'b0;
		cart_sdram_refresh_div_q <= 8'd0;
		cart_sdram_refresh_pending_q <= 1'b0;
		cart1_seen_write_q <= 1'b0;
		cart2_seen_write_q <= 1'b0;
		custom_palette_q <= DEFAULT_CUSTOM_PALETTE;
		custom_palette_load_q <= 88'd0;
		palette_download_byte_count_q <= 4'd0;
		ext_bios_loaded_q <= 1'b0;
		ext_bios_seen_wr_q <= 1'b0;
		touch_cursor_idle_q <= 26'd0;
		touch_cursor_prev_x_q <= 4'd5;
		touch_cursor_prev_y_q <= 4'd4;
		touch_cursor_visible_q <= 1'b0;
		warm_boot_hold_q <= 5'd0;
		slot1_addr_mask_q <= 24'd0;
		slot2_addr_mask_q <= 24'd0;
		ext_bios_addr_q <= 18'd0;
		save_addr_q <= 13'd0;
	end else begin
		if (cold_reset_request || ext_bios_download || save_loading || !ext_bios_loaded_q) begin
			warm_boot_hold_q <= 5'd0;
		end else if (warm_reset_request) begin
			warm_boot_hold_q <= WARM_BOOT_HOLD_CYCLES;
		end else if (warm_boot_hold_q != 5'd0) begin
			warm_boot_hold_q <= warm_boot_hold_q - 5'd1;
		end

		if (ext_bios_port_active_w) begin
			ext_bios_addr_q <= ext_bios_addr_hold_w;
		end
		if (save_port_active_w) begin
			save_addr_q <= save_addr;
		end
		if (cart_sdram_refresh_seen_w) begin
			cart_sdram_refresh_div_q <= 8'd0;
			cart_sdram_refresh_pending_q <= 1'b0;
		end else if (!cart_sdram_refresh_pending_q) begin
			if (cart_sdram_refresh_div_q == SDRAM_REFRESH_PERIOD) begin
				cart_sdram_refresh_div_q <= 8'd0;
				cart_sdram_refresh_pending_q <= 1'b1;
			end else begin
				cart_sdram_refresh_div_q <= cart_sdram_refresh_div_q + 8'd1;
			end
		end

		if (!show_touch_cursor) begin
			touch_cursor_idle_q <= 26'd0;
			touch_cursor_prev_x_q <= touch_x;
			touch_cursor_prev_y_q <= touch_y;
			touch_cursor_visible_q <= 1'b0;
		end else if ((touch_x != touch_cursor_prev_x_q) || (touch_y != touch_cursor_prev_y_q)) begin
			touch_cursor_idle_q <= 26'd0;
			touch_cursor_prev_x_q <= touch_x;
			touch_cursor_prev_y_q <= touch_y;
			touch_cursor_visible_q <= 1'b1;
		end else begin
			if (touch_cursor_idle_q != TOUCH_CURSOR_IDLE_CLKS) begin
				touch_cursor_idle_q <= touch_cursor_idle_q + 26'd1;
			end
			if (touch_cursor_idle_q >= (TOUCH_CURSOR_IDLE_CLKS - 26'd1)) begin
				touch_cursor_visible_q <= 1'b0;
			end else begin
				touch_cursor_visible_q <= 1'b1;
			end
		end

		if (!ext_bios_download_r && ext_bios_download) begin
			ext_bios_loaded_q <= 1'b0;
			ext_bios_seen_wr_q <= 1'b0;
		end else if (ext_bios_download && ext_bios_wr) begin
			ext_bios_seen_wr_q <= 1'b1;
		end else if (ext_bios_download_r && !ext_bios_download && ext_bios_seen_wr_q) begin
			ext_bios_loaded_q <= 1'b1;
		end

		if (palette_download && !palette_download_r) begin
			custom_palette_load_q <= 88'd0;
			palette_download_byte_count_q <= 4'd0;
		end
		if (palette_download && ioctl_wr) begin
			if (!palette_download_r) begin
				custom_palette_load_q <= {80'd0, ioctl_dout};
				palette_download_byte_count_q <= 4'd1;
			end else if (palette_download_byte_count_q < GAMECOM_PALETTE_COLOR_BYTES) begin
				palette_download_byte_count_q <= palette_download_byte_count_q + 4'd1;

				if (palette_download_byte_count_q < (GBP_PALETTE_FOUR_COLOR_BYTES - 4'd1)) begin
					custom_palette_load_q <= {custom_palette_load_q[79:0], ioctl_dout};
				end else if (palette_download_byte_count_q ==
					(GBP_PALETTE_FOUR_COLOR_BYTES - 4'd1)) begin
					// Commit a conventional twelve-byte GBP palette immediately
					// and mark its absent fifth color with zero. Extended Game.com
					// palettes may replace that sentinel with bytes twelve to
					// fourteen; a sixteenth payload byte remains ignored.
					custom_palette_q <= {custom_palette_load_q, ioctl_dout, 24'h000000};
				end else begin
					case (palette_download_byte_count_q)
						4'd12: custom_palette_q[23:16] <= ioctl_dout;
						4'd13: custom_palette_q[15:8] <= ioctl_dout;
						default: custom_palette_q[7:0] <= ioctl_dout;
					endcase
				end
			end
		end

		if (!cart1_download_r && cart1_download) begin
			cart1_loaded_q <= 1'b0;
			cart1_seen_write_q <= 1'b0;
			slot1_addr_mask_q <= 24'd0;
		end

		if (!cart2_download_r && cart2_download) begin
			cart2_loaded_q <= 1'b0;
			cart2_seen_write_q <= 1'b0;
			slot2_addr_mask_q <= 24'd0;
		end

		if (cart_sdram_we_w) begin
			if (cart1_sdram_we_w) begin
				cart1_seen_write_q <= 1'b1;
				// Build the slot-local ROM mirror mask from the address bits that
				// were actually exercised during download, instead of assuming the
				// final write address alone fully describes the chip size.
				slot1_addr_mask_q <= slot1_addr_mask_q | ioctl_addr[23:0];
			end
			if (cart2_sdram_we_w) begin
				cart2_seen_write_q <= 1'b1;
				slot2_addr_mask_q <= slot2_addr_mask_q | ioctl_addr[23:0];
			end
		end else if (cart1_download_r && !cart1_download && cart1_seen_write_q) begin
			cart1_loaded_q <= 1'b1;
		end else if (cart2_download_r && !cart2_download && cart2_seen_write_q) begin
			cart2_loaded_q <= 1'b1;
		end
	end
end

GameCom GameCom (
	.clk_sys(clk_sys),
	.phi0(phi0_core),
	.clk_vid(clk_vid),
	.phi1(phi1_core),
	.reset(reset),
	.stop_disable_i(stop_disable),
	.warm_boot_i(warm_boot_effective),
	.video_reset_i(system_reset),
	.cart_din_i(cart_din),
	.rom_read_ready_i(rom_read_ready_w),
	.uart_rxd_i(uart_rxd_core),
	.uart_cts_i(uart_cts_core),
	.uart_dsr_i(uart_dsr_core),
	.buttons_i({
		button_power,
		button_pause,
		button_d,
		button_c,
		button_b,
		button_a,
		button_sound,
		button_menu,
		button_right,
		button_left,
		button_down,
		button_up
	}),
	.touch_active_i(touch_active),
	.touch_x_i(touch_x),
	.touch_y_i(touch_y),
	.video_60hz_i(video_60hz),
	.palette_four_color_i(palette_four_color_w),
	.cursor_enable_i(touch_cursor_enable),
	.cursor_x_i(touch_x),
	.cursor_y_i(touch_y),
	.save_din_i(save_ram_core_q),
	.rtc_i(rtc),
	.savestate_pause_req_i(sleep_savestate),
	.savestate_mem_active_i(savestate_core_mem_active),
	.savestate_mem_type_i(Savestate_RAMType),
	.savestate_mem_addr_i(Savestate_RAMAddr),
	.savestate_mem_rd_i(Savestate_RAMRdEn),
	.savestate_mem_wr_i(Savestate_RAMWrEn),
	.savestate_mem_wdata_i(Savestate_RAMWriteData),
	.cheat_clear_i(cheat_clear_w),
	.cheat_code_i(cheat_code_w),

	.ce_pix(ce_pix),

	.HBlank(HBlank),
	.HSync(HSync),
	.VBlank(VBlank),
	.VSync(VSync),

	.shade(shade),

	.cart_addr_o(cart_addr),
	.cart_dout_o(),
	.cart_doe_o(),
	.cart_rd_o(cart_rd),
	.cart_wr_o(cart_wr),
	.cart_slot1_sel_o(cart_slot1_sel),
	.cart_slot2_sel_o(cart_slot2_sel),
	.save_addr_o(save_addr),
	.save_dout_o(save_dout),
	.save_rd_o(save_rd),
	.save_wren_o(save_wren),

	.cpu_sound_o(),
	.audio_pcm_o(board_audio),
	.cpu_txdb_o(board_txdb),
	.cpu_lcd_clk_o(),
	.cpu_doffb_o(),
	.uart_rts_o(board_uart_rts),
	.uart_dtr_o(board_uart_dtr),
	.savestate_pause_ready_o(savestate_pause_ready),
	.savestate_mem_rdata_o(core_savestate_mem_rdata)
);

assign UART_RTS = serial_internal_enable ? board_uart_rts : 1'b1;
assign UART_DTR = serial_internal_enable ? board_uart_dtr : 1'b1;
assign UART_TXD = serial_internal_enable ? board_txdb : 1'b1;
// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: SNAC serial route owns USER_IO while enabled, joydb drives it otherwise
assign USER_OUT = serial_snac_enable ? {
	1'b1,           // USER_IO[7]: unused
// [MiSTer-DB9 END]
	1'b1,           // USER_IO[6]: unused
	board_uart_dtr, // USER_IO[5]: DTR output
	1'b1,           // USER_IO[4]: DSR input
	board_uart_rts, // USER_IO[3]: RTS output
	1'b1,           // USER_IO[2]: CTS input
	board_txdb,     // USER_IO[1]: TXD output
	1'b1            // USER_IO[0]: RXD input
// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: selector-Off fall-through to the joydb wrapper
} : USER_OUT_DRIVE;
// [MiSTer-DB9 END]

assign AUDIO_S = 1'b0;
assign AUDIO_L = board_audio;
assign AUDIO_R = board_audio;
assign AUDIO_MIX = 2'b00;

assign CLK_VIDEO = clk_vid;

video_mixer #(
	.LINE_LENGTH(204),
	.HALF_DEPTH(1'b0),
	.GAMMA(1'b1)
) u_video_mixer (
	.CLK_VIDEO(CLK_VIDEO),
	.CE_PIXEL(CE_PIXEL),
	.ce_pix(ce_pix),
	.scandoubler((scale != 3'd0) || forced_scandoubler),
	.hq2x(scale == 3'd1),
	.gamma_bus(gamma_bus),
	.R(video_rgb[23:16]),
	.G(video_rgb[15:8]),
	.B(video_rgb[7:0]),
	.HSync(HSync),
	.VSync(VSync),
	.HBlank(HBlank),
	.VBlank(VBlank),
	.HDMI_FREEZE(HDMI_FREEZE),
	.freeze_sync(),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.VGA_DE(vga_de)
);

// The LCD has no overscan to trim, so only the integer scaling is offered.
video_freak u_video_freak (
	.CLK_VIDEO(CLK_VIDEO),
	.CE_PIXEL(CE_PIXEL),
	.VGA_VS(VGA_VS),
	.HDMI_WIDTH(HDMI_WIDTH),
	.HDMI_HEIGHT(HDMI_HEIGHT),
	.VGA_DE(VGA_DE),
	.VIDEO_ARX(VIDEO_ARX),
	.VIDEO_ARY(VIDEO_ARY),
	.VGA_DE_IN(vga_de),
	.ARX(video_arx),
	.ARY(video_ary),
	.CROP_SIZE(12'd0),
	.CROP_OFF(5'd0),
	.SCALE(video_scale)
);

assign LED_DISK = led_disk;
assign LED_POWER = 2'b00;
assign LED_USER = led_user;

endmodule
