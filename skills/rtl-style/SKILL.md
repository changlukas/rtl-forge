---
name: rtl-style
description: SystemVerilog/Verilog RTL coding style guide and templates. Use when writing, generating, or modifying SystemVerilog/Verilog RTL code, including modules, always_ff/always_comb blocks, FSM, pipeline, AXI/APB interfaces, generate blocks. Enforces naming conventions (_i/_o/_q/_d/_n suffixes), forbids common pitfalls (latch generation, blocking/non-blocking mix, for-loop hardware abuse), and provides ready-to-copy module/FSM/pipeline/AXI4 templates.
---

# SystemVerilog RTL Style Guide

This skill defines the SystemVerilog/Verilog RTL coding standard. Follow it before generating any RTL code. The skill itself is the authoritative source — `references/`, `templates/`, and `checklists/` together define every rule.

---

## Mandatory rules (core summary)

### Formatting
- **4-space indent**, no tabs
- Line length ≤ 100 characters
- Whitespace around operators and after commas

### Naming suffixes (most-violated rules)

| Suffix | Use | Example |
|--------|-----|---------|
| `_i` | input port | `data_i`, `valid_i` |
| `_o` | output port | `result_o`, `valid_o` |
| `_q` | registered (FF output) | `state_q`, `counter_q` |
| `_d` | combinational input to FF | `state_d`, `counter_d` |
| `_n` | active-low | `rst_ni`, `cs_n`, `we_n` |
| `_e` | enum type | `state_e` |
| `_t` | struct/typedef | `axi_req_t` |
| `_u` | union | `data_u` |

- Modules / signals: lowercase + underscore (`axi_dma_controller`, `fetch_done`)
- Parameter / localparam / `define`: UPPER_CASE + underscore (`ADDR_WIDTH`, `AXI4_RESP_OKAY`)
- Pipeline stages: `s<N>_<signal>_q` (e.g. `s1_data_q`, `s2_valid_q`)

### Clocks and resets

- Clock naming: `clk_i` (single-clock) or `clk_<domain>_i` (multi-clock — e.g. `clk_sys_i`, `clk_cpu_i`)
- Reset naming: `rst_ni` (active-low default), `arst_ni` (explicit async), `rst_<dom>_ni` per domain
- **Synchronous reset is the default.** Use async reset only for critical control paths and the first FF in each domain that captures external/POR reset.
- Async resets must release through a 2-FF synchronizer in **each** clock domain (synchronous deassertion). Never share a synchronized reset across domains.
- Forbidden: manual clock gating (`clk_i & en`), signals as clocks. Use enable signals or library ICG cells instead.
- Full strategy and synchronizer code: `references/clock-reset.md`.

### Sequential logic (FF)
```systemverilog
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        data_q  <= '0;       // every register reset to a known value
        state_q <= IDLE;
    end else begin
        data_q  <= data_d;   // non-blocking <= only
        state_q <= state_d;
    end
end
```

### Combinational logic
```systemverilog
always_comb begin
    out      = default_val;  // every output has a default
    state_d  = state_q;      // default: hold current state
    case (sel)
        2'b00:   out = a;
        2'b01:   out = b;
        default: out = c;    // case must have default (avoid latch)
    endcase
end
```

### Repeated hardware: use `generate`, not `for`
```systemverilog
// ✓ Correct
genvar i;
generate
    for (i = 0; i < N; i++) begin : gen_units
        adder u_adder ( ... );  // parallel hardware instances
    end
endgenerate

// ❌ Wrong: for inside always block produces cascaded logic
always_comb begin
    for (i = 0; i < N; i++) sum = sum + data[i];
end
```
`for` loops are restricted to testbench / `initial` / `function` bodies.

### Pipeline rules
- Name each stage `s<N>_<signal>_q`
- `valid` must **not** depend on `ready` (would create a combinational loop)
- Stall preserves data; flush clears `valid` while keeping data
- See `references/pipeline.md`

### Standard buses
AXI/APB/AHB interfaces live in dedicated `.svh` headers; use `` `define `` to centralize widths and constants. See `references/interfaces.md`.

---

## Progressive reference loading

Load only the references needed for the task. Never preload everything.

| Task | Files to load |
|------|---------------|
| New module (shell / ports) | `references/module-structure.md` + `templates/module.sv` |
| Naming detail | `references/naming.md` |
| File organization, directory layout | `references/file-organization.md` |
| Clock / reset strategy, async-reset deassertion | `references/clock-reset.md` |
| Comments, doc blocks, TODO/FIXME tags | `references/comments.md` |
| FSM | `references/fsm.md` + `templates/fsm.sv` |
| Pipeline (with backpressure) | `references/pipeline.md` + `templates/pipeline.sv` |
| Repeated hardware arrays | `references/generate-vs-for.md` |
| AXI / APB / AHB | `references/interfaces.md` + `templates/axi4_if.svh` |
| Arithmetic optimization (CSA, shifts, LZC, popcount, divider FSM, TDM) | `references/optimization.md` |
| Debug a violation | `references/forbidden-patterns.md` |
| Final pre-synthesis check | `checklists/pre-synthesis.md` |

---

## Workflow when generating RTL

1. **Plan inputs/outputs/processing** — list ports and dataflow direction.
2. **Copy a template** — start from the closest `templates/` skeleton.
3. **Apply naming suffixes** — `_i` / `_o` / `_q` / `_d` / `_n`.
4. **Separate sequential and combinational** — `always_ff` for registers, `always_comb` for logic.
5. **Add defaults** — every `case` and every combinational output.
6. **Run the checklist** — verify against `checklists/pre-synthesis.md` before declaring done.
