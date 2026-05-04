// ============================================================================
// Three-process FSM template
//   Process 1 (sequential)  : state register
//   Process 2 (combinational): next-state logic
//   Process 3 (combinational): output logic (Moore)
// ============================================================================

module fsm_example (
    input  logic clk_i,
    input  logic rst_ni,

    // FSM inputs
    input  logic start_i,
    input  logic fetch_done_i,
    input  logic fetch_error_i,
    input  logic exec_done_i,
    input  logic wb_done_i,
    input  logic error_clear_i,

    // FSM outputs
    output logic fetch_en_o,
    output logic exec_en_o,
    output logic wb_en_o,
    output logic error_o
);

    // ========================================================================
    // State Type Definition
    // ========================================================================
    typedef enum logic [2:0] {
        IDLE       = 3'b001,
        FETCH      = 3'b010,
        EXECUTE    = 3'b011,
        WRITE_BACK = 3'b100,
        ERROR      = 3'b101
    } state_e;

    state_e state_q, state_d;

    // ========================================================================
    // Process 1: State Register (sequential)
    // ========================================================================
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            state_q <= IDLE;
        end else begin
            state_q <= state_d;
        end
    end

    // ========================================================================
    // Process 2: Next-State Logic (combinational)
    // ========================================================================
    always_comb begin
        // Default: stay in current state
        state_d = state_q;

        case (state_q)
            IDLE: begin
                if (start_i) state_d = FETCH;
            end

            FETCH: begin
                if      (fetch_error_i) state_d = ERROR;
                else if (fetch_done_i)  state_d = EXECUTE;
            end

            EXECUTE: begin
                if (exec_done_i) state_d = WRITE_BACK;
            end

            WRITE_BACK: begin
                if (wb_done_i) state_d = IDLE;
            end

            ERROR: begin
                if (error_clear_i) state_d = IDLE;
            end

            default: state_d = IDLE;
        endcase
    end

    // ========================================================================
    // Process 3: Output Logic (combinational, Moore-style)
    // ========================================================================
    always_comb begin
        // Default outputs (avoid latch)
        fetch_en_o = 1'b0;
        exec_en_o  = 1'b0;
        wb_en_o    = 1'b0;
        error_o    = 1'b0;

        case (state_q)
            IDLE:       /* nothing */;
            FETCH:      fetch_en_o = 1'b1;
            EXECUTE:    exec_en_o  = 1'b1;
            WRITE_BACK: wb_en_o    = 1'b1;
            ERROR:      error_o    = 1'b1;
            default:    /* nothing */;
        endcase
    end

endmodule : fsm_example
