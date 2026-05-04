# Generate vs For

## Decision rule

| Use case | Use |
|----------|-----|
| Parallel hardware instances | **`generate`** |
| Tree structures (adder tree, XOR tree) | **`generate`** |
| Repeated register/logic arrays | **`generate`** |
| Conditional hardware | **`generate if`** |
| Testbench iteration | `for` |
| `initial` block init | `for` |
| Function-internal accumulation | `for` (sparingly) |

## Comparison

| Aspect | `generate` | `for` |
|--------|-----------|-------|
| Expansion | Elaboration time | Run time |
| Result | Parallel hardware | Cascaded logic / iteration |
| Synthesizable | ✓ Fully | ⚠️ Partially |
| Timing | Parallel, no extra delay | Long combinational paths possible |

## generate — parallel instances

```systemverilog
module parallel_adders #(
    parameter int N  = 8,
    parameter int DW = 32
) (
    input  logic [DW-1:0] a_i [N],
    input  logic [DW-1:0] b_i [N],
    output logic [DW-1:0] sum_o [N]
);
    genvar i;
    generate
        for (i = 0; i < N; i++) begin : gen_adders
            assign sum_o[i] = a_i[i] + b_i[i];
        end
    endgenerate
endmodule
```

## generate — parallel FF array

```systemverilog
genvar i;
generate
    for (i = 0; i < 8; i++) begin : gen_regs
        always_ff @(posedge clk_i or negedge rst_ni) begin
            if (!rst_ni) data_o[i] <= '0;
            else         data_o[i] <= data_i[i];
        end
    end
endgenerate
```

## generate — adder tree

```systemverilog
// 16 → 8 → 4 → 2 → 1, log2(N) levels
logic [8:0]  level1 [8];
logic [9:0]  level2 [4];
logic [10:0] level3 [2];

genvar i;
generate
    for (i = 0; i < 8; i++) begin : gen_l1
        assign level1[i] = {1'b0, data_i[2*i]} + {1'b0, data_i[2*i+1]};
    end
    for (i = 0; i < 4; i++) begin : gen_l2
        assign level2[i] = {1'b0, level1[2*i]} + {1'b0, level1[2*i+1]};
    end
    for (i = 0; i < 2; i++) begin : gen_l3
        assign level3[i] = {1'b0, level2[2*i]} + {1'b0, level2[2*i+1]};
    end
endgenerate
assign sum_o = {1'b0, level3[0]} + {1'b0, level3[1]};
```

## Conditional generate

```systemverilog
generate
    if (USE_PIPELINE) begin : gen_pipelined
        always_ff @(posedge clk_i) data_o <= data_i;
    end else begin : gen_combinational
        assign data_o = data_i;
    end
endgenerate
```

## Anti-pattern: for inside always (produces unintended hardware)

```systemverilog
// ❌ Shared-counter risk
integer i;
always_ff @(posedge clk_i) begin
    for (i = 0; i < 8; i++) data_o[i] <= data_i[i];
end

// ❌ 8-level cascaded adder
always_comb begin
    sum = '0;
    for (i = 0; i < 8; i++) sum = sum + data[i];
end
```

## Anti-pattern: for-loop selector

```systemverilog
// ❌
always_comb begin
    data_o = '0;
    for (i = 0; i < 8; i++) begin
        if (i == sel_i) data_o = data_i[i];
    end
end

// ✓ Direct index
assign data_o = data_i[sel_i];

// ✓ Or case
always_comb begin
    case (sel_i)
        3'd0: data_o = data_i[0];
        3'd1: data_o = data_i[1];
        // ...
        default: data_o = '0;
    endcase
end
```

## Generate naming (mandatory)

```systemverilog
// All generate blocks must be named (waveform/back-trace requires it)
genvar i;
generate
    for (i = 0; i < N; i++) begin : gen_units    // <- required
        processing_unit u_unit ( ... );
    end
endgenerate

// All branches of conditional generate must be named
generate
    if (COND) begin : gen_path_a
        // ...
    end else begin : gen_path_b
        // ...
    end
endgenerate
```

## Nested generate

```systemverilog
// 2D mesh
genvar row, col;
generate
    for (row = 0; row < ROWS; row++) begin : gen_rows
        for (col = 0; col < COLS; col++) begin : gen_cols
            router #(
                .X_COORD (col),
                .Y_COORD (row)
            ) u_router ( ... );
        end
    end
endgenerate
// Cap nesting at 3 levels.
```
