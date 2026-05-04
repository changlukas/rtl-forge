# Forbidden Patterns

## 1. Mixing blocking and non-blocking assignments

```systemverilog
// ❌ Severe — race condition
always_ff @(posedge clk_i) begin
    a <= b;        // non-blocking
    c = a + 1;     // blocking — undefined behavior
end

// ✓ Sequential logic uses <= only
always_ff @(posedge clk_i) begin
    a <= b;
    c <= a + 1'b1;
end

// ✓ Combinational logic uses = only
always_comb begin
    temp   = a + b;
    result = temp * c;
end
```

## 2. Multiple drivers

```systemverilog
// ❌ Two always blocks driving the same signal
always_ff @(posedge clk_i) data_q <= data_i;
always_comb               data_q  = other_value;   // conflict

// ✓ Single driver
always_comb begin
    data_d = condition ? data_i : other_value;
end
always_ff @(posedge clk_i) data_q <= data_d;
```

## 3. Incomplete sensitivity list

```systemverilog
// ❌ always @ easily misses signals
always @(a) result = a + b + c;     // b and c missing

// ✓ Always use always_comb (auto-inferred)
always_comb result = a + b + c;
```

## 4. Latch generation (most common defect)

```systemverilog
// ❌ Incomplete case → out becomes a latch
always_comb begin
    case (sel)
        2'b00: out = a;
        2'b01: out = b;
        // 2'b10, 2'b11 missing
    endcase
end

// ✓ Add default
always_comb begin
    case (sel)
        2'b00:   out = a;
        2'b01:   out = b;
        2'b10:   out = c;
        default: out = '0;
    endcase
end

// ✓ Or assign a global default first
always_comb begin
    out = '0;       // default
    case (sel)
        2'b00: out = a;
        2'b01: out = b;
    endcase
end

// ❌ if without else
always_comb begin
    if (en) out = data;     // !en path → latch
end

// ✓
always_comb begin
    out = '0;
    if (en) out = data;
end
```

## 5. Width mismatch (implicit truncation)

```systemverilog
// ❌ Implicit truncation
logic [7:0]  byte_data;
logic [15:0] word_data;
assign byte_data = word_data;       // upper bits silently dropped

// ✓ Explicit slice
assign byte_data = word_data[7:0];

// ✓ Explicit extension
assign word_data = {8'b0, byte_data};
```

## 6. `x` or `z` in synthesizable code

```systemverilog
// ❌
assign data = 4'bxxxx;          // unsynthesizable

// ✓
assign data = 4'b0000;

// `x` is allowed only in testbench
initial data = 4'bxxxx;         // testbench OK
```

## 7. For-loop hardware abuse

```systemverilog
// ❌ for inside always_ff
integer i;
always_ff @(posedge clk_i) begin
    for (i = 0; i < 16; i++) data_o[i] <= data_i[i];    // shared-counter risk
end

// ❌ Cascaded combinational chain
always_comb begin
    sum = '0;
    for (i = 0; i < 16; i++) sum = sum + data[i];       // 16-level chain
end

// ✓ Use generate
genvar i;
generate
    for (i = 0; i < 16; i++) begin : gen_regs
        always_ff @(posedge clk_i) data_o[i] <= data_i[i];
    end
endgenerate
```

See `references/generate-vs-for.md`.

## 8. Manual clock gating

```systemverilog
// ❌ Hand-AND'd clock
assign gated_clk = clk_i & enable;
always_ff @(posedge gated_clk) data_q <= data_d;

// ❌ Signal as clock
always_ff @(posedge data_valid) counter <= counter + 1;

// ✓ Use enable
always_ff @(posedge clk_i) begin
    if (enable) counter_q <= counter_q + 1'b1;
end
```

If clock gating is required, use the library's ICG cell. Never roll your own.

## 9. Async reset missing from sensitivity list

```systemverilog
// ❌ Async reset declared but not in sensitivity list
always_ff @(posedge clk_i) begin
    if (!rst_ni) data_q <= '0;       // becomes synchronous (semantic error)
    else         data_q <= data_d;
end

// ✓
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) data_q <= '0;
    else         data_q <= data_d;
end
```

## 10. CDC without synchronizer

```systemverilog
// ❌ Direct cross-domain assignment → metastability
always_ff @(posedge clk_a) sig_a <= ...;
always_ff @(posedge clk_b) sig_b <= sig_a;      // unsafe

// ✓ Two-FF synchronizer
logic sync_1, sync_2;
always_ff @(posedge clk_b) begin
    sync_1 <= sig_a;
    sync_2 <= sync_1;
end
// Use sync_2; never use sync_1
```

For multi-bit CDC, use a proper handshake or async FIFO — a synchronizer alone is not sufficient.

## 11. Arithmetic without width extension

```systemverilog
// ❌ Result truncates on overflow
logic [7:0] a, b, sum;
assign sum = a + b;         // overflow silently dropped

// ✓ Extend
logic [7:0] a, b;
logic [8:0] sum;
assign sum = {1'b0, a} + {1'b0, b};
```

## 12. `always` instead of `always_ff` / `always_comb`

```systemverilog
// ❌ Ambiguous (sequential? combinational?)
always @(posedge clk_i) data_q <= data_d;
always @* result = a + b;

// ✓ Explicit
always_ff  @(posedge clk_i) data_q <= data_d;
always_comb result = a + b;
```
