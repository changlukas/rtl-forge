// ============================================================================
// File        : qmac_unit.sv
// Description : 4-lane signed Multiply-Accumulate (MAC) unit. DNN inference
//               primitive computing the dot product of two LANE_NUM-element
//               signed vectors. Two-stage pipeline with valid-ready handshake.
//                 Stage 1: parallel 8b x 8b signed multiplies.
//                 Stage 2: adder tree summation -> 24b signed sum.
// Author      : Lucas
// Created     : 2026-05-04
// ============================================================================

module qmac_unit
#(
    parameter  int LANE_NUM   = 4,
    parameter  int IN_WIDTH   = 8,
    parameter  int OUT_WIDTH  = 24,
    // Derived widths
    localparam int PROD_WIDTH = 2 * IN_WIDTH,                  // 16
    localparam int TREE_LVL   = $clog2(LANE_NUM),              // 2 for LANE_NUM=4
    localparam int SUM_WIDTH  = PROD_WIDTH + TREE_LVL          // 18
) (
    // ========================================================================
    // Clock and Reset
    // ========================================================================
    input  logic                       clk_i,
    input  logic                       rst_ni,

    // ========================================================================
    // Input Interface (valid-ready)
    // ========================================================================
    input  logic signed [IN_WIDTH-1:0] vec_a_i [LANE_NUM],
    input  logic signed [IN_WIDTH-1:0] vec_b_i [LANE_NUM],
    input  logic                       valid_i,
    output logic                       ready_o,

    // ========================================================================
    // Output Interface (valid-ready)
    // ========================================================================
    output logic signed [OUT_WIDTH-1:0] sum_o,
    output logic                        valid_o,
    input  logic                        ready_i
);

    // ========================================================================
    // Pipeline Backpressure Signals
    // ========================================================================
    logic s1_ready;
    logic s2_ready;

    // ========================================================================
    // Stage 1: Parallel Multiply (LANE_NUM lanes, signed 8b x 8b -> 16b)
    // ========================================================================
    logic signed [PROD_WIDTH-1:0] s1_prod_q  [LANE_NUM];
    logic                         s1_valid_q;

    // Stage 1 can advance when empty, or when stage 2 is ready
    assign s1_ready = !s1_valid_q || s2_ready;
    assign ready_o  = s1_ready;

    // Parallel multiplier instances (one per lane)
    genvar i;
    generate
        for (i = 0; i < LANE_NUM; i++) begin : gen_mult
            always_ff @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni) begin
                    s1_prod_q[i] <= '0;
                end else if (s1_ready) begin
                    s1_prod_q[i] <= vec_a_i[i] * vec_b_i[i];
                end
            end
        end
    endgenerate

    // Stage 1 valid register
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            s1_valid_q <= 1'b0;
        end else if (s1_ready) begin
            s1_valid_q <= valid_i;
        end
    end

    // ========================================================================
    // Stage 2: Adder Tree (combinational) -> Output Register
    //   Level 1: LANE_NUM (16b) -> LANE_NUM/2 (17b)
    //   Level 2: LANE_NUM/2 (17b) -> 1 (18b)
    //   Sign-extend 18b -> 24b on register
    // ========================================================================
    logic signed [PROD_WIDTH:0]    s2_l1_d [LANE_NUM/2];   // 17b
    logic signed [SUM_WIDTH-1:0]   s2_sum_d;               // 18b
    logic signed [OUT_WIDTH-1:0]   s2_sum_q;
    logic                          s2_valid_q;

    // Stage 2 can advance when empty, or when downstream is ready
    assign s2_ready = !s2_valid_q || ready_i;

    // Level 1 of adder tree: pairwise sums (explicit 1-bit sign extension)
    generate
        for (i = 0; i < LANE_NUM/2; i++) begin : gen_tree_l1
            assign s2_l1_d[i] = {s1_prod_q[2*i][PROD_WIDTH-1],   s1_prod_q[2*i]}
                              + {s1_prod_q[2*i+1][PROD_WIDTH-1], s1_prod_q[2*i+1]};
        end
    endgenerate

    // Level 2: final pair sum (explicit 1-bit sign extension)
    assign s2_sum_d = {s2_l1_d[0][PROD_WIDTH], s2_l1_d[0]}
                    + {s2_l1_d[1][PROD_WIDTH], s2_l1_d[1]};

    // Stage 2 register (sign-extend 18b -> 24b)
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            s2_sum_q   <= '0;
            s2_valid_q <= 1'b0;
        end else if (s2_ready) begin
            // Explicit sign-extend SUM_WIDTH (18b) -> OUT_WIDTH (24b)
            s2_sum_q   <= {{(OUT_WIDTH-SUM_WIDTH){s2_sum_d[SUM_WIDTH-1]}}, s2_sum_d};
            s2_valid_q <= s1_valid_q;
        end
    end

    // ========================================================================
    // Output
    // ========================================================================
    assign sum_o   = s2_sum_q;
    assign valid_o = s2_valid_q;

    // ========================================================================
    // Assertions (simulation-only)
    // ========================================================================
    // synopsys translate_off
    `ifndef SYNTHESIS

    // valid_o must remain stable while not handshook
    property p_valid_stable;
        @(posedge clk_i) disable iff (!rst_ni)
        valid_o && !ready_i |=> valid_o && $stable(sum_o);
    endproperty

    assert property (p_valid_stable)
        else $error("qmac_unit: sum_o changed while valid_o asserted without handshake");

    `endif
    // synopsys translate_on

endmodule : qmac_unit
