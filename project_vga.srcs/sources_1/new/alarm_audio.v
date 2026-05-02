`timescale 1ns / 1ps

module alarm_audio (
    input  wire clk,
    input  wire rst,
    input  wire alarm_active,
    output wire pwm_low
);
    localparam CLK_HZ = 25_174_010;
    localparam UNIT_TICKS = 2_221_824; // 16th note at quarter note = 170 BPM
    localparam NOTE_COUNT = 48;

    localparam N_REST = 4'd0;
    localparam N_C5   = 4'd1;
    localparam N_D5   = 4'd2;
    localparam N_E5   = 4'd3;
    localparam N_F5   = 4'd4;
    localparam N_G5   = 4'd5;
    localparam N_A5   = 4'd6;
    localparam N_B5   = 4'd7;
    localparam N_C6   = 4'd8;

    reg [7:0]  pwm_cnt;
    reg [15:0] tone_cnt;
    reg [21:0] unit_cnt;
    reg [5:0]  note_idx;
    reg [3:0]  unit_idx;
    reg        tone;

    wire [3:0] current_note;
    wire [3:0] current_units;
    wire [15:0] half_period;
    wire note_is_on;
    reg [7:0] sample;

    assign current_note = melody_note(note_idx);
    assign current_units = melody_units(note_idx);
    assign half_period = note_half_period(current_note);
    assign note_is_on = alarm_active && (current_note != N_REST) && (unit_idx < current_units);

    always @(posedge clk) begin
        if (rst) begin
            pwm_cnt  <= 8'd0;
            tone_cnt <= 16'd0;
            unit_cnt <= 22'd0;
            note_idx <= 6'd0;
            unit_idx <= 4'd0;
            tone     <= 1'b0;
        end else begin
            pwm_cnt <= pwm_cnt + 8'd1;

            if (alarm_active) begin
                if (unit_cnt == UNIT_TICKS - 1) begin
                    unit_cnt <= 22'd0;
                    if (unit_idx == current_units - 1) begin
                        unit_idx <= 4'd0;
                        if (note_idx == NOTE_COUNT - 1) begin
                            note_idx <= 6'd0;
                        end else begin
                            note_idx <= note_idx + 6'd1;
                        end
                    end else begin
                        unit_idx <= unit_idx + 4'd1;
                    end
                end else begin
                    unit_cnt <= unit_cnt + 22'd1;
                end

                if (half_period != 16'd0) begin
                    if (tone_cnt == half_period - 1) begin
                        tone_cnt <= 16'd0;
                        tone <= ~tone;
                    end else begin
                        tone_cnt <= tone_cnt + 16'd1;
                    end
                end else begin
                    tone_cnt <= 16'd0;
                    tone <= 1'b0;
                end
            end else begin
                tone_cnt <= 16'd0;
                unit_cnt <= 22'd0;
                note_idx <= 6'd0;
                unit_idx <= 4'd0;
                tone <= 1'b0;
            end
        end
    end

    always @(*) begin
        if (note_is_on) begin
            sample = tone ? 8'd198 : 8'd58;
        end else begin
            sample = 8'd128;
        end
    end

    assign pwm_low = (pwm_cnt >= sample);

    function [3:0] melody_note;
        input [5:0] idx;
        begin
            case (idx)
                6'd0:  melody_note = N_E5;
                6'd1:  melody_note = N_G5;
                6'd2:  melody_note = N_E5;
                6'd3:  melody_note = N_D5;
                6'd4:  melody_note = N_C5;
                6'd5:  melody_note = N_D5;
                6'd6:  melody_note = N_E5;
                6'd7:  melody_note = N_REST;
                6'd8:  melody_note = N_C5;
                6'd9:  melody_note = N_E5;
                6'd10: melody_note = N_G5;
                6'd11: melody_note = N_E5;
                6'd12: melody_note = N_D5;
                6'd13: melody_note = N_C5;
                6'd14: melody_note = N_D5;
                6'd15: melody_note = N_REST;
                6'd16: melody_note = N_G5;
                6'd17: melody_note = N_A5;
                6'd18: melody_note = N_G5;
                6'd19: melody_note = N_E5;
                6'd20: melody_note = N_G5;
                6'd21: melody_note = N_A5;
                6'd22: melody_note = N_C6;
                6'd23: melody_note = N_REST;
                6'd24: melody_note = N_C6;
                6'd25: melody_note = N_B5;
                6'd26: melody_note = N_A5;
                6'd27: melody_note = N_G5;
                6'd28: melody_note = N_E5;
                6'd29: melody_note = N_G5;
                6'd30: melody_note = N_A5;
                6'd31: melody_note = N_REST;
                6'd32: melody_note = N_E5;
                6'd33: melody_note = N_F5;
                6'd34: melody_note = N_G5;
                6'd35: melody_note = N_E5;
                6'd36: melody_note = N_D5;
                6'd37: melody_note = N_E5;
                6'd38: melody_note = N_G5;
                6'd39: melody_note = N_REST;
                6'd40: melody_note = N_A5;
                6'd41: melody_note = N_G5;
                6'd42: melody_note = N_E5;
                6'd43: melody_note = N_D5;
                6'd44: melody_note = N_C5;
                6'd45: melody_note = N_D5;
                6'd46: melody_note = N_E5;
                default: melody_note = N_REST;
            endcase
        end
    endfunction

    function [3:0] melody_units;
        input [5:0] idx;
        begin
            case (idx)
                6'd7, 6'd15, 6'd23, 6'd31, 6'd39: melody_units = 4'd1;
                6'd46: melody_units = 4'd4;
                default: melody_units = 4'd2;
            endcase
        end
    endfunction

    function [15:0] note_half_period;
        input [3:0] note;
        begin
            case (note)
                N_C5: note_half_period = 16'd24067; // 523 Hz
                N_D5: note_half_period = 16'd21405; // 588 Hz
                N_E5: note_half_period = 16'd19068; // 660 Hz
                N_F5: note_half_period = 16'd18033; // 698 Hz
                N_G5: note_half_period = 16'd16055; // 784 Hz
                N_A5: note_half_period = 16'd14304; // 880 Hz
                N_B5: note_half_period = 16'd12740; // 988 Hz
                N_C6: note_half_period = 16'd12033; // 1046 Hz
                default: note_half_period = 16'd0;
            endcase
        end
    endfunction
endmodule
