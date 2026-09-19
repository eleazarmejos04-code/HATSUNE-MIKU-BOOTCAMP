/*
 * Copyright (c) 2024-2025 James Ross
 * SPDX-License-Identifier: Apache-2.0
 *
 * VGA top level (640x480) driving a dancing pixel idol.
 * ui_in[1:0] : colour scheme      ui_in[7:6] : VGA mode (sprite is laid out for mode 0)
 */

`default_nettype none

module tt_um_vga_glyph_mode(
	input  wire [7:0] ui_in,    // Dedicated inputs
	output wire [7:0] uo_out,   // Dedicated outputs
	input  wire [7:0] uio_in,   // IOs: Input path
	output wire [7:0] uio_out,  // IOs: Output path
	output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
	input  wire       ena,      // always 1 when the design is powered, so you can ignore it
	input  wire       clk,      // clock
	input  wire       rst_n     // reset_n - low to reset
);

	// VGA signals
	wire hsync, vsync, display_on;
	wire [10:0] hpos;
	wire [9:0] vpos;
	wire [5:0] RGB;

	// TinyVGA PMOD
	assign uo_out = {hsync, RGB[0], RGB[2], RGB[4], vsync, RGB[1], RGB[3], RGB[5]};

	// Unused outputs assigned to 0.
	assign uio_out = 0;
	assign uio_oe  = 0;

	// Suppress unused signals warning
	wire _unused_ok = &{ena, ui_in[5:2], uio_in, hpos[10], hpos[2:0], vpos[2:0]};

	// One animation tick per video frame (60 Hz)
	reg [7:0] frame;

	always @(posedge vsync, negedge rst_n) begin
		if (~rst_n)
			frame <= 0;
		else
			frame <= frame + 1;
	end

	// VGA output
	hvsync_generator hvsync_gen(
		.clk(clk),
		.reset(~rst_n),
		.mode(ui_in[7:6]),
		.hsync(hsync),
		.vsync(vsync),
		.display_on(display_on),
		.hpos(hpos),
		.vpos(vpos)
	);

	// Dancer: 8x8-pixel "fat pixels" -> 80x60 grid
	wire [5:0] dancer_rgb;
	dancer dancer_inst(
		.gx(hpos[9:3]),
		.gy(vpos[9:3]),
		.frame(frame),
		.pal(ui_in[1:0]),
		.rgb(dancer_rgb)
	);

	assign RGB = display_on ? dancer_rgb : 6'd0;

endmodule
