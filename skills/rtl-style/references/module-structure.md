# Module Structure and Port Alignment

## Port declaration order (mandatory)

1. Clock(s)
2. Reset(s)
3. Inputs (grouped by function)
4. Outputs (grouped by function)
5. Bidirectional (`inout`) — avoid

```systemverilog
module example #(
    parameter int DATA_WIDTH = 32
) (
    // Clock and Reset (always first)
    input  logic clk_i,
    input  logic rst_ni,

    // Control inputs
    input  logic start_i,
    input  logic stop_i,

    // Data inputs
    input  logic [DATA_WIDTH-1:0] data_i,
    input  logic                  valid_i,

    // Status outputs
    output logic busy_o,
    output logic done_o,

    // Data outputs
    output logic [DATA_WIDTH-1:0] result_o,
    output logic                  valid_o
);
```

## Port alignment (mandatory)

Align direction, type/width, name in three columns:

```systemverilog
module aligned_ports (
    input  logic        clk_i,          // System clock
    input  logic        rst_ni,         // Active-low reset
    input  logic [31:0] addr_i,         // Address input
    input  logic [63:0] data_i,         // Data input
    output logic        ready_o,        // Ready signal
    output logic [63:0] result_o        // Computation result
);
```

## Parameterization

Use `parameter` for caller-overridable values, `localparam` for derived values that must not be overridden.

```systemverilog
module parameterized_fifo #(
    parameter int DATA_WIDTH = 32,
    parameter int DEPTH      = 16,
    // Derived — caller cannot override
    localparam int ADDR_WIDTH = $clog2(DEPTH)
) (
    input  logic                  clk_i,
    input  logic                  rst_ni,
    input  logic [DATA_WIDTH-1:0] wdata_i,
    input  logic                  wen_i,
    output logic [DATA_WIDTH-1:0] rdata_o,
    output logic                  full_o,
    output logic                  empty_o
);

    logic [ADDR_WIDTH-1:0] wptr_q, rptr_q;
    logic [DATA_WIDTH-1:0] mem [DEPTH];
endmodule
```

## Internal banner sections

Inside the module body, separate concerns with banner comments:

```systemverilog
    // ========================================================================
    // Local Parameters
    // ========================================================================
    localparam int INTERNAL_WIDTH = PARAM_A + PARAM_B;

    // ========================================================================
    // Signal Declarations
    // ========================================================================
    state_e state_q, state_d;
    logic [INTERNAL_WIDTH-1:0] temp_data;

    // ========================================================================
    // Combinational Logic
    // ========================================================================
    always_comb begin
        // ...
    end

    // ========================================================================
    // Sequential Logic
    // ========================================================================
    always_ff @(posedge clk_i or negedge rst_ni) begin
        // ...
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
        .data_o  (temp_data)
    );
```

## Submodule instantiation — named connections only

```systemverilog
// ✓ Named connections
fifo #(
    .DATA_WIDTH (32),
    .DEPTH      (16)
) u_input_fifo (
    .clk_i   (clk_i),
    .rst_ni  (rst_ni),
    .wdata_i (input_data),
    .wen_i   (input_valid),
    .rdata_o (fifo_data),
    .full_o  (fifo_full)
);

// ❌ Positional — forbidden
fifo u_fifo (clk_i, rst_ni, data, valid, ...);
```

## Continuous assignments (`assign`)

Use `assign` for simple combinational expressions. For multi-line conditions, break and align under the operator:

```systemverilog
// Simple
assign sum       = a + b + c;
assign is_valid  = req_valid && !fifo_full;
assign next_addr = addr_q + INCREMENT;

// Multi-line: each operand on its own line, operator-aligned
assign complex_condition = (state_q == ACTIVE)        &&
                           (counter_q < MAX_COUNT)    &&
                           (!error_flag)              &&
                           (data_valid_i);
```

If the expression is more than ~3 operands or has nested ternaries, move it into an `always_comb` block.

## Assertion blocks (simulation-only)

Wrap `property` / `assert property` / `cover` in tool pragmas so they don't enter synthesis. Both `synopsys translate_off/on` and `` `ifndef SYNTHESIS `` must guard the block — different tools honor different markers.

```systemverilog
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
```

Place assertions at the bottom of the module, after RTL and submodule instantiation.

## Template

`templates/module.sv`.
