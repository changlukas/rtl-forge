# Pre-Synthesis Checklist

Run through every group before declaring code ready.

## 1. Code style

- [ ] 4-space indent (no tabs)
- [ ] Module name lowercase + underscore
- [ ] Port direction suffix: `_i` / `_o`
- [ ] Register suffix: `_q` / `_d`
- [ ] Active-low signals: `_n` suffix
- [ ] Clocks named `clk_*_i`, resets named `rst_*ni` or `arst_*ni`
- [ ] Constants / parameters in UPPER_CASE + underscore
- [ ] enum `_e`, struct `_t`, union `_u`
- [ ] Pipeline stages prefixed `s<N>_`

## 2. Sequential logic

- [ ] `always_ff` (not `always @(posedge clk)`)
- [ ] Non-blocking assignments `<=`
- [ ] All registers reset to a known value
- [ ] Reset polarity correct (sync: `@(posedge clk_i)`; async: `@(posedge clk_i or negedge rst_ni)`)
- [ ] Async reset signal appears in the sensitivity list

## 3. Combinational logic

- [ ] `always_comb` (not `always @*` or `always @(...)`)
- [ ] Blocking assignments `=`
- [ ] Every output assigned a default (avoid latch)
- [ ] Every `case` has a `default`
- [ ] Every `if` has an `else`, or a default is set up-front

## 4. Synthesis correctness

- [ ] **No multi-driver** (each signal driven in exactly one block)
- [ ] **No unintended latch** (verify with lint)
- [ ] **No combinational loop** (especially: `valid` must not depend on `ready`)
- [ ] **Width-matched** assignments — no implicit truncate / extend
- [ ] **No `x` / `z`** in synthesizable code
- [ ] **No manual clock gating** (use the library ICG cell)
- [ ] **No signal used as clock**
- [ ] Async resets released through a 2-FF synchronizer per domain
- [ ] Cross-domain signals pass through a 2-FF synchronizer (or proper handshake / async FIFO for multi-bit)
- [ ] Arithmetic widened to prevent overflow truncation
- [ ] Parametric edge cases (N=0, N=1, N=MAX) handled

## 5. Generate / for loops

- [ ] **Repeated hardware uses `generate`, not `for`**
- [ ] **`for` loops only inside testbench / `initial` / `function`**
- [ ] **All `generate` blocks named** (`gen_<role>`)
- [ ] All conditional-generate branches named
- [ ] Generate variables declared with `genvar`
- [ ] Nested generate ≤ 3 levels

## 6. Pipeline (if applicable)

- [ ] Every stage has a `_q` register
- [ ] `valid` propagates with the data
- [ ] **`valid` does not depend on `ready`**
- [ ] Backpressure logic correct (`!valid_q || downstream_ready`)
- [ ] Stall preserves data
- [ ] Flush clears `valid` (data may stay)
- [ ] No cross-stage combinational paths
- [ ] Hazards (forwarding / bubble) handled

## 7. Documentation

- [ ] Module banner has Module / Description / Parameters / Interfaces / Author / Date / Version
- [ ] Complex logic comments explain *why* (not *what*)
- [ ] Every parameter has a purpose comment
- [ ] Non-obvious ports have a comment
- [ ] FSM transitions have a diagram or comment when complex
- [ ] `TODO(user)` / `FIXME(user)` / `NOTE` / `HACK` tags follow convention

## 8. Lint / tool checks

- [ ] Verilator / Spyglass lint clean
- [ ] Synthesis: zero unintended-latch warnings
- [ ] Synthesis: zero multi-driver warnings
- [ ] Simulator: zero `WIDTH` mismatch warnings

## 9. Self-review questions

After finishing the code, answer these:

- What does this module *do*? Inputs / processing / outputs / side effects?
- Where does data come from? Who consumes it? When does state change?
- Which signals are *guarantees* (always true) vs *policies* (design choices)?
- Are exceptional paths (reset, stall, flush, error) handled correctly?
- Do edge values (N=0, N=MAX, empty, full) break anything?
