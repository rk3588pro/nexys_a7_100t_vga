`timescale 1ns / 1ps

module vga_timing (
    input  wire       clk,
    input  wire       rst,
    input  wire       pixel_en,
    output reg [9:0]  pixel_x,
    output reg [9:0]  pixel_y,
    output wire       video_on,
    output wire       hsync,
    output wire       vsync,
    output wire       frame_tick
);
    localparam H_DISPLAY = 640;
    localparam H_FRONT   = 16;
    localparam H_SYNC    = 96;
    localparam H_BACK    = 48;
    localparam H_TOTAL   = H_DISPLAY + H_FRONT + H_SYNC + H_BACK;

    localparam V_DISPLAY = 480;
    localparam V_FRONT   = 10;
    localparam V_SYNC    = 2;
    localparam V_BACK    = 33;
    localparam V_TOTAL   = V_DISPLAY + V_FRONT + V_SYNC + V_BACK;

    always @(posedge clk) begin
        if (rst) begin
            pixel_x <= 10'd0;
            pixel_y <= 10'd0;
        end else if (pixel_en) begin
            if (pixel_x == H_TOTAL - 1) begin
                pixel_x <= 10'd0;
                if (pixel_y == V_TOTAL - 1) begin
                    pixel_y <= 10'd0;
                end else begin
                    pixel_y <= pixel_y + 10'd1;
                end
            end else begin
                pixel_x <= pixel_x + 10'd1;
            end
        end
    end

    assign video_on = (pixel_x < H_DISPLAY) && (pixel_y < V_DISPLAY);

    assign hsync = ~((pixel_x >= H_DISPLAY + H_FRONT) &&
                     (pixel_x <  H_DISPLAY + H_FRONT + H_SYNC));

    assign vsync = ~((pixel_y >= V_DISPLAY + V_FRONT) &&
                     (pixel_y <  V_DISPLAY + V_FRONT + V_SYNC));

    assign frame_tick = pixel_en && (pixel_x == H_TOTAL - 1) && (pixel_y == V_TOTAL - 1);
endmodule
