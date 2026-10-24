
`timescale 1ns/1ps

module generic_timer_tb;

    localparam CLK_PERIOD = 10;

    reg clk;
    reg rst_n;

    reg start4, start8, start16;
    reg [3:0] target4;
    reg [7:0] target8;
    reg [15:0] target16;

    wire done4, done8, done16;

    integer pass_count;
    integer fail_count;
    integer cycles;
    integer pulses;
    integer i;

    // Clock generation: 100 MHz
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Timer with 4-bit counter
    generic_timer #(
        .COUNTER_WIDTH(4)
    ) timer4 (
        .clk(clk),
        .rst_n(rst_n),
        .start(start4),
        .count_target(target4),
        .done(done4)
    );

    // Timer with 8-bit counter
    generic_timer #(
        .COUNTER_WIDTH(8)
    ) timer8 (
        .clk(clk),
        .rst_n(rst_n),
        .start(start8),
        .count_target(target8),
        .done(done8)
    );

    // Timer with 16-bit counter
    generic_timer #(
        .COUNTER_WIDTH(16)
    ) timer16 (
        .clk(clk),
        .rst_n(rst_n),
        .start(start16),
        .count_target(target16),
        .done(done16)
    );

    // PASS/FAIL reporting
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

    // Sample after sequential logic updates.
    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    // Stop all timers and allow targets to settle.
    task stop_all;
        begin
            @(negedge clk);
            start4  = 0;
            start8  = 0;
            start16 = 0;

            repeat (2) tick;
        end
    endtask

    // Test one timer and measure its first done pulse.
    // Timer selection: 4, 8, or 16.
    task run_count_test;
        input integer width;
        input integer target;
        integer measured;
        integer pulse_seen;
        integer finished;
        begin
            stop_all();

            @(negedge clk);

            case (width)
                4:  target4  = target;
                8:  target8  = target;
                16: target16 = target;
            endcase

            // Register target while start is low.
            repeat (2) tick;

            @(negedge clk);

            case (width)
                4:  start4  = 1;
                8:  start8  = 1;
                16: start16 = 1;
            endcase

            measured = 0;
            pulse_seen = 0;
            finished = 0;

            // Count until first done pulse.
            while (!finished && measured < target + 5) begin
                tick;
                measured = measured + 1;

                case (width)
                    4:  if (done4)  finished = 1;
                    8:  if (done8)  finished = 1;
                    16: if (done16) finished = 1;
                endcase
            end

            $display(
                "INFO: Width=%0d Target=%0d Measured=%0d",
                width, target, measured
            );

            check(finished && measured == target,
                  "Timer completed after expected clock cycles");

            // Check that done goes low on the next clock.
            tick;

            case (width)
                4:  pulse_seen = done4;
                8:  pulse_seen = done8;
                16: pulse_seen = done16;
            endcase

            check(pulse_seen == 0,
                  "Done pulse lasts exactly one clock cycle");

            stop_all();
        end
    endtask

    initial begin
        rst_n = 0;

        start4  = 0;
        start8  = 0;
        start16 = 0;

        target4  = 0;
        target8  = 0;
        target16 = 0;

        pass_count = 0;
        fail_count = 0;

        $display("");
        $display("==========================================");
        $display(" GENERIC TIMER STANDALONE VERIFICATION");
        $display("==========================================");

        // TEST 1: Reset
        repeat (3) tick;

        check(done4 == 0 &&
              done8 == 0 &&
              done16 == 0,
              "All three timers reset correctly");

        @(negedge clk);
        rst_n = 1;

        // TEST 2: Zero target
        @(negedge clk);
        target8 = 0;
        start8 = 1;

        pulses = 0;

        repeat (5) begin
            tick;
            if (done8)
                pulses = pulses + 1;
        end

        check(pulses == 1,
              "Zero target produces exactly one pulse");

        stop_all();

        // TEST 3: 4-bit timer, target 3
        run_count_test(4, 3);

        // TEST 4: 8-bit timer, target 5
        run_count_test(8, 5);

        // TEST 5: 16-bit timer, target 10
        run_count_test(16, 10);

        // TEST 6: Reset during counting
        @(negedge clk);
        target8 = 10;
        start8 = 1;

        repeat (4) tick;

        @(negedge clk);
        rst_n = 0;

        #1;
        check(done8 == 0 &&
              timer8.count_reg == 0,
              "Reset during counting clears timer");

        @(negedge clk);
        start8 = 0;
        rst_n = 1;

        stop_all();

        // TEST 7: Stop and restart
        @(negedge clk);
        target8 = 4;
        start8 = 1;

        repeat (2) tick;

        @(negedge clk);
        start8 = 0;

        tick;

        check(timer8.count_reg == 0,
              "Dropping start clears timer count");

        @(negedge clk);
        start8 = 1;

        pulses = 0;

        repeat (4) begin
            tick;
            if (done8)
                pulses = pulses + 1;
        end

        check(pulses == 1,
              "Restarted timer completes correctly");

        $display("");
        $display("==========================================");
        $display(" FINAL GENERIC TIMER SUMMARY");
        $display("==========================================");

        $display(" TOTAL PASS = %0d", pass_count);
        $display(" TOTAL FAIL = %0d", fail_count);

        if (fail_count == 0)
            $display(" GENERIC TIMER TEST PASSED");
        else
            $display(" GENERIC TIMER TEST FAILED");

        $display("==========================================");

        $finish;
    end

    // Global watchdog
    initial begin
        #100000;
        $display("FAIL: Simulation timeout");
        $finish;
    end

endmodule
