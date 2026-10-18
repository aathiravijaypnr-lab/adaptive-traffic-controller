
`timescale 1ns/1ps

module generic_timer #(
    parameter COUNTER_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [COUNTER_WIDTH-1:0] count_target,
    output reg done
);

    reg [COUNTER_WIDTH-1:0] count_reg;
    reg [COUNTER_WIDTH-1:0] previous_target;
    reg zero_done_flag;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_reg      <= {COUNTER_WIDTH{1'b0}};
            previous_target <= {COUNTER_WIDTH{1'b0}};
            done           <= 1'b0;
            zero_done_flag <= 1'b0;
        end else begin
            done <= 1'b0;

            if (!start) begin
                count_reg       <= {COUNTER_WIDTH{1'b0}};
                previous_target <= count_target;
                zero_done_flag  <= 1'b0;
            end else if (count_target != previous_target) begin
                count_reg       <= {COUNTER_WIDTH{1'b0}};
                previous_target <= count_target;
                zero_done_flag  <= 1'b0;
            end else if (count_target == {COUNTER_WIDTH{1'b0}}) begin
                count_reg <= {COUNTER_WIDTH{1'b0}};

                if (!zero_done_flag) begin
                    done <= 1'b1;
                    zero_done_flag <= 1'b1;
                end
            end else begin
                zero_done_flag <= 1'b0;

                if (count_reg >= count_target - 1'b1) begin
                    count_reg <= {COUNTER_WIDTH{1'b0}};
                    done <= 1'b1;
                end else begin
                    count_reg <= count_reg + 1'b1;
                end
            end
        end
    end

endmodule

