# Arithmetic and Logic Optimization

## Overview

| Technique | When to use | Effect |
|-----------|-------------|--------|
| Shift instead of constant multiply | Multiply by 2^n or (2^n ± 1) | No multiplier |
| CSA adder | ≥3 operands | Reduced delay |
| Reciprocal multiply | Divide by constant | No divider |
| Pipeline retiming | High throughput | Higher Fmax |
| Resource sharing | Mutually-exclusive ops | Less area |
| LUT | Complex small functions | Less logic |
| Gray code | CDC counters | Lower metastability risk |
| Clock gating (ICG cells) | Conditional updates | Lower power |
| Operand isolation | Idle datapath | Lower power |

## Constant multiplication via shifts

```systemverilog
// Multiply by power of 2: shift
assign result = data << 3;          // data * 8

// Multiply by (2^n ± 1): shift + add/sub
// data * 3  = (data << 1) + data
// data * 5  = (data << 2) + data
// data * 7  = (data << 3) - data
// data * 9  = (data << 3) + data
// data * 15 = (data << 4) - data
// data * 17 = (data << 4) + data
// data * 31 = (data << 5) - data

assign mul3 = (data << 1) + data;
assign mul7 = (data << 3) - data;
```

## CSA (Carry-Save Adder) tree

For multi-operand sums (e.g. `a + b + c + d`), use 3:2 compressors to cut delay:

```systemverilog
// Layer 1: a + b + c → sum + carry
logic [31:0] s1_sum, s1_carry;
assign s1_sum   = a_i ^ b_i ^ c_i;
assign s1_carry = ((a_i & b_i) | (b_i & c_i) | (c_i & a_i)) << 1;

// Layer 2: sum + carry + d
logic [31:0] s2_sum, s2_carry;
assign s2_sum   = s1_sum ^ s1_carry ^ d_i;
assign s2_carry = ((s1_sum & s1_carry) | (s1_carry & d_i) | (d_i & s1_sum)) << 1;

// Final: carry-propagate adder
assign sum_o = s2_sum + s2_carry;
```

## Saturating add

```systemverilog
logic [WIDTH:0] temp_sum;       // one extra bit detects overflow
assign temp_sum = {1'b0, a_i} + {1'b0, b_i};
assign sum_o    = temp_sum[WIDTH] ? {WIDTH{1'b1}} : temp_sum[WIDTH-1:0];
```

## Division optimization

```systemverilog
// Divide by power of 2: shift
assign result = data >>> 4;     // signed   / 16
assign result = data >>  4;     // unsigned / 16

// Divide by constant ≈ multiply by reciprocal (fixed-point)
// x / 3 ≈ (x * 0x55555556) >> 32
localparam logic [31:0] RECIPROCAL = 32'h55555556;
logic [63:0] product;
assign product    = dividend_i * RECIPROCAL;
assign quotient_o = product[63:32];
```

## Iterative non-restoring divider

When variable-divisor division is required, build an FSM-based iterative divider — one bit per cycle, `WIDTH` cycles per division. Avoids a fully-combinational divider's latency / area cost.

```systemverilog
typedef enum logic [1:0] { IDLE, COMPUTE, DONE } div_state_e;

div_state_e        state_q, state_d;
logic [WIDTH-1:0]  quotient_q,  quotient_d;
logic [2*WIDTH-1:0] remainder_q, remainder_d;
logic [5:0]        counter_q,   counter_d;

always_comb begin
    state_d     = state_q;
    quotient_d  = quotient_q;
    remainder_d = remainder_q;
    counter_d   = counter_q;
    valid_o     = 1'b0;
    div_by_zero_o = 1'b0;

    case (state_q)
        IDLE: if (start_i) begin
            if (divisor_i == '0) begin
                state_d       = DONE;
                div_by_zero_o = 1'b1;
            end else begin
                state_d     = COMPUTE;
                remainder_d = {{WIDTH{1'b0}}, dividend_i};
                quotient_d  = '0;
                counter_d   = WIDTH;
            end
        end

        COMPUTE: begin
            remainder_d = remainder_q << 1;
            if (remainder_d[2*WIDTH-1:WIDTH] >= divisor_i) begin
                remainder_d[2*WIDTH-1:WIDTH] = remainder_d[2*WIDTH-1:WIDTH] - divisor_i;
                quotient_d = (quotient_q << 1) | 1'b1;
            end else begin
                quotient_d = quotient_q << 1;
            end
            counter_d = counter_q - 1'b1;
            if (counter_q == 1) state_d = DONE;
        end

        DONE: begin
            valid_o = 1'b1;
            if (start_i) state_d = IDLE;
        end
    endcase
end
```

## Comparator via subtraction

A subtractor's sign and zero flags give all three comparisons for free:

```systemverilog
logic [32:0] diff;
assign diff = {1'b0, a_i} - {1'b0, b_i};

assign a_gt_b = !diff[32] && |diff[31:0];
assign a_eq_b = ~|diff;
assign a_lt_b = diff[32];
```

## Wide-comparator partitioning

For very wide comparators (≥64 bits), split into chunks to reduce fan-in and improve timing:

```systemverilog
module fast_comparator_64 (
    input  logic [63:0] a_i,
    input  logic [63:0] b_i,
    output logic        equal_o,
    output logic        greater_o
);
    logic [3:0] eq_part, gt_part;

    genvar i;
    generate
        for (i = 0; i < 4; i++) begin : gen_compare
            assign eq_part[i] = (a_i[i*16+:16] == b_i[i*16+:16]);
            assign gt_part[i] = (a_i[i*16+:16] >  b_i[i*16+:16]);
        end
    endgenerate

    assign equal_o   = &eq_part;
    assign greater_o = gt_part[3]                                              ||
                       (eq_part[3] && gt_part[2])                              ||
                       (eq_part[3] && eq_part[2] && gt_part[1])                ||
                       (eq_part[3] && eq_part[2] && eq_part[1] && gt_part[0]);
endmodule
```

## Leading Zero Count (LZC)

```systemverilog
always_comb begin
    lzc_o      = 6'd32;
    all_zero_o = 1'b1;
    for (int i = 31; i >= 0; i--) begin
        if (data_i[i]) begin
            lzc_o      = 31 - i;
            all_zero_o = 1'b0;
            break;
        end
    end
end
```

## Population count (tree)

```systemverilog
// 32-bit popcount as a tree (not a ripple)
logic [1:0] s1 [16];
logic [2:0] s2 [8];
logic [3:0] s3 [4];
logic [4:0] s4 [2];

genvar i;
generate
    for (i = 0; i < 16; i++) begin : gen_l1
        assign s1[i] = data_i[2*i] + data_i[2*i+1];
    end
    for (i = 0; i < 8; i++) begin : gen_l2
        assign s2[i] = s1[2*i] + s1[2*i+1];
    end
    for (i = 0; i < 4; i++) begin : gen_l3
        assign s3[i] = s2[2*i] + s2[2*i+1];
    end
    for (i = 0; i < 2; i++) begin : gen_l4
        assign s4[i] = s3[2*i] + s3[2*i+1];
    end
endgenerate
assign count_o = s4[0] + s4[1];
```

## Piecewise-linear LUT approximation

For monotonic non-linear functions (sqrt, log, sin), partition the input range into N segments and store base + slope per segment. Reduces both ROM size and runtime cost vs a full LUT.

```systemverilog
module sqrt_approx (
    input  logic [15:0] x_i,
    output logic [7:0]  sqrt_o
);
    logic [3:0] segment;     // top 4 bits select segment
    logic [3:0] offset;      // next 4 bits interpolate

    assign segment = x_i[15:12];
    assign offset  = x_i[11:8];

    logic [7:0] base  [16];
    logic [7:0] slope [16];

    // Initialize base[]/slope[] from a header file or `initial` block.

    // sqrt(x) ≈ base[seg] + slope[seg] * offset
    assign sqrt_o = base[segment] + ((slope[segment] * offset) >> 4);
endmodule
```

## Gray-code counter (CDC-friendly)

```systemverilog
logic [WIDTH-1:0] binary_q;

always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni)         binary_q <= '0;
    else if (enable_i)   binary_q <= binary_q + 1'b1;
end

assign gray_o   = binary_q ^ (binary_q >> 1);   // binary → gray
assign binary_o = binary_q;
```

## Pipeline retiming

```systemverilog
// ❌ Long combinational path
always_ff @(posedge clk_i) begin
    result_q <= ((a_i * 2) + 100) << 3;     // too much per cycle
end

// ✓ Split into stages
always_ff @(posedge clk_i) begin
    s1_q <= a_i * 2;
    s2_q <= s1_q + 100;
    s3_q <= s2_q << 3;
end
```

Prefer letting the synthesis tool retime; manual stage splitting is the second resort.

## Operand isolation (power)

```systemverilog
// Force operands to 0 when idle to suppress internal toggling
assign a_gated = enable_i ? a_i : '0;
assign b_gated = enable_i ? b_i : '0;
assign result  = a_gated * b_gated;
```

## Resource sharing — ALU

```systemverilog
// Single shared adder serves multiple ops
logic [31:0] op1, op2;
always_comb begin
    case (sel_i)
        2'b00: begin op1 = a_i; op2 = b_i;             end  // a + b
        2'b01: begin op1 = a_i; op2 = ~b_i + 1'b1;     end  // a - b
        default: begin op1 = '0; op2 = '0;             end
    endcase
end
assign alu_result = (sel_i == 2'b10) ? (op1 & op2) : (op1 + op2);
```

## Time-division multiplexing (TDM)

When several channels share a heavy operator (multiplier, divider) and channel rate ≪ clock rate, multiplex one operator across channels:

```systemverilog
module tdm_multiplier #(
    parameter int NUM_CHANNELS = 4,
    parameter int DATA_WIDTH   = 16
) (
    input  logic                    clk_i,
    input  logic                    rst_ni,
    input  logic [DATA_WIDTH-1:0]   data_i  [NUM_CHANNELS],
    input  logic [DATA_WIDTH-1:0]   coeff_i [NUM_CHANNELS],
    output logic [2*DATA_WIDTH-1:0] result_o[NUM_CHANNELS]
);
    logic [$clog2(NUM_CHANNELS)-1:0] channel_q;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) channel_q <= '0;
        else         channel_q <= (channel_q == NUM_CHANNELS-1) ? '0
                                                                : channel_q + 1'b1;
    end

    logic [DATA_WIDTH-1:0]   mul_a, mul_b;
    logic [2*DATA_WIDTH-1:0] mul_result;

    assign mul_a      = data_i [channel_q];
    assign mul_b      = coeff_i[channel_q];
    assign mul_result = mul_a * mul_b;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) foreach (result_o[i]) result_o[i] <= '0;
        else         result_o[channel_q] <= mul_result;
    end
endmodule
```

## Fixed-point multiply (Q format)

```systemverilog
// Q8.8 × Q8.8 → Q16.16; take middle 16 bits to recover Q8.8
logic signed [31:0] temp_prod;
assign temp_prod = a_i * b_i;
assign prod_o    = temp_prod[23:8];
// Round-to-nearest: assign prod_o = temp_prod[23:8] + temp_prod[7];
```

## Tool notes

- ASIC synthesis tools auto-infer Booth / Wallace tree multipliers — write `a * b`, let the tool decide.
- FPGA tools auto-map multiplies to DSP blocks.
- **Never roll your own clock gating** — use the library's ICG cell.
- Prefer letting the synthesis tool do retiming; manual stage splitting is fallback.
