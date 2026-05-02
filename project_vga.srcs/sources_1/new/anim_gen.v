`timescale 1ns / 1ps

module anim_gen (
    input  wire       clk,
    input  wire       video_on,
    input  wire [9:0] pixel_x,
    input  wire [9:0] pixel_y,
    input  wire       sw_mode,
    input  wire       alarm_en,
    input  wire       alarm_active,
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
    wire text_shadow_on;
    wire colon_on;
    wire colon_shadow_on;
    wire [3:0] hour_tens;
    wire [3:0] hour_ones;
    wire [3:0] min_tens;
    wire [3:0] min_ones;
    wire [3:0] sec_tens;
    wire [3:0] sec_ones;
    wire status_bar_on;
    wire status_line_on;
    wire mode_accent_on;
    wire alarm_dot_on;
    wire alarm_flash;

    wire [7:0] str_char_code;
    wire [3:0] str_row_idx;
    wire [7:0] str_row_data;
    wire       str_on;

    // 字库实例化
    font_rom u_font_rom (
        .clk      (clk),
        .char_code(str_char_code),
        .row_idx  (str_row_idx),
        .row_data (str_row_data)
    );

    // 字符串渲染参数: 放大比例(比如8倍大小, 每个字符64x128像素)
    localparam STR_SCALE = 2;
    localparam STR_TOP   = 10'd2;
    localparam STR_LEFT  = 10'd420;

    assign status_bar_on  = (pixel_y < 10'd28);
    assign status_line_on = 1'b0;
    assign mode_accent_on = (pixel_x < 10'd8) && status_bar_on;
    assign alarm_dot_on   = circle_pixel(pixel_x, pixel_y, 10'd604, 10'd14, 10'd6);
    assign alarm_flash    = alarm_active && sec[0];

    // 字符选择逻辑
    // ALARM (A=65, L=76, A=65, R=82, M=77)
    // CLOCK (C=67, L=76, O=79, C=67, K=75)
    reg [7:0] char_selected;
    always @(*) begin
        if (sw_mode == 1'b1) begin // ALARM
            case ((pixel_x - STR_LEFT) / (STR_SCALE * 8))
                0: char_selected = 8'd65; // A
                1: char_selected = 8'd76; // L
                2: char_selected = 8'd65; // A
                3: char_selected = 8'd82; // R
                4: char_selected = 8'd77; // M
                default: char_selected = 8'd32; // 空格
            endcase
        end else begin // CLOCK
            case ((pixel_x - STR_LEFT) / (STR_SCALE * 8))
                0: char_selected = 8'd67; // C
                1: char_selected = 8'd76; // L
                2: char_selected = 8'd79; // O
                3: char_selected = 8'd67; // C
                4: char_selected = 8'd75; // K
                default: char_selected = 8'd32; // 空格
            endcase
        end
    end

    // 确定ROM输入
    assign str_char_code = char_selected;
    assign str_row_idx = (pixel_y - STR_TOP) / STR_SCALE;

    // 判断当前像素是否在字符串区域内并且对应的像素为1
    wire [9:0] str_col_idx;
    assign str_col_idx = (pixel_x - STR_LEFT) / STR_SCALE;

    assign str_on = (pixel_x >= STR_LEFT) && (pixel_x < STR_LEFT + 5 * 8 * STR_SCALE) &&
                    (pixel_y >= STR_TOP)  && (pixel_y < STR_TOP + 16 * STR_SCALE) &&
                    str_row_data[str_col_idx % 8];

    assign hour_tens = hour / 10;
    assign hour_ones = hour % 10;
    assign min_tens  = min / 10;
    assign min_ones  = min % 10;
    assign sec_tens  = sec / 10;
    assign sec_ones  = sec % 10;

    assign colon_on = colon_pixel(pixel_x, pixel_y, 10'd212, 10'd200) ||
                      colon_pixel(pixel_x, pixel_y, 10'd335, 10'd200);

    assign colon_shadow_on = colon_pixel(pixel_x, pixel_y, 10'd216, 10'd204) ||
                             colon_pixel(pixel_x, pixel_y, 10'd339, 10'd204);

    assign text_on = digit_pixel(pixel_x, pixel_y, 10'd112, 10'd200, hour_tens) ||
                     digit_pixel(pixel_x, pixel_y, 10'd160, 10'd200, hour_ones) ||
                     digit_pixel(pixel_x, pixel_y, 10'd235, 10'd200, min_tens)  ||
                     digit_pixel(pixel_x, pixel_y, 10'd283, 10'd200, min_ones)  ||
                     digit_pixel(pixel_x, pixel_y, 10'd358, 10'd200, sec_tens)  ||
                     digit_pixel(pixel_x, pixel_y, 10'd406, 10'd200, sec_ones)  ||
                     colon_on;

    assign text_shadow_on = digit_pixel(pixel_x, pixel_y, 10'd116, 10'd204, hour_tens) ||
                            digit_pixel(pixel_x, pixel_y, 10'd164, 10'd204, hour_ones) ||
                            digit_pixel(pixel_x, pixel_y, 10'd239, 10'd204, min_tens)  ||
                            digit_pixel(pixel_x, pixel_y, 10'd287, 10'd204, min_ones)  ||
                            digit_pixel(pixel_x, pixel_y, 10'd362, 10'd204, sec_tens)  ||
                            digit_pixel(pixel_x, pixel_y, 10'd410, 10'd204, sec_ones)  ||
                            colon_shadow_on;

    always @(*) begin
        if (!video_on) begin
            vga_r = 4'h0;
            vga_g = 4'h0;
            vga_b = 4'h0;
        end else if (str_on) begin
            vga_r = sw_mode ? 4'hF : 4'h0;
            vga_g = sw_mode ? 4'h0 : 4'hF;
            vga_b = 4'h0;
        end else if (text_on) begin
            if (alarm_flash) begin
                vga_r = 4'hF;
                vga_g = 4'h1;
                vga_b = 4'h1;
            end else begin
                vga_r = 4'hF;
                vga_g = 4'hF;
                vga_b = 4'hF;
            end
        end else if (text_shadow_on) begin
            vga_r = 4'h5;
            vga_g = 4'h6;
            vga_b = 4'h7;
        end else if (mode_accent_on) begin
            if (sw_mode) begin
                vga_r = 4'hF;
                vga_g = 4'hB;
                vga_b = 4'h1;
            end else begin
                vga_r = 4'h2;
                vga_g = 4'hD;
                vga_b = 4'hC;
            end
        end else if (alarm_dot_on) begin
            if (alarm_flash) begin
                vga_r = 4'hF;
                vga_g = 4'h1;
                vga_b = 4'h1;
            end else if (alarm_en) begin
                vga_r = 4'h5;
                vga_g = 4'hF;
                vga_b = 4'h7;
            end else begin
                vga_r = 4'h5;
                vga_g = 4'h6;
                vga_b = 4'h7;
            end
        end else if (status_line_on) begin
            vga_r = 4'hB;
            vga_g = 4'hC;
            vga_b = 4'hD;
        end else if (status_bar_on) begin
            if (alarm_flash) begin
                vga_r = 4'hF;
                vga_g = 4'hD;
                vga_b = 4'hD;
            end else begin
                vga_r = 4'hE;
                vga_g = 4'hF;
                vga_b = 4'hF;
            end
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
            a = seg[6] && (lx >= 10'd6)  && (lx < 10'd36) && (ly < 10'd6);
            b = seg[5] && (lx >= 10'd36) && (lx < 10'd42) && (ly >= 10'd6)  && (ly < 10'd36);
            c = seg[4] && (lx >= 10'd36) && (lx < 10'd42) && (ly >= 10'd42) && (ly < 10'd72);
            d = seg[3] && (lx >= 10'd6)  && (lx < 10'd36) && (ly >= 10'd72) && (ly < 10'd78);
            e = seg[2] && (lx < 10'd6)   && (ly >= 10'd42) && (ly < 10'd72);
            f = seg[1] && (lx < 10'd6)   && (ly >= 10'd6)  && (ly < 10'd36);
            g = seg[0] && (lx >= 10'd6)  && (lx < 10'd36) && (ly >= 10'd36) && (ly < 10'd42);
            digit_pixel = (px >= left) && (px < left + 10'd42) &&
                          (py >= top)  && (py < top + 10'd78) &&
                          (a || b || c || d || e || f || g);
        end
    endfunction

    function circle_pixel;
        input [9:0] px;
        input [9:0] py;
        input [9:0] cx;
        input [9:0] cy;
        input [9:0] radius;
        reg signed [10:0] dx;
        reg signed [10:0] dy;
        reg [21:0] dist2;
        reg [21:0] radius2;
        begin
            dx = $signed({1'b0, px}) - $signed({1'b0, cx});
            dy = $signed({1'b0, py}) - $signed({1'b0, cy});
            dist2 = dx * dx + dy * dy;
            radius2 = radius * radius;
            circle_pixel = dist2 <= radius2;
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
                          (py >= top)  && (py < top + 10'd78) &&
                          (((lx >= 10'd2) && (lx < 10'd10) && (ly >= 10'd20) && (ly < 10'd28)) ||
                           ((lx >= 10'd2) && (lx < 10'd10) && (ly >= 10'd48) && (ly < 10'd56)));
        end
    endfunction
endmodule
