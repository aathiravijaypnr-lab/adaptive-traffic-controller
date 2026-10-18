
`timescale 1ns/1ps

module amtgc_top #(
    parameter [31:0] MIN_GREEN_TIME    = 5,
    parameter [31:0] MAX_GREEN_TIME    = 10,
    parameter [31:0] GREEN_EXTENSION   = 1,
    parameter [31:0] YELLOW_TIME       = 3,
    parameter [31:0] RED_TIME          = 8,
    parameter [31:0] PEDESTRIAN_TIME   = 6,
    parameter        SYNC_OFFSET_TIME  = 4
)(
    input  wire clk,
    input  wire rst_n,

    // Shared pedestrian requests
    input  wire ped_req_a,
    input  wire ped_req_b,

    // One system-wide emergency override
    input  wire emergency_override,

    // Adaptive traffic density inputs
    input  wire [2:0] density_a,
    input  wire [2:0] density_b,

    // Controller states
    output wire [2:0] state_a,
    output wire [2:0] state_b,

    // Junction A lights
    output wire ns_green_a,
    output wire ns_yellow_a,
    output wire ew_green_a,
    output wire ew_yellow_a,
    output wire ped_walk_a,

    // Junction B lights
    output wire ns_green_b,
    output wire ns_yellow_b,
    output wire ew_green_b,
    output wire ew_yellow_b,
    output wire ped_walk_b,

    // Observable green-wave synchronization signal
    output wire sync_trigger
);

    // ========================================================
    // Internal signals
    // ========================================================

    wire ped_grant_a;
    wire ped_grant_b;

    wire timer_expired_a;
    wire timer_expired_b;

    wire timer_start_a;
    wire timer_start_b;

    wire [31:0] timer_limit_a;
    wire [31:0] timer_limit_b;

    wire ped_ready_a;
    wire ped_ready_b;

    wire sync_trigger_raw;

    // Drive the emergency signal directly to both controllers.
    // Their state machines enter ST_EMERGENCY on the next clock
    // edge, while their light outputs are gated immediately.
    wire emg_active;
    assign emg_active = emergency_override;

    // Do not expose a stale synchronization pulse during emergency.
    assign sync_trigger = sync_trigger_raw & ~emergency_override;

    // Pedestrian requests are accepted only during normal operation.
    wire ped_req_a_normal;
    wire ped_req_b_normal;

    assign ped_req_a_normal = ped_req_a & ~emergency_override;
    assign ped_req_b_normal = ped_req_b & ~emergency_override;

    // Existing controller interface: NS_YELLOW is the request-ready
    // phase. Pedestrian grant timing must be verified in simulation.
    assign ped_ready_a =
        (state_a == 3'b010) & ~emergency_override;

    assign ped_ready_b =
        (state_b == 3'b010) & ~emergency_override;


    // ========================================================
    // Green-wave synchronization
    // ========================================================

    green_wave_sync #(
        .OFFSET_CYCLES(SYNC_OFFSET_TIME)
    ) u_green_wave_sync (
        .clk            (clk),
        .rst_n          (rst_n),
        .state_a        (state_a),
        .sync_trigger_b (sync_trigger_raw)
    );


    // ========================================================
    // Shared pedestrian arbiter
    // ========================================================

    ped_arbiter u_ped_arbiter (
        .clk     (clk),
        .rst_n   (rst_n),

        .req_a   (ped_req_a_normal),
        .req_b   (ped_req_b_normal),

        .ready_a (ped_ready_a),
        .ready_b (ped_ready_b),

        .grant_a (ped_grant_a),
        .grant_b (ped_grant_b)
    );


    // ========================================================
    // Junction A timer
    // ========================================================

    generic_timer #(
        .COUNTER_WIDTH(32)
    ) u_timer_a (
        .clk          (clk),
        .rst_n        (rst_n),
        .start        (timer_start_a),
        .count_target (timer_limit_a),
        .done         (timer_expired_a)
    );


    // ========================================================
    // Junction B timer
    // ========================================================

    generic_timer #(
        .COUNTER_WIDTH(32)
    ) u_timer_b (
        .clk          (clk),
        .rst_n        (rst_n),
        .start        (timer_start_b),
        .count_target (timer_limit_b),
        .done         (timer_expired_b)
    );


    // ========================================================
    // Junction A controller
    // ========================================================

    junction_controller #(
        .MIN_GREEN_TIME  (MIN_GREEN_TIME),
        .MAX_GREEN_TIME  (MAX_GREEN_TIME),
        .GREEN_EXTENSION (GREEN_EXTENSION),
        .YELLOW_TIME     (YELLOW_TIME),
        .RED_TIME        (RED_TIME),
        .PEDESTRIAN_TIME (PEDESTRIAN_TIME),
        .IS_JUNCTION_B   (1'b0)
    ) u_junction_a (
        .clk              (clk),
        .rst_n            (rst_n),

        .timer_expired    (timer_expired_a),
        .ped_grant        (ped_grant_a),
        .emg_active       (emg_active),
        .sync_trigger     (1'b0),

        .traffic_density  (density_a),

        .timer_limit      (timer_limit_a),
        .timer_start      (timer_start_a),

        .ns_green         (ns_green_a),
        .ns_yellow        (ns_yellow_a),
        .ew_green         (ew_green_a),
        .ew_yellow        (ew_yellow_a),
        .ped_walk         (ped_walk_a),

        .current_state    (state_a)
    );


    // ========================================================
    // Junction B controller
    // ========================================================

    junction_controller #(
        .MIN_GREEN_TIME  (MIN_GREEN_TIME),
        .MAX_GREEN_TIME  (MAX_GREEN_TIME),
        .GREEN_EXTENSION (GREEN_EXTENSION),
        .YELLOW_TIME     (YELLOW_TIME),
        .RED_TIME        (RED_TIME),
        .PEDESTRIAN_TIME (PEDESTRIAN_TIME),
        .IS_JUNCTION_B   (1'b1)
    ) u_junction_b (
        .clk              (clk),
        .rst_n            (rst_n),

        .timer_expired    (timer_expired_b),
        .ped_grant        (ped_grant_b),
        .emg_active       (emg_active),
        .sync_trigger     (sync_trigger),

        .traffic_density  (density_b),

        .timer_limit      (timer_limit_b),
        .timer_start      (timer_start_b),

        .ns_green         (ns_green_b),
        .ns_yellow        (ns_yellow_b),
        .ew_green         (ew_green_b),
        .ew_yellow        (ew_yellow_b),
        .ped_walk         (ped_walk_b),

        .current_state    (state_b)
    );

endmodule

