
`timescale 1ns/1ps

module green_wave_sync #(
    parameter integer OFFSET_CYCLES = 4
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [2:0] state_a,
    output reg        sync_trigger_b
);

    localparam [2:0] ST_NS_GREEN = 3'b001;

    reg [2:0] prev_state_a;
    integer count;
    reg counting;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_state_a   <= 3'b000;
            sync_trigger_b <= 1'b0;
            count          <= 0;
            counting       <= 1'b0;
        end
        else begin
            prev_state_a   <= state_a;
            sync_trigger_b <= 1'b0;

            if ((state_a == ST_NS_GREEN) &&
                (prev_state_a != ST_NS_GREEN)) begin
                count    <= 0;
                counting <= 1'b1;
            end
            else if (counting) begin
                if (count == OFFSET_CYCLES - 1) begin
                    sync_trigger_b <= 1'b1;
                    counting       <= 1'b0;
                    count          <= 0;
                end
                else begin
                    count <= count + 1;
                end
            end
        end
    end

endmodule

