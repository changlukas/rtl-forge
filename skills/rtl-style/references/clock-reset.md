# Clocks and Resets

## Clock naming

```systemverilog
input logic clk_sys_i;       // system clock
input logic clk_cpu_i;       // CPU clock
input logic clk_peri_i;      // peripheral clock
input logic clk_ddr_i;       // DDR clock
```

Single-clock designs use `clk_i`. Multi-clock designs must qualify each clock with its domain (`clk_<domain>_i`).

## Reset naming

| Form | Use |
|------|-----|
| `rst_ni`        | Active-low reset (sync or async, single-domain) |
| `arst_ni`       | Explicitly **a**synchronous active-low reset |
| `rst_<dom>_ni`  | Per-domain reset (e.g. `rst_cpu_ni`) |
| `arst_<dom>_ni` | Per-domain async reset |

Active-low is the project default. Active-high resets must be justified.

## Reset strategy: sync vs async

**Default to synchronous reset.** It's smaller (no async pin on the FF) and timing-friendly (the reset path closes against the clock).

```systemverilog
// ✓ Synchronous reset (default)
always_ff @(posedge clk_i) begin
    if (!rst_ni) data_q <= '0;
    else         data_q <= data_d;
end
```

Use **asynchronous reset** only for:
- Critical control paths that must reset before the clock is stable.
- The first FF in each clock domain that captures power-on / external reset.
- CDC reset distribution.

```systemverilog
// ✓ Asynchronous reset (limited use)
always_ff @(posedge clk_i or negedge arst_ni) begin
    if (!arst_ni) critical_flag_q <= 1'b0;
    else          critical_flag_q <= critical_flag_d;
end
```

Mixing sync and async resets within the same module is allowed but every register's choice must be deliberate.

## Async reset assertion vs deassertion

Async assertion is fine — the reset propagates immediately, regardless of clock. The hazard is **deassertion**: if `arst_ni` rises near a clock edge, the FF can go metastable.

**Rule**: every async reset must be released through a synchronous-deassertion synchronizer in each clock domain it reaches.

```systemverilog
// 2-FF reset synchronizer per domain
logic rst_sync_meta, rst_sync_q;
always_ff @(posedge clk_i or negedge arst_ni) begin
    if (!arst_ni) begin
        rst_sync_meta <= 1'b0;
        rst_sync_q    <= 1'b0;
    end else begin
        rst_sync_meta <= 1'b1;
        rst_sync_q    <= rst_sync_meta;
    end
end

// Use rst_sync_q (renamed rst_ni) as the per-domain reset
```

Effects:
- Reset asserts immediately when `arst_ni` falls (asynchronous behavior preserved).
- Reset deasserts only after two clocks have passed since `arst_ni` rose (synchronous, no metastability).

Each clock domain gets its own synchronizer. Never share a synchronized reset across domains.

## Forbidden clock patterns

```systemverilog
// ❌ Manual clock gating
assign gated_clk = clk_i & enable;
always_ff @(posedge gated_clk) data_q <= data_d;     // do not roll your own

// ❌ Signal as clock
always_ff @(posedge data_valid) counter <= counter + 1;

// ✓ Use enable
always_ff @(posedge clk_i) begin
    if (enable) counter_q <= counter_q + 1'b1;
end
```

If clock gating is required for power, use the standard cell library's ICG (Integrated Clock Gating) cell — never `assign clk = clk_i & en`.
