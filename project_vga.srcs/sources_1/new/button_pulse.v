`timescale 1ns / 1ps

module button_pulse (
    input  wire clk,
    input  wire rst,
    input  wire button_in,
    output reg  pulse
);
    localparam DEBOUNCE_TICKS = 19'd503_480;

    reg [1:0] sync;
    reg       stable;
    reg       stable_d;
    reg [18:0] cnt;

    always @(posedge clk) begin
        if (rst) begin
            sync     <= 2'b00;
            stable   <= 1'b0;
            stable_d <= 1'b0;
            cnt      <= 19'd0;
            pulse    <= 1'b0;
        end else begin
            sync <= {sync[0], button_in};

            if (sync[1] == stable) begin
                cnt <= 19'd0;
            end else if (cnt == DEBOUNCE_TICKS - 1) begin
                stable <= sync[1];
                cnt    <= 19'd0;
            end else begin
                cnt <= cnt + 19'd1;
            end

            stable_d <= stable;
            pulse    <= stable && !stable_d;
        end
    end
endmodule
