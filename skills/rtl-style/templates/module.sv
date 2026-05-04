// ============================================================================
// Copyright (c) YYYY Company Name
// File        : <module_name>.sv
// Description : <一兩句話描述模組功能>
// Author      : <Author Name>
// Created     : YYYY-MM-DD
// ============================================================================

`include "common_defines.svh"

module <module_name>
    import common_pkg::*;
#(
    parameter int PARAM_A = 32,
    parameter int PARAM_B = 64,
    // 衍生參數（不可由外部覆寫）
    localparam int INTERNAL_WIDTH = PARAM_A + PARAM_B
) (
    // ========================================================================
    // Clock and Reset
    // ========================================================================
    input  logic clk_i,
    input  logic rst_ni,

    // ========================================================================
    // Control Inputs
    // ========================================================================
    input  logic start_i,
    input  logic stop_i,

    // ========================================================================
    // Data Inputs
    // ========================================================================
    input  logic [PARAM_A-1:0] data_i,
    input  logic               valid_i,
    output logic               ready_o,

    // ========================================================================
    // Status Outputs
    // ========================================================================
    output logic busy_o,
    output logic done_o,

    // ========================================================================
    // Data Outputs
    // ========================================================================
    output logic [PARAM_B-1:0] result_o,
    output logic               valid_o,
    output logic               error_o
);

    // ========================================================================
    // Local Parameters
    // ========================================================================
    localparam int COUNTER_MAX = 100;

    // ========================================================================
    // Type Definitions
    // ========================================================================
    typedef enum logic [1:0] {
        IDLE   = 2'b00,
        ACTIVE = 2'b01,
        DONE   = 2'b10,
        ERROR  = 2'b11
    } state_e;

    // ========================================================================
    // Signal Declarations
    // ========================================================================
    state_e state_q, state_d;

    logic [INTERNAL_WIDTH-1:0] temp_data;
    logic                      internal_valid;

    // ========================================================================
    // Combinational Logic — Next State and Outputs
    // ========================================================================
    always_comb begin
        // Default assignments (avoid latch)
        state_d  = state_q;
        result_o = '0;
        busy_o   = 1'b0;
        done_o   = 1'b0;
        error_o  = 1'b0;

        case (state_q)
            IDLE: begin
                if (valid_i && start_i) begin
                    state_d = ACTIVE;
                end
            end

            ACTIVE: begin
                busy_o = 1'b1;
                if (internal_valid) begin
                    state_d = DONE;
                end
            end

            DONE: begin
                done_o   = 1'b1;
                result_o = temp_data[PARAM_B-1:0];
                state_d  = IDLE;
            end

            ERROR: begin
                error_o = 1'b1;
                if (stop_i) state_d = IDLE;
            end

            default: state_d = IDLE;
        endcase
    end

    assign ready_o = (state_q == IDLE);
    assign valid_o = (state_q == DONE);

    // ========================================================================
    // Sequential Logic
    // ========================================================================
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            state_q <= IDLE;
        end else begin
            state_q <= state_d;
        end
    end

    // ========================================================================
    // Submodule Instantiation
    // ========================================================================
    sub_module #(
        .PARAM_X (PARAM_A),
        .PARAM_Y (PARAM_B)
    ) u_sub_module (
        .clk_i   (clk_i),
        .rst_ni  (rst_ni),
        .data_i  (data_i),
        .valid_i (valid_i),
        .data_o  (temp_data),
        .valid_o (internal_valid)
    );

    // ========================================================================
    // Assertions (simulation-only)
    // ========================================================================
    // synopsys translate_off
    `ifndef SYNTHESIS

    property p_valid_stable;
        @(posedge clk_i) disable iff (!rst_ni)
        valid_o && !ready_i |=> $stable(result_o);
    endproperty

    assert property (p_valid_stable)
        else $error("Result changed while valid is high");

    `endif
    // synopsys translate_on

endmodule : <module_name>
