`timescale 1ns / 1ps

module vga_out (
    input  wire       clk,
    input  wire       rst,
    input  wire       btn_hour_up,
    input  wire       btn_hour_down,
    input  wire       btn_min_up,
    input  wire       btn_min_down,
    input  wire       sw_mode,
    input  wire       alarm_en,
    input  wire       bg_sel,
    output wire       vga_hs,
    output wire       vga_vs,
    output wire [3:0] vga_r,
    output wire [3:0] vga_g,
    output wire [3:0] vga_b,
    output wire [7:0] seg,
    output wire [7:0] an,
    output wire [3:0] led,
    inout  wire       aud_pwm
);
    wire [9:0] pixel_x;
    wire [9:0] pixel_y;
    wire       video_on;
    wire       frame_tick;
    wire       pix_clk;
    wire       clk_locked;
    wire       vga_rst;
    wire [4:0] hour;
    wire [5:0] min;
    wire [5:0] sec;
    wire [4:0] disp_hour;
    wire [5:0] disp_min;
    wire [5:0] disp_sec;
    wire       led_hourly;
    wire       led_alarm;
    wire       one_hz_tick;
    wire [3:0] bg_r;
    wire [3:0] bg_g;
    wire [3:0] bg_b;
    wire       aud_pwm_low;
    reg [24:0] pix_cnt;
    reg [5:0]  frame_cnt;
    
    assign vga_rst = rst | ~clk_locked;
    
    clk_wiz_0 u_clk_wiz_0 (
        .clk_in1  (clk),
        .clk_out1 (pix_clk),
        .reset    (rst),
        .locked   (clk_locked)
    );

    always @(posedge pix_clk) begin
        if (vga_rst) begin
            pix_cnt   <= 25'd0;
            frame_cnt <= 6'd0;
        end else begin
            pix_cnt <= pix_cnt + 25'd1;
            if (frame_tick) begin
                frame_cnt <= frame_cnt + 6'd1;
            end
        end
    end

    assign led[0] = led_hourly;
    assign led[1] = led_alarm;
    assign led[2] = pix_cnt[24];
    assign led[3] = frame_cnt[5];
    assign aud_pwm = aud_pwm_low ? 1'b0 : 1'bz;

    alarm_audio u_alarm_audio (
        .clk          (pix_clk),
        .rst          (vga_rst),
        .alarm_active (led_alarm),
        .pwm_low      (aud_pwm_low)
    );

    clock_core u_clock_core (
        .clk          (pix_clk),
        .rst          (vga_rst),
        .btn_hour_up  (btn_hour_up),
        .btn_hour_down(btn_hour_down),
        .btn_min_up   (btn_min_up),
        .btn_min_down (btn_min_down),
        .sw_mode      (sw_mode),
        .alarm_en     (alarm_en),
        .hour         (hour),
        .min          (min),
        .sec          (sec),
        .disp_hour    (disp_hour),
        .disp_min     (disp_min),
        .disp_sec     (disp_sec),
        .led_hourly   (led_hourly),
        .led_alarm    (led_alarm),
        .one_hz_tick  (one_hz_tick)
    );

    seg_display u_seg_display (
        .clk  (pix_clk),
        .rst  (vga_rst),
        .hour (disp_hour),
        .min  (disp_min),
        .sec  (disp_sec),
        .seg  (seg),
        .an   (an)
    );

    vga_timing u_vga_timing (
        .clk        (pix_clk),
        .rst        (vga_rst),
        .pixel_en   (1'b1),
        .pixel_x    (pixel_x),
        .pixel_y    (pixel_y),
        .video_on   (video_on),
        .hsync      (vga_hs),
        .vsync      (vga_vs),
        .frame_tick (frame_tick)
    );

    bram_background u_bram_background (
        .clk      (pix_clk),
        .video_on (video_on),
        .bg_sel   (bg_sel),
        .pixel_x  (pixel_x),
        .pixel_y  (pixel_y),
        .bg_r     (bg_r),
        .bg_g     (bg_g),
        .bg_b     (bg_b)
    );

    anim_gen u_anim_gen (
        .clk        (pix_clk),
        .video_on   (video_on),
        .pixel_x    (pixel_x),
        .pixel_y    (pixel_y),
        .sw_mode    (sw_mode),
        .alarm_en   (alarm_en),
        .alarm_active(led_alarm),
        .hour       (disp_hour),
        .min        (disp_min),
        .sec        (disp_sec),
        .bg_r       (bg_r),
        .bg_g       (bg_g),
        .bg_b       (bg_b),
        .vga_r      (vga_r),
        .vga_g      (vga_g),
        .vga_b      (vga_b)
    );
endmodule
