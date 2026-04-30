`timescale 1ns / 1ps

module seg_display (
    input  wire       clk,
    input  wire       rst,
    input  wire [4:0] hour,
    input  wire [5:0] min,
    input  wire [5:0] sec,
    output reg  [7:0] seg,
    output reg  [7:0] an
);
    reg [14:0] scan_cnt;
    reg [2:0]  scan_sel;
    reg [3:0]  digit;

    wire [3:0] hour_tens = hour / 10;
    wire [3:0] hour_ones = hour % 10;
    wire [3:0] min_tens  = min / 10;
    wire [3:0] min_ones  = min % 10;
    wire [3:0] sec_tens  = sec / 10;
    wire [3:0] sec_ones  = sec % 10;

    always @(posedge clk) begin
        if (rst) begin
            scan_cnt <= 15'd0;
            scan_sel <= 3'd0;
        end else if (scan_cnt == 15'd25_173) begin
            scan_cnt <= 15'd0;
            scan_sel <= scan_sel + 3'd1;
        end else begin
            scan_cnt <= scan_cnt + 15'd1;
        end
    end

    always @(*) begin
        case (scan_sel)
            3'd0: begin an = 8'b1111_1110; digit = sec_ones;  end
            3'd1: begin an = 8'b1111_1101; digit = sec_tens;  end
            3'd2: begin an = 8'b1111_1011; digit = 4'hE;      end
            3'd3: begin an = 8'b1111_0111; digit = min_ones;  end
            3'd4: begin an = 8'b1110_1111; digit = min_tens;  end
            3'd5: begin an = 8'b1101_1111; digit = 4'hE;      end
            3'd6: begin an = 8'b1011_1111; digit = hour_ones; end
            3'd7: begin an = 8'b0111_1111; digit = hour_tens; end
            default: begin an = 8'b1111_1111; digit = 4'hF;   end
        endcase

        seg = seg_decode(digit);
    end

    function [7:0] seg_decode;
        input [3:0] value;
        begin
            case (value)
                4'h0: seg_decode = 8'b1100_0000;
                4'h1: seg_decode = 8'b1111_1001;
                4'h2: seg_decode = 8'b1010_0100;
                4'h3: seg_decode = 8'b1011_0000;
                4'h4: seg_decode = 8'b1001_1001;
                4'h5: seg_decode = 8'b1001_0010;
                4'h6: seg_decode = 8'b1000_0010;
                4'h7: seg_decode = 8'b1111_1000;
                4'h8: seg_decode = 8'b1000_0000;
                4'h9: seg_decode = 8'b1001_0000;
                4'hE: seg_decode = 8'b1011_1111;
                default: seg_decode = 8'b1111_1111;
            endcase
        end
    endfunction
endmodule
