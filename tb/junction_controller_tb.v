
`timescale 1ns/1ps

module junction_controller_tb;

    localparam CLK_PERIOD = 10;

    localparam [2:0]
        ST_RESET     = 3'b000,
        ST_NS_GREEN  = 3'b001,
        ST_NS_YELLOW = 3'b010,
        ST_EW_GREEN  = 3'b011,
        ST_EW_YELLOW = 3'b100,
        ST_PED_WALK  = 3'b101,
        ST_ALL_RED   = 3'b110,
        ST_EMERGENCY = 3'b111;

    reg clk;
    reg rst_n;
    reg ped_grant;
    reg emg_active;
    reg sync_trigger;
    reg [2:0] traffic_density;

    wire timer_expired;
    wire timer_start;
    wire [31:0] timer_limit;

    wire ns_green;
    wire ns_yellow;
    wire ew_green;
    wire ew_yellow;
    wire ped_walk;
    wire [2:0] current_state;

    integer pass_count;
    integer fail_count;
    integer cycles;
    integer green_cycles;
    integer ped_entries;
    reg [2:0] last_state;

    // Clock generation
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Final junction controller RTL
    junction_controller #(
        .MIN_GREEN_TIME  (5),
        .MAX_GREEN_TIME  (10),
        .GREEN_EXTENSION (1),
        .YELLOW_TIME     (3),
        .RED_TIME        (8),
        .PEDESTRIAN_TIME (6),
        .IS_JUNCTION_B   (1'b0)
    ) dut (
        .clk             (clk),
        .rst_n           (rst_n),
        .timer_expired   (timer_expired),
        .ped_grant       (ped_grant),
        .emg_active      (emg_active),
        .sync_trigger    (sync_trigger),
        .traffic_density (traffic_density),
        .timer_limit     (timer_limit),
        .timer_start     (timer_start),
        .ns_green        (ns_green),
        .ns_yellow       (ns_yellow),
        .ew_green        (ew_green),
        .ew_yellow       (ew_yellow),
        .ped_walk        (ped_walk),
        .current_state   (current_state)
    );

    // External generic timer
    generic_timer #(
        .COUNTER_WIDTH(32)
    ) u_timer (
        .clk          (clk),
        .rst_n        (rst_n),
        .start        (timer_start),
        .count_target (timer_limit),
        .done         (timer_expired)
    );

    task check;
        input condition;
        input [8*100-1:0] message;
        begin
            if (condition === 1'b1) begin
                pass_count = pass_count + 1;
                $display("PASS: %0s", message);
            end
            else begin
                fail_count = fail_count + 1;
                $display("FAIL: %0s", message);
            end
        end
    endtask

    // Wait for an FSM state with a timeout.
    task wait_for_state;
        input [2:0] expected;
        input integer timeout_cycles;
        output reg found;
        integer i;
        begin
            found = (current_state === expected);

            for (i = 0; i < timeout_cycles && !found; i = i + 1) begin
                @(negedge clk);
                if (current_state === expected)
                    found = 1'b1;
            end

            if (!found)
                $display("TIMEOUT: Expected state %b, actual %b",
                         expected, current_state);
        end
    endtask

    reg found;

    // Count entries into the pedestrian state.
    always @(negedge clk) begin
        if (!rst_n) begin
            last_state = ST_RESET;
        end
        else begin
            if (current_state == ST_PED_WALK &&
                last_state != ST_PED_WALK)
                ped_entries = ped_entries + 1;

            last_state = current_state;
        end
    end

    initial begin
        rst_n          = 1'b0;
        ped_grant      = 1'b0;
        emg_active     = 1'b0;
        sync_trigger   = 1'b0;
        traffic_density = 3'd0;

        pass_count  = 0;
        fail_count  = 0;
        ped_entries = 0;
        green_cycles = 0;

        $display("");
        $display("==============================================");
        $display(" JUNCTION CONTROLLER STANDALONE VERIFICATION");
        $display("==============================================");

        // TEST 1: Reset
        #2;
        check(current_state == ST_RESET,
              "Active-low asynchronous reset");

        repeat (3) @(negedge clk);
        rst_n = 1'b1;

        // TEST 2: Initial all-red
        wait_for_state(ST_ALL_RED, 10, found);
        check(found, "RESET to ALL_RED transition");

        // TEST 3: Normal NS green
        wait_for_state(ST_NS_GREEN, 40, found);
        check(found && ns_green && !ew_green,
              "NS GREEN phase entered safely");

        // Check sampled adaptive target for density 0
        check(timer_limit == 5,
              "Density 0 selects minimum green time 5");

        // TEST 4: NS yellow
        wait_for_state(ST_NS_YELLOW, 30, found);
        check(found && ns_yellow && !ew_yellow,
              "NS YELLOW phase entered");

        // TEST 5: Pedestrian grant during NS yellow
        // Drive inputs at the falling edge.
        ped_grant = 1'b1;
        @(negedge clk);
        ped_grant = 1'b0;

        wait_for_state(ST_ALL_RED, 30, found);
        check(found, "Safety ALL_RED after NS YELLOW");

        wait_for_state(ST_PED_WALK, 40, found);
        check(found && ped_walk &&
              !ns_green && !ew_green,
              "Pedestrian walk phase entered safely");

        // TEST 6: Return to EW green
        wait_for_state(ST_EW_GREEN, 40, found);
        check(found && ew_green && !ns_green,
              "EW GREEN phase after pedestrian service");

        wait_for_state(ST_EW_YELLOW, 30, found);
        check(found && ew_yellow,
              "EW YELLOW phase entered");

        wait_for_state(ST_ALL_RED, 30, found);
        check(found, "Safety ALL_RED after EW YELLOW");

        // TEST 7: Density 7 maximum green time
        traffic_density = 3'd7;

        wait_for_state(ST_NS_GREEN, 40, found);
        check(found && timer_limit == 10,
              "Density 7 selects capped green time 10");

        // TEST 8: Mid-green density change
        traffic_density = 3'd0;
        #1;
        check(timer_limit == 10,
              "Mid-green density change does not alter target");

        // TEST 9: Emergency preemption
        emg_active = 1'b1;
        #1;

        check(!ns_green && !ns_yellow &&
              !ew_green && !ew_yellow && !ped_walk,
              "Emergency immediately suppresses outputs");

        @(negedge clk);
        check(current_state == ST_EMERGENCY,
              "Controller enters EMERGENCY state");

        // TEST 10: Emergency recovery
        emg_active = 1'b0;

        wait_for_state(ST_ALL_RED, 10, found);
        check(found, "Emergency recovery enters ALL_RED");

        // TEST 11: Reset during operation
        rst_n = 1'b0;
        #1;
        check(current_state == ST_RESET,
              "Mid-operation asynchronous reset");

        @(negedge clk);
        rst_n = 1'b1;

        wait_for_state(ST_ALL_RED, 10, found);
        check(found, "Recovery after mid-operation reset");

        // Check pedestrian service count
        check(ped_entries == 1,
              "Pedestrian request serviced exactly once");

        $display("");
        $display("==============================================");
        $display(" FINAL STANDALONE VERIFICATION SUMMARY");
        $display("==============================================");
        $display(" TOTAL PASS = %0d", pass_count);
        $display(" TOTAL FAIL = %0d", fail_count);

        if (fail_count == 0)
            $display(" JUNCTION CONTROLLER TEST PASSED");
        else
            $display(" JUNCTION CONTROLLER TEST FAILED");

        $display("==============================================");

        $finish;
    end

    // Global watchdog prevents endless simulation.
    initial begin
        #100000;
        $display("FAIL: Global simulation timeout");
        $finish;
    end

endmodule
