// ============================================================================
// File        : qmac_unit_buggy.sv
// Description : Intentionally buggy variant of qmac_unit. DO NOT USE — this
//               file exists only as a regression test for the rtl-reviewer
//               agent. Multiple deliberate style and synthesis violations.
// ============================================================================

module QMacUnitBuggy
#(
    parameter int LANE_NUM  = 4,
    parameter int IN_WIDTH  = 8,
    parameter int OUT_WIDTH = 24
) (
    input  logic                       clk_i,
    input  logic                       rst_ni,
    input  logic signed [IN_WIDTH-1:0] vec_a [LANE_NUM],
    input  logic signed [IN_WIDTH-1:0] vec_b [LANE_NUM],
    input  logic                       valid_i,
    output logic                       ready_o,
    output logic signed [OUT_WIDTH-1:0] sum_o,
    output logic                        valid_o,
    input  logic                        ready_i
);

    logic signed [15:0] product [LANE_NUM];
    logic               valid_reg;
    logic signed [23:0] sum_reg;
    logic [1:0]         mode;
    logic               enable_o;
    integer             i;
    logic               gated_clk;
    logic signed [23:0] temp_sum;
    logic [3:0]         debug;

    // Manual clock gating
    assign gated_clk = clk_i & valid_i;

    // valid_o combinationally depends on ready_i
    assign valid_o = valid_reg && ready_i;
    assign ready_o = !valid_reg;
    assign sum_o   = sum_reg;

    // Async reset missing from sensitivity list; blocking inside always_ff
    always_ff @(posedge clk_i) begin
        if (!rst_ni) begin
            valid_reg <= 1'b0;
        end else begin
            valid_reg = valid_i;
        end
    end

    // Gated clock used as a clock; for-loop creating register array inside always_ff
    always_ff @(posedge gated_clk) begin
        if (!rst_ni) begin
            for (i = 0; i < LANE_NUM; i++) begin
                product[i] <= '0;
            end
        end else begin
            for (i = 0; i < LANE_NUM; i++) begin
                product[i] <= vec_a[i] * vec_b[i];
            end
        end
    end

    // always @* instead of always_comb; for-loop produces serial accumulator
    always @* begin
        temp_sum = '0;
        for (i = 0; i < LANE_NUM; i++) begin
            temp_sum = temp_sum + product[i];
        end
    end

    // case missing default -> latch on enable_o
    always_comb begin
        case (mode)
            2'b00: enable_o = 1'b1;
            2'b01: enable_o = 1'b0;
        endcase
    end

    // x in synthesizable code
    assign debug = 4'bxxxx;

    // sum_reg has no reset initial value
    always_ff @(posedge clk_i) begin
        sum_reg <= temp_sum;
    end

endmodule
