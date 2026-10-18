
`timescale 1ns/1ps

module ped_arbiter (
    input  wire clk,
    input  wire rst_n,

    input  wire req_a,
    input  wire req_b,

    input  wire ready_a,
    input  wire ready_b,

    output reg grant_a,
    output reg grant_b
);

    // 0 = Junction A has priority.
    // 1 = Junction B has priority.
    reg turn;

    always @(posedge clk) begin
        if (!rst_n) begin
            grant_a <= 1'b0;
            grant_b <= 1'b0;
            turn    <= 1'b0;
        end
        else begin
            // Clear grants by default.
            grant_a <= 1'b0;
            grant_b <= 1'b0;

            case ({ready_a, ready_b})

                // Only Junction A is ready.
                2'b10: begin
                    if (req_a) begin
                        grant_a <= 1'b1;
                        turn    <= 1'b1;
                    end
                end

                // Only Junction B is ready.
                2'b01: begin
                    if (req_b) begin
                        grant_b <= 1'b1;
                        turn    <= 1'b0;
                    end
                end

                // Both junctions are ready.
                2'b11: begin
                    if (turn == 1'b0) begin
                        if (req_a) begin
                            grant_a <= 1'b1;
                            turn    <= 1'b1;
                        end
                        else if (req_b) begin
                            grant_b <= 1'b1;
                            turn    <= 1'b0;
                        end
                    end
                    else begin
                        if (req_b) begin
                            grant_b <= 1'b1;
                            turn    <= 1'b0;
                        end
                        else if (req_a) begin
                            grant_a <= 1'b1;
                            turn    <= 1'b1;
                        end
                    end
                end

                default: begin
                    grant_a <= 1'b0;
                    grant_b <= 1'b0;
                end

            endcase
        end
    end

endmodule

