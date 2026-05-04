// ============================================================================
// Pipeline with Valid-Ready Backpressure Template
// Three-stage pipeline: input register -> processing -> output register
// Supports stall and flush
// ============================================================================

module pipeline_with_backpressure #(
    parameter int DATA_WIDTH = 32
) (
    input  logic                  clk_i,
    input  logic                  rst_ni,

    // Control
    input  logic                  flush_i,

    // Input interface (valid-ready)
    input  logic [DATA_WIDTH-1:0] data_i,
    input  logic                  valid_i,
    output logic                  ready_o,

    // Output interface (valid-ready)
    output logic [DATA_WIDTH-1:0] data_o,
    output logic                  valid_o,
    input  logic                  ready_i
);

    // ========================================================================
    // Stage 1: Input Register
    // ========================================================================
    logic [DATA_WIDTH-1:0] s1_data_q;
    logic                  s1_valid_q;
    logic                  s1_ready;

    assign s1_ready = !s1_valid_q || s2_ready;
    assign ready_o  = s1_ready;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            s1_data_q  <= '0;
            s1_valid_q <= 1'b0;
        end else if (flush_i) begin
            s1_valid_q <= 1'b0;
        end else if (s1_ready) begin
            s1_data_q  <= data_i;
            s1_valid_q <= valid_i;
        end
    end

    // ========================================================================
    // Stage 2: Processing
    // ========================================================================
    logic [DATA_WIDTH-1:0] s2_data_d, s2_data_q;
    logic                  s2_valid_q;
    logic                  s2_ready;

    // Combinational processing
    always_comb begin
        s2_data_d = (s1_data_q << 1) + 1'b1;    // example: x*2 + 1
    end

    assign s2_ready = !s2_valid_q || s3_ready;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            s2_data_q  <= '0;
            s2_valid_q <= 1'b0;
        end else if (flush_i) begin
            s2_valid_q <= 1'b0;
        end else if (s2_ready) begin
            s2_data_q  <= s2_data_d;
            s2_valid_q <= s1_valid_q;
        end
    end

    // ========================================================================
    // Stage 3: Output Register
    // ========================================================================
    logic [DATA_WIDTH-1:0] s3_data_q;
    logic                  s3_valid_q;
    logic                  s3_ready;

    assign s3_ready = !s3_valid_q || ready_i;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            s3_data_q  <= '0;
            s3_valid_q <= 1'b0;
        end else if (flush_i) begin
            s3_valid_q <= 1'b0;
        end else if (s3_ready) begin
            s3_data_q  <= s2_data_q;
            s3_valid_q <= s2_valid_q;
        end
    end

    // ========================================================================
    // Output
    // ========================================================================
    assign data_o  = s3_data_q;
    assign valid_o = s3_valid_q;

endmodule : pipeline_with_backpressure
