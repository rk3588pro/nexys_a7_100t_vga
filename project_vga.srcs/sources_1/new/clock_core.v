`timescale 1ns / 1ps

module clock_core (
    input  wire       clk,
    input  wire       rst,
    input  wire       btn_hour_up,
    input  wire       btn_hour_down,
    input  wire       btn_min_up,
    input  wire       btn_min_down,
    input  wire       sw_mode,
    input  wire       alarm_en,
    output reg  [4:0] hour,
    output reg  [5:0] min,
    output reg  [5:0] sec,
    output wire [4:0] disp_hour,
    output wire [5:0] disp_min,
    output wire [5:0] disp_sec,
    output reg        led_hourly,
    output reg        led_alarm,
    output reg        one_hz_tick
);
    localparam CLK_HZ = 25_174_010;

    reg [24:0] tick_cnt;
    reg [4:0]  alarm_hour;
    reg [5:0]  alarm_min;
    reg [1:0]  mode_sync;
    reg [1:0]  alarm_en_sync;

    wire hour_up_pulse;
    wire hour_down_pulse;
    wire min_up_pulse;
    wire min_down_pulse;
    wire mode;
    wire alarm_enabled;

    assign mode = mode_sync[1];
    assign alarm_enabled = alarm_en_sync[1];
    assign disp_hour = mode ? alarm_hour : hour;
    assign disp_min  = mode ? alarm_min  : min;
    assign disp_sec  = mode ? 6'd0       : sec;

    button_pulse u_btn_hour_up (
        .clk       (clk),
        .rst       (rst),
        .button_in (btn_hour_up),
        .pulse     (hour_up_pulse)
    );

    button_pulse u_btn_hour_down (
        .clk       (clk),
        .rst       (rst),
        .button_in (btn_hour_down),
        .pulse     (hour_down_pulse)
    );

    button_pulse u_btn_min_up (
        .clk       (clk),
        .rst       (rst),
        .button_in (btn_min_up),
        .pulse     (min_up_pulse)
    );

    button_pulse u_btn_min_down (
        .clk       (clk),
        .rst       (rst),
        .button_in (btn_min_down),
        .pulse     (min_down_pulse)
    );

    always @(posedge clk) begin
        if (rst) begin
            tick_cnt    <= 25'd0;
            hour        <= 5'd0;
            min         <= 6'd0;
            sec         <= 6'd0;
            alarm_hour  <= 5'd0;
            alarm_min   <= 6'd0;
            mode_sync   <= 2'b00;
            alarm_en_sync <= 2'b00;
            led_hourly  <= 1'b0;
            led_alarm   <= 1'b0;
            one_hz_tick <= 1'b0;
        end else begin
            one_hz_tick <= 1'b0;
            mode_sync <= {mode_sync[0], sw_mode};
            alarm_en_sync <= {alarm_en_sync[0], alarm_en};

            if (tick_cnt == CLK_HZ - 1) begin
                tick_cnt    <= 25'd0;
                one_hz_tick <= 1'b1;

                if (sec == 6'd59) begin
                    sec <= 6'd0;
                    if (min == 6'd59) begin
                        min <= 6'd0;
                        if (hour == 5'd23) begin
                            hour <= 5'd0;
                        end else begin
                            hour <= hour + 5'd1;
                        end
                    end else begin
                        min <= min + 6'd1;
                    end
                end else begin
                    sec <= sec + 6'd1;
                end
            end else begin
                tick_cnt <= tick_cnt + 25'd1;
            end

            if (mode) begin
                if (hour_up_pulse) begin
                    alarm_hour <= (alarm_hour == 5'd23) ? 5'd0 : alarm_hour + 5'd1;
                end else if (hour_down_pulse) begin
                    alarm_hour <= (alarm_hour == 5'd0) ? 5'd23 : alarm_hour - 5'd1;
                end

                if (min_up_pulse) begin
                    alarm_min <= (alarm_min == 6'd59) ? 6'd0 : alarm_min + 6'd1;
                end else if (min_down_pulse) begin
                    alarm_min <= (alarm_min == 6'd0) ? 6'd59 : alarm_min - 6'd1;
                end
            end else begin
                if (hour_up_pulse) begin
                    hour <= (hour == 5'd23) ? 5'd0 : hour + 5'd1;
                    sec  <= 6'd0;
                end else if (hour_down_pulse) begin
                    hour <= (hour == 5'd0) ? 5'd23 : hour - 5'd1;
                    sec  <= 6'd0;
                end

                if (min_up_pulse) begin
                    min <= (min == 6'd59) ? 6'd0 : min + 6'd1;
                    sec <= 6'd0;
                end else if (min_down_pulse) begin
                    min <= (min == 6'd0) ? 6'd59 : min - 6'd1;
                    sec <= 6'd0;
                end
            end

            led_hourly <= (min == 6'd0) && (sec == 6'd0);
            led_alarm  <= alarm_enabled && (hour == alarm_hour) && (min == alarm_min);
        end
    end
endmodule
