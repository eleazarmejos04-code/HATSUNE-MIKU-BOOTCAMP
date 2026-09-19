/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_vga_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs (TinyVGA mapping)
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path
    input  wire       ena,      // Will go high when the design is enabled
    input  wire       clk,      // Clock (typically 25.175 MHz for 640x480)
    input  wire       rst_n     // Active-low reset
);

    // Drive unused bidirectional outputs low
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    wire reset = ~rst_n;

    // 640x480 @ 60Hz timing constants
    localparam H_VISIBLE = 640, H_FRONT = 16, H_SYNC = 96,  H_TOTAL = 800;
    localparam V_VISIBLE = 480, V_FRONT = 10, V_SYNC = 2,   V_TOTAL = 525;

    reg [9:0] h_count;
    reg [9:0] v_count;

    // Pixel coordinate counters
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            h_count <= 10'd0;
            v_count <= 10'd0;
        end else begin
            if (h_count == H_TOTAL - 1) begin
                h_count <= 10'd0;
                if (v_count == V_TOTAL - 1)
                    v_count <= 10'd0;
                else
                    v_count <= v_count + 1'b1;
            end else begin
                h_count <= h_count + 1'b1;
            end
        end
    end

    // Sync pulses (active low)
    wire hsync = ~((h_count >= (H_VISIBLE + H_FRONT)) && (h_count < (H_VISIBLE + H_FRONT + H_SYNC)));
    wire vsync = ~((v_count >= (V_VISIBLE + V_FRONT)) && (v_count < (V_VISIBLE + V_FRONT + V_SYNC)));
    wire display_on = (h_count < H_VISIBLE) && (v_count < V_VISIBLE);

    // Simple pattern: colored vertical bands
    wire [1:0] red   = display_on ? h_count[7:6] : 2'b00;
    wire [1:0] green = display_on ? v_count[7:6] : 2'b00;
    wire [1:0] blue  = display_on ? (h_count[5:4] ^ v_count[5:4]) : 2'b00;

    // Map to TinyVGA PMOD pinout
    assign uo_out[0] = red[1];
    assign uo_out[4] = red[0];
    assign uo_out[1] = green[1];
    assign uo_out[5] = green[0];
    assign uo_out[2] = blue[1];
    assign uo_out[6] = blue[0];
    assign uo_out[3] = vsync;
    assign uo_out[7] = hsync;

endmodule
