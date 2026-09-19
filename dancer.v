/*
 * SPDX-License-Identifier: Apache-2.0
 *
 * Procedural dancing pixel idol.
 *
 * No sprite ROM: the character is built from rectangles / diagonal lines in
 * an 80x60 grid of 8x8-pixel "fat pixels" (640x480 VGA), so it costs a few
 * hundred gates instead of kilobits of ROM.  Everything is symmetric around
 * column 40; per-side animation state (arm pose, tail sway, raised leg) is
 * picked from `left`, which is what makes the two sides dance out of phase.
 *
 * Layers are painted back-to-front by overwriting `col`.
 */

`default_nettype none

module dancer (
    input  wire [6:0] gx,     // fat-pixel column  (hpos[9:3])
    input  wire [6:0] gy,     // fat-pixel row     (vpos[9:3])
    input  wire [7:0] frame,  // frame counter, +1 per vsync
    input  wire [1:0] pal,    // colour scheme
    output reg  [5:0] rgb     // RRGGBB
);

    // ---------------------------------------------------------------- colours
    localparam [5:0] C_SKIN   = 6'b111010;
    localparam [5:0] C_EYE    = 6'b010001;
    localparam [5:0] C_WHITE  = 6'b111111;
    localparam [5:0] C_BLUSH  = 6'b110101;
    localparam [5:0] C_MOUTH  = 6'b110000;
    localparam [5:0] C_MOUTHO = 6'b100000;
    localparam [5:0] C_BG     = 6'b000001;
    localparam [5:0] C_FLOORB = 6'b000010;

    reg [5:0] c_hair, c_hilite, c_top, c_acc;
    always @(*) begin
        case (pal)
            2'd0:    begin c_hair = 6'b110010; c_hilite = 6'b111011; c_top = 6'b111111; c_acc = 6'b111100; end // magenta / white / yellow
            2'd1:    begin c_hair = 6'b111000; c_hilite = 6'b111100; c_top = 6'b010011; c_acc = 6'b111111; end // orange / indigo / white
            2'd2:    begin c_hair = 6'b011100; c_hilite = 6'b101101; c_top = 6'b010001; c_acc = 6'b110000; end // lime / plum / red
            default: begin c_hair = 6'b101010; c_hilite = 6'b111111; c_top = 6'b110000; c_acc = 6'b111100; end // silver / red / gold
        endcase
    end

    // ------------------------------------------------------------ coordinates
    wire [8:0] dx   = {2'b00, gx} - 9'd40;        // centre the sprite on column 40
    wire       left = dx[8];                      // viewer's-left half
    wire [8:0] adx  = left ? (9'd0 - dx) : dx;    // |dx|
    wire [7:0] ax   = adx[7:0];                   // mirrored distance from centre
    wire       bob  = frame[4];                   // hop every 16 frames
    wire [6:0] y    = gy + {6'b000000, bob};      // sprite-space row (feet at 49)

    // ------------------------------------------------------- animation state
    wire [1:0] tph   = left ? frame[5:4] : frame[5:4] + 2'd2;  // tail sway phase
    wire [2:0] aph   = left ? frame[6:4] : frame[6:4] + 3'd4;  // arm phase
    wire [1:0] pose  = aph[2] ? ~aph[1:0] : aph[1:0];          // 0 down,1 diag-dn,2 out,3 diag-up
    wire       lift  = left ? ~frame[5] : frame[5];            // raised leg
    wire       blink = (frame[6:2] == 5'd0);
    wire       mouth_open = frame[3];

    // ----------------------------------------------------------------- render
    integer iax, iy, sh, tsh, tx, hw;
    reg [5:0] col, floor_a;
    reg       arm, hand;

    always @(*) begin
        iax = ax;
        iy  = y;

        // --- background: night sky, pulsing spotlight, twinkling stars
        col = C_BG;
        if (gy < 50 && ax <= 16)
            col = frame[5] ? 6'b010010 : 6'b000110;
        if (gy < 50 && gx[2:0] == 3'd5 && gy[2:0] == 3'd2 &&
            (gx[5:3] ^ gy[5:3] ^ frame[6:4]) == 3'd0)
            col = C_WHITE;

        // --- disco floor
        case (frame[6:5])
            2'd0:    floor_a = 6'b110011;
            2'd1:    floor_a = 6'b111100;
            2'd2:    floor_a = 6'b011111;
            default: floor_a = 6'b110110;
        endcase
        if (gy >= 50)
            col = (gx[2] ^ gy[1]) ? floor_a : C_FLOORB;

        // --- twin tails (behind everything); lower sections sway more
        sh  = (tph == 2'd1) ? 1 : (tph == 2'd3) ? -1 : 0;
        tsh = (iy >= 34) ? 2 * sh : (iy >= 23) ? sh : 0;
        tx  = iax - tsh;
        if (iy >= 12 && iy <= 43 &&
            tx >= ((iy < 38) ? 8 : 9) && tx <= ((iy < 42) ? 10 : 9))
            col = (tx == 9 && iy >= 14 && iy <= 19) ? c_hilite : c_hair;
        if (iy >= 10 && iy <= 11 && iax >= 8 && iax <= 10)   // hair ties
            col = c_acc;

        // --- legs / boots (one leg kicks up, alternating)
        if (!lift) begin
            if (iy >= 39 && iy <= 47 && iax >= 1 && iax <= 3) col = C_SKIN;
            if (iy >= 48 && iy <= 49 && iax >= 1 && iax <= 4) col = c_top;
        end else begin
            if (iy >= 39 && iy <= 43 && iax >= 1 && iax <= 3) col = C_SKIN;
            if (iy >= 44 && iy <= 45 && iax >= 2 && iax <= 4) col = C_SKIN;
            if (iy >= 46 && iy <= 47 && iax >= 3 && iax <= 6) col = c_top;
        end

        // --- skirt
        if (iy == 34 && iax <= 4)                 col = c_top;
        if (iy >= 35 && iy <= 37 && iax <= 5)     col = c_top;
        if (iy == 38 && iax <= 6)                 col = c_acc;

        // --- torso, belt, neck, bow
        if (iy == 24 && iax <= 4)                 col = c_top;
        if (iy >= 25 && iy <= 32 && iax <= 3)     col = c_top;
        if (iy == 33 && iax <= 3)                 col = c_acc;
        if (iy >= 22 && iy <= 23 && iax <= 1)     col = C_SKIN;
        if ((iy == 24 || iy == 25) && iax <= 1)   col = c_acc;
        if (iy == 26 && iax == 0)                 col = c_acc;

        // --- hair: dome, fringe, side locks
        hw = (iy == 6) ? 3 : (iy == 7) ? 5 : (iy == 8) ? 6 : 7;
        if (iy >= 6  && iy <= 12 && iax <= hw)                 col = c_hair;
        if (iy == 13 && iax >= 2 && iax <= 7)                  col = c_hair;
        if ((iy == 14 || iy == 15) && iax >= 5 && iax <= 7)    col = c_hair;
        if (iy >= 16 && iy <= 23 && iax >= 6 && iax <= 7)      col = c_hair;
        if (iy == 8 && iax >= 2 && iax <= 4)                   col = c_hilite;

        // --- face
        if (iy == 13 && iax <= 1)                 col = C_SKIN;
        if ((iy == 14 || iy == 15) && iax <= 4)   col = C_SKIN;
        if (iy >= 16 && iy <= 19 && iax <= 5)     col = C_SKIN;
        if (iy == 20 && iax <= 4)                 col = C_SKIN;
        if (iy == 21 && iax <= 3)                 col = C_SKIN;

        // eyes (lash row, eye, sparkle), blush, singing mouth
        if (iy == 14 && iax >= 2 && iax <= 4)                          col = C_EYE;
        if (iax >= 2 && iax <= 3 && (iy == 16 || (iy == 15 && !blink))) col = C_EYE;
        if (iy == 15 && iax == 2 && !blink)                            col = C_WHITE;
        if (iy == 18 && iax >= 3 && iax <= 4)                          col = C_BLUSH;
        if (iy == 19 && iax <= 1)                                      col = mouth_open ? C_MOUTHO : C_MOUTH;
        if (iy == 20 && iax <= 1 && mouth_open)                        col = C_MOUTHO;

        // --- arms (in front of everything)
        arm  = 1'b0;
        hand = 1'b0;
        case (pose)
            2'd0: begin arm = (iax >= 5 && iax <= 6  && iy >= 24 && iy <= 34);       hand = (iy >= 32);  end
            2'd1: begin arm = (iax >= 5 && iax <= 13 && (iy - iax == 19 || iy - iax == 20)); hand = (iax >= 12); end
            2'd2: begin arm = (iax >= 5 && iax <= 15 && iy >= 24 && iy <= 25);       hand = (iax >= 14); end
            2'd3: begin arm = (iax >= 5 && iax <= 13 && (iy + iax == 28 || iy + iax == 29)); hand = (iax >= 12); end
        endcase
        if (arm) col = hand ? C_SKIN : c_acc;

        rgb = col;
    end

endmodule
