`timescale 1ns / 1ps

module bram_background (
    input  wire       clk,
    input  wire       video_on,
    input  wire       bg_sel,
    input  wire [9:0] pixel_x,
    input  wire [9:0] pixel_y,
    output reg  [3:0] bg_r,
    output reg  [3:0] bg_g,
    output reg  [3:0] bg_b
);
    wire [8:0] rom_x;
    wire [7:0] rom_y;
    wire [16:0] base_addr;
    wire [17:0] rom_addr;
    wire [11:0] rom_rgb;

    reg video_on_d;

    assign rom_x = pixel_x[9:1];
    assign rom_y = pixel_y[8:1];
    assign base_addr = ({9'd0, rom_y} << 8) + ({9'd0, rom_y} << 6) + {8'd0, rom_x};
    assign rom_addr = bg_sel ? ({1'b0, base_addr} + 18'd76800) : {1'b0, base_addr};

    blk_mem_gen_0 u_bg_rom (
        .clka  (clk),
        .ena   (1'b1),
        .addra (rom_addr),
        .douta (rom_rgb)
    );

    always @(posedge clk) begin
        video_on_d <= video_on;

        if (video_on_d) begin
            bg_r <= rom_rgb[11:8];
            bg_g <= rom_rgb[7:4];
            bg_b <= rom_rgb[3:0];
        end else begin
            bg_r <= 4'h0;
            bg_g <= 4'h0;
            bg_b <= 4'h0;
        end
    end
endmodule
