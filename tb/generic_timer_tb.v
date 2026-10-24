`timescale 1ns/1ps

module generic_timer_tb;

    // Parameters
    parameter COUNTER_WIDTH = 8;
    parameter CLK_PERIOD    = 10; // 10ns clock -> 100MHz

    // Testbench signals
    reg                      clk;
    reg                      rst_n;
    reg                      start;
    reg  [COUNTER_WIDTH-1:0] count_target;
    wire                     done;

    // Instantiate the generic_timer module under test
    generic_timer #(
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .count_target(count_target),
        .done(done)
    );

    // Clean clock generation
    initial clk = 1'b0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // Test stimulus sequence
    initial begin
        // Initialize signals
        rst_n        = 1'b0;
        start        = 1'b0;
        count_target = 0;

        // Apply active-low reset
        #(CLK_PERIOD * 3);
        rst_n = 1'b1;
        @(posedge clk);

        $display("=== STARTING GENERIC_TIMER WAVEFORM SIMULATION ===");

        // Test 1: Target = 0
        $display("Time %0t: Testing Target = 0", $time);
        count_target = 0;
        start        = 1'b1;
        #(CLK_PERIOD * 3);
        start        = 1'b0;
        #(CLK_PERIOD * 2);

        // Test 2: Target = 3
        $display("Time %0t: Testing Target = 3", $time);
        count_target = 3;
        start        = 1'b1;
        @(posedge done);
        $display("Time %0t: Target 3 reached, done pulsed.", $time);
        @(posedge clk);
        start        = 1'b0;
        #(CLK_PERIOD * 2);

        // Test 3: Target = 5
        $display("Time %0t: Testing Target = 5", $time);
        count_target = 5;
        start        = 1'b1;
        @(posedge done);
        $display("Time %0t: Target 5 reached, done pulsed.", $time);
        @(posedge clk);
        start        = 1'b0;
        #(CLK_PERIOD * 2);

        // Test 4: Target = 8
        $display("Time %0t: Testing Target = 8", $time);
        count_target = 8;
        start        = 1'b1;
        @(posedge done);
        $display("Time %0t: Target 8 reached, done pulsed.", $time);
        @(posedge clk);
        start        = 1'b0;
        #(CLK_PERIOD * 2);

        // Test 5: Reset while counting
        $display("Time %0t: Testing Reset while counting (Target = 10)", $time);
        count_target = 10;
        start        = 1'b1;
        #(CLK_PERIOD * 4); // Let it count halfway
        $display("Time %0t: Asserting reset mid-count.", $time);
        rst_n        = 1'b0;
        #(CLK_PERIOD * 3);
        rst_n        = 1'b1;
        start        = 1'b0;
        #(CLK_PERIOD * 2);

        // Test 6: Stop and Restart
        $display("Time %0t: Testing stop and restart behavior (Target = 4)", $time);
        count_target = 4;
        start        = 1'b1;
        #(CLK_PERIOD * 2);
        $display("Time %0t: Dropping start (interrupting timer).", $time);
        start        = 1'b0;
        #(CLK_PERIOD * 3);
        $display("Time %0t: Re-asserting start (restarting timer).", $time);
        start        = 1'b1;
        @(posedge done);
        $display("Time %0t: Restarted target 4 reached, done pulsed.", $time);

        #(CLK_PERIOD * 5);
        $display("=== SIMULATION COMPLETED ===");
        $finish;
    end

endmodule
