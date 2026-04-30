`timescale 1ns / 1ps

module anim_gen (
    input  wire       video_on,
    input  wire [9:0] pixel_x,
    input  wire [9:0] pixel_y,
    input  wire [4:0] hour,
    input  wire [5:0] min,
    input  wire [5:0] sec,
    input  wire [3:0] bg_r,
    input  wire [3:0] bg_g,
    input  wire [3:0] bg_b,
    output reg  [3:0] vga_r,
    output reg  [3:0] vga_g,
    output reg  [3:0] vga_b
);
    wire text_on;
    wire colon_on;
    wire [3:0] hour_tens;
    wire [3:0] hour_ones;
    wire [3:0] min_tens;
    wire [3:0] min_ones;
    wire [3:0] sec_tens;
    wire [3:0] sec_ones;

    assign hour_tens = hour / 10;
    assign hour_ones = hour % 10;
    assign min_tens  = min / 10;
    assign min_ones  = min % 10;
    assign sec_tens  = sec / 10;
    assign sec_ones  = sec % 10;

    assign colon_on = colon_pixel(pixel_x, pixel_y, 10'd218, 10'd190) ||
                      colon_pixel(pixel_x, pixel_y, 10'd382, 10'd190);

    assign text_on = digit_pixel(pixel_x, pixel_y, 10'd80,  10'd190, hour_tens) ||
                     digit_pixel(pixel_x, pixel_y, 10'd144, 10'd190, hour_ones) ||
                     digit_pixel(pixel_x, pixel_y, 10'd244, 10'd190, min_tens)  ||
                     digit_pixel(pixel_x, pixel_y, 10'd308, 10'd190, min_ones)  ||
                     digit_pixel(pixel_x, pixel_y, 10'd408, 10'd190, sec_tens)  ||
                     digit_pixel(pixel_x, pixel_y, 10'd472, 10'd190, sec_ones)  ||
                     colon_on;

    always @(*) begin
        if (!video_on) begin
            vga_r = 4'h0;
            vga_g = 4'h0;
            vga_b = 4'h0;
        end else if (text_on) begin
            vga_r = 4'h0;
            vga_g = 4'h0;
            vga_b = 4'hF;
        end else begin
            vga_r = bg_r;
            vga_g = bg_g;
            vga_b = bg_b;
        end
    end

    function [6:0] digit_segments;
        input [3:0] digit;
        begin
            case (digit)
                4'd0: digit_segments = 7'b1111110;
                4'd1: digit_segments = 7'b0110000;
                4'd2: digit_segments = 7'b1101101;
                4'd3: digit_segments = 7'b1111001;
                4'd4: digit_segments = 7'b0110011;
                4'd5: digit_segments = 7'b1011011;
                4'd6: digit_segments = 7'b1011111;
                4'd7: digit_segments = 7'b1110000;
                4'd8: digit_segments = 7'b1111111;
                4'd9: digit_segments = 7'b1111011;
                default: digit_segments = 7'b0000000;
            endcase
        end
    endfunction

    function digit_pixel;
        input [9:0] px;
        input [9:0] py;
        input [9:0] left;
        input [9:0] top;
        input [3:0] digit;
        reg [9:0] lx;
        reg [9:0] ly;
        reg [6:0] seg;
        reg a;
        reg b;
        reg c;
        reg d;
        reg e;
        reg f;
        reg g;
        begin
            lx = px - left;
            ly = py - top;
            seg = digit_segments(digit);
            a = seg[6] && (lx >= 10'd8)  && (lx < 10'd48) && (ly < 10'd8);
            b = seg[5] && (lx >= 10'd48) && (lx < 10'd56) && (ly >= 10'd8)  && (ly < 10'd48);
            c = seg[4] && (lx >= 10'd48) && (lx < 10'd56) && (ly >= 10'd56) && (ly < 10'd96);
            d = seg[3] && (lx >= 10'd8)  && (lx < 10'd48) && (ly >= 10'd96) && (ly < 10'd104);
            e = seg[2] && (lx < 10'd8)   && (ly >= 10'd56) && (ly < 10'd96);
            f = seg[1] && (lx < 10'd8)   && (ly >= 10'd8)  && (ly < 10'd48);
            g = seg[0] && (lx >= 10'd8)  && (lx < 10'd48) && (ly >= 10'd48) && (ly < 10'd56);
            digit_pixel = (px >= left) && (px < left + 10'd56) &&
                          (py >= top)  && (py < top + 10'd104) &&
                          (a || b || c || d || e || f || g);
        end
    endfunction

    function colon_pixel;
        input [9:0] px;
        input [9:0] py;
        input [9:0] left;
        input [9:0] top;
        reg [9:0] lx;
        reg [9:0] ly;
        begin
            lx = px - left;
            ly = py - top;
            colon_pixel = (px >= left) && (px < left + 10'd12) &&
                          (py >= top)  && (py < top + 10'd104) &&
                          (((lx >= 10'd2) && (lx < 10'd10) && (ly >= 10'd28) && (ly < 10'd40)) ||
                           ((lx >= 10'd2) && (lx < 10'd10) && (ly >= 10'd64) && (ly < 10'd76)));
        end
    endfunction
endmodule
