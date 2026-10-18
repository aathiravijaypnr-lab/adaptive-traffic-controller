
`timescale 1ns/1ps

module junction_controller #(
    parameter [31:0] MIN_GREEN_TIME  = 5,
    parameter [31:0] MAX_GREEN_TIME  = 10,
    parameter [31:0] GREEN_EXTENSION = 1,
    parameter [31:0] YELLOW_TIME     = 3,
    parameter [31:0] RED_TIME        = 8,
    parameter [31:0] PEDESTRIAN_TIME = 6,
    parameter        IS_JUNCTION_B   = 1'b0
)(
    input wire clk,
    input wire rst_n,
    input wire timer_expired,
    input wire ped_grant,
    input wire emg_active,
    input wire sync_trigger,
    input wire [2:0] traffic_density,

    output reg [31:0] timer_limit,
    output reg timer_start,
    output reg ns_green,
    output reg ns_yellow,
    output reg ew_green,
    output reg ew_yellow,
    output reg ped_walk,
    output reg [2:0] current_state
);

    localparam [2:0] ST_RESET     = 3'b000;
    localparam [2:0] ST_NS_GREEN  = 3'b001;
    localparam [2:0] ST_NS_YELLOW = 3'b010;
    localparam [2:0] ST_EW_GREEN  = 3'b011;
    localparam [2:0] ST_EW_YELLOW = 3'b100;
    localparam [2:0] ST_PED_WALK  = 3'b101;
    localparam [2:0] ST_ALL_RED   = 3'b110;
    localparam [2:0] ST_EMERGENCY = 3'b111;

    reg [2:0] next_state;
    reg [31:0] sampled_green_time;

    reg ped_pending;
    reg ped_after_red;
    reg red_to_ns;
    reg sync_pending;
    reg red_timer_done;

    // Calculate adaptive green time and clamp to the allowed range.
    function [31:0] calculate_green_time;
        input [2:0] density;
        reg [31:0] value;
        begin
            value = MIN_GREEN_TIME + density * GREEN_EXTENSION;

            if (value < MIN_GREEN_TIME)
                calculate_green_time = MIN_GREEN_TIME;
            else if (value > MAX_GREEN_TIME)
                calculate_green_time = MAX_GREEN_TIME;
            else
                calculate_green_time = value;
        end
    endfunction

    // State register: emergency override has priority.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= ST_RESET;
        else if (emg_active)
            current_state <= ST_EMERGENCY;
        else
            current_state <= next_state;
    end

    // Retain pedestrian requests until served.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ped_pending <= 1'b0;
        else if (emg_active)
            ped_pending <= 1'b0;
        else if (current_state == ST_PED_WALK)
            ped_pending <= 1'b0;
        else if (ped_grant)
            ped_pending <= 1'b1;
    end

    // Remember all-red timer completion while waiting for sync.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            red_timer_done <= 1'b0;
        else if (emg_active)
            red_timer_done <= 1'b0;
        else if (current_state != ST_ALL_RED)
            red_timer_done <= 1'b0;
        else if (timer_expired)
            red_timer_done <= 1'b1;
    end

    // Track the next phase after all-red and retain sync events.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ped_after_red <= 1'b0;
            red_to_ns     <= 1'b1;
            sync_pending  <= 1'b0;
        end
        else if (emg_active) begin
            ped_after_red <= 1'b0;
            red_to_ns     <= 1'b0;
            sync_pending  <= 1'b0;
        end
        else begin
            if (IS_JUNCTION_B && sync_trigger)
                sync_pending <= 1'b1;

            if (current_state == ST_NS_YELLOW &&
                timer_expired) begin
                ped_after_red <= ped_pending | ped_grant;
                red_to_ns     <= 1'b0;
            end
            else if (current_state == ST_EW_YELLOW &&
                     timer_expired) begin
                red_to_ns     <= 1'b1;
                ped_after_red <= 1'b0;
            end
            else if (current_state == ST_ALL_RED &&
                     (timer_expired || red_timer_done)) begin
                ped_after_red <= 1'b0;

                if (red_to_ns &&
                    (!IS_JUNCTION_B ||
                     sync_trigger ||
                     sync_pending))
                    sync_pending <= 1'b0;
            end

            if (current_state == ST_PED_WALK)
                ped_after_red <= 1'b0;

            if (current_state == ST_EMERGENCY) begin
                ped_after_red <= 1'b0;
                red_to_ns     <= 1'b0;
            end
        end
    end

    // Sample adaptive green time only when entering a green phase.
    // Sample adaptive green time only when entering a green phase.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sampled_green_time <= MIN_GREEN_TIME;
        else if (emg_active)
            sampled_green_time <= MIN_GREEN_TIME;
        else if ((next_state == ST_NS_GREEN &&
                  current_state != ST_NS_GREEN) ||
                 (next_state == ST_EW_GREEN &&
                  current_state != ST_EW_GREEN)
                )
            sampled_green_time <= calculate_green_time(
                traffic_density
            );
    end
    // Next-state logic.
    always @(*) begin
        next_state = current_state;

        case (current_state)

            ST_RESET: begin
                next_state = ST_ALL_RED;
            end

            ST_NS_GREEN: begin
                if (timer_expired)
                    next_state = ST_NS_YELLOW;
            end

            ST_NS_YELLOW: begin
                if (timer_expired)
                    next_state = ST_ALL_RED;
            end

            ST_ALL_RED: begin
                if (timer_expired || red_timer_done) begin
                    if (red_to_ns) begin
                        if (!IS_JUNCTION_B ||
                            sync_trigger ||
                            sync_pending)
                            next_state = ST_NS_GREEN;
                    end
                    else if (ped_after_red ||
                             ped_pending ||
                             ped_grant) begin
                        next_state = ST_PED_WALK;
                    end
                    else begin
                        next_state = ST_EW_GREEN;
                    end
                end
            end

            ST_EW_GREEN: begin
                if (timer_expired)
                    next_state = ST_EW_YELLOW;
            end

            ST_EW_YELLOW: begin
                if (timer_expired)
                    next_state = ST_ALL_RED;
            end

            ST_PED_WALK: begin
                if (timer_expired)
                    next_state = ST_EW_GREEN;
            end

            ST_EMERGENCY: begin
                next_state = ST_ALL_RED;
            end

            default: begin
                next_state = ST_ALL_RED;
            end

        endcase
    end

    // Timer configuration for the current phase.
    always @(*) begin
        timer_start = 1'b0;
        timer_limit = 32'd0;

        if (!emg_active) begin
            case (current_state)

                ST_NS_GREEN,
                ST_EW_GREEN: begin
                    timer_start = 1'b1;
                    timer_limit = sampled_green_time;
                end

                ST_NS_YELLOW,
                ST_EW_YELLOW: begin
                    timer_start = 1'b1;
                    timer_limit = YELLOW_TIME;
                end

                ST_ALL_RED: begin
                    timer_start = 1'b1;
                    timer_limit = RED_TIME;
                end

                ST_PED_WALK: begin
                    timer_start = 1'b1;
                    timer_limit = PEDESTRIAN_TIME;
                end

                default: begin
                    timer_start = 1'b0;
                    timer_limit = 32'd0;
                end

            endcase
        end
    end

    // Moore outputs.
    // All vehicle and pedestrian signals remain off during emergency.
    always @(*) begin
        ns_green  = 1'b0;
        ns_yellow = 1'b0;
        ew_green  = 1'b0;
        ew_yellow = 1'b0;
        ped_walk  = 1'b0;

        if (!emg_active) begin
            case (current_state)

                ST_NS_GREEN:
                    ns_green = 1'b1;

                ST_NS_YELLOW:
                    ns_yellow = 1'b1;

                ST_EW_GREEN:
                    ew_green = 1'b1;

                ST_EW_YELLOW:
                    ew_yellow = 1'b1;

                ST_PED_WALK:
                    ped_walk = 1'b1;

                default: begin
                    ns_green  = 1'b0;
                    ns_yellow = 1'b0;
                    ew_green  = 1'b0;
                    ew_yellow = 1'b0;
                    ped_walk  = 1'b0;
                end

            endcase
        end
    end

endmodule

