# rtl-forge

A SystemVerilog/Verilog RTL coding standard packaged as Claude Code tooling. Two artifacts work together:

- **`rtl-style`** — a Claude Code skill that enforces the standard while Claude generates or modifies RTL.
- **`rtl-reviewer`** — a Claude Code sub-agent that reviews existing RTL against the standard and produces a categorized findings report.

The standard is operational only — every rule is something a synthesis tool, lint tool, or downstream engineer will hold you accountable to. There is no pedagogical filler.

---

## Repository layout

```
rtl-forge/
├── README.md                    # this file (human reading entry)
├── rtl/                         # example RTL
│   ├── qmac_unit.sv             # reference implementation
│   └── qmac_unit_buggy.sv       # intentional violations (rtl-reviewer regression test)
├── skills/
│   └── rtl-style/
│       ├── SKILL.md             # core mandatory rules
│       ├── references/          # progressive-load topic files
│       ├── templates/           # ready-to-copy module skeletons
│       └── checklists/
│           └── pre-synthesis.md # gate before declaring code done
└── agents/
    └── rtl-reviewer.md          # sub-agent definition
```

Reading order for newcomers: `skills/rtl-style/SKILL.md` → the references most relevant to your task → `checklists/pre-synthesis.md` before commit.

---

## Style guide overview

The full rules live in `skills/rtl-style/`. Each topic below links to the file that owns it.

### 1. Naming → [`references/naming.md`](skills/rtl-style/references/naming.md)

Suffixes carry semantic meaning. They are mandatory.

- `_i` input port, `_o` output port
- `_q` registered output, `_d` next-state input to a register
- `_n` active-low (e.g. `rst_ni`, `cs_n`)
- `_e` enum, `_t` struct, `_u` union
- `s<N>_` prefix on pipeline-stage signals (`s1_data_q`, `s2_valid_q`)

Modules and signals are `lowercase_with_underscores`. Parameters are `UPPER_CASE_WITH_UNDERSCORES`.

### 2. Module structure → [`references/module-structure.md`](skills/rtl-style/references/module-structure.md)

Port declaration order: clocks → resets → control inputs → data inputs → status outputs → data outputs. Three-column alignment of direction / type / name. Submodule connections are always named, never positional. Internal sections are separated by banner comments.

Continuous assignments use `assign` for simple expressions; multi-line conditions are operator-aligned. Anything beyond ~3 operands or with nested ternaries belongs in `always_comb`.

Assertions are wrapped in both `synopsys translate_off` and `` `ifndef SYNTHESIS `` so synthesis tools see neither.

### 3. File organization → [`references/file-organization.md`](skills/rtl-style/references/file-organization.md)

One file holds at most one main module. File basename matches the module name. Standard layout:

```
project/
├── rtl/<subsystem>/   # SystemVerilog modules
├── include/           # .svh headers, no module bodies
└── tb/                # testbenches
```

Headers wrap with include guards. Packages live in `<name>_pkg.sv`.

### 4. Clock and reset → [`references/clock-reset.md`](skills/rtl-style/references/clock-reset.md)

Clock naming: single-clock designs use `clk_i`; multi-clock designs qualify each (`clk_sys_i`, `clk_cpu_i`).

Reset naming: `rst_ni` for active-low (default), `arst_ni` when explicitly asynchronous, `rst_<dom>_ni` per domain.

**Reset strategy**: synchronous reset is the default — smaller and timing-friendly. Use asynchronous reset only for critical control paths and the first FF in each clock domain that captures the external/POR reset.

**Asynchronous reset deassertion** must pass through a 2-FF synchronizer in every clock domain. Each domain owns its own synchronizer; a synchronized reset is never shared across domains.

### 5. Sequential logic

```systemverilog
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        data_q  <= '0;
        state_q <= IDLE;
    end else begin
        data_q  <= data_d;
        state_q <= state_d;
    end
end
```

Rules: only `always_ff` (never bare `always`); only non-blocking `<=`; every register has a reset value; async reset must appear in the sensitivity list with `or negedge rst_ni`.

### 6. Combinational logic

```systemverilog
always_comb begin
    out      = default_val;
    state_d  = state_q;
    case (sel)
        2'b00:   out = a;
        2'b01:   out = b;
        default: out = c;
    endcase
end
```

Rules: only `always_comb` (never `always @*` or `always @(...)`); only blocking `=`; every output assigned a default before any conditional; every `case` has a `default`.

### 7. Repeated hardware → [`references/generate-vs-for.md`](skills/rtl-style/references/generate-vs-for.md)

Use `generate` for parallel hardware instances, register arrays, adder/XOR trees, and conditional hardware selection. Generate blocks are always named (`gen_<role>`).

`for` loops are restricted to testbench code, `initial` blocks, and `function` bodies. A `for` inside `always_ff`/`always_comb` produces cascaded logic or an unintended shared counter — use `generate` instead.

### 8. State machines → [`references/fsm.md`](skills/rtl-style/references/fsm.md), template at [`templates/fsm.sv`](skills/rtl-style/templates/fsm.sv)

Three-process structure: state register (sequential), next-state logic (combinational), output logic (combinational). States are defined with `typedef enum`, never raw bit vectors. Both case statements have `default`. Process 2 starts with `state_d = state_q`. Process 3 starts with default-zero on every output.

### 9. Pipelines → [`references/pipeline.md`](skills/rtl-style/references/pipeline.md), template at [`templates/pipeline.sv`](skills/rtl-style/templates/pipeline.sv)

Per-stage signals are named `s<N>_<signal>_q` / `_d`. Datapath and control path are kept separate. The valid-ready protocol has one inviolable rule: **`valid` must not be combinationally derived from `ready`** — that creates a loop.

Stall preserves data and valid. Flush clears valid; data may stay. Skid buffers break the ready combinational path when downstream timing is tight.

### 10. Standard buses → [`references/interfaces.md`](skills/rtl-style/references/interfaces.md), AXI4 template at [`templates/axi4_if.svh`](skills/rtl-style/templates/axi4_if.svh)

AXI / APB / AHB / NoC / PCIe interfaces are defined in dedicated `<interface>_if.svh` headers. All widths and constants centralized via `` `define ``. Modules reference the named constants (`AXI4_RESP_OKAY`, `AXI4_BURST_INCR`) rather than magic numbers.

### 11. Forbidden patterns → [`references/forbidden-patterns.md`](skills/rtl-style/references/forbidden-patterns.md)

12 patterns that fail synthesis, simulate inconsistently, or hide bugs. The most common offenders:

1. Mixing `=` and `<=` in `always_ff`
2. Multiple drivers on the same signal
3. Incomplete sensitivity list (a reason to never use bare `always`)
4. Latch generation from incomplete `case` or `if` paths
5. Implicit width truncation
6. `x` / `z` in synthesizable code
7. `for` loops producing hardware
8. Manual clock gating (`clk & en`)
9. Async reset declared but missing from sensitivity list
10. CDC without a 2-FF synchronizer
11. Arithmetic without width extension
12. Bare `always` instead of `always_ff` / `always_comb`

### 12. Comments and documentation → [`references/comments.md`](skills/rtl-style/references/comments.md)

Comments explain *why*, not *what*. The module banner has Description, Parameters, Interfaces, Author, Date, Version. Tagged comments use `TODO(user)`, `FIXME(user)`, `NOTE`, `HACK`. `FIXME` and `HACK` always reference the underlying ticket or bug.

### 13. Optimization → [`references/optimization.md`](skills/rtl-style/references/optimization.md)

Operational catalogue of techniques: shift-multiply, CSA tree, reciprocal divide, iterative non-restoring divider, comparator via subtraction, wide-comparator partitioning, LZC, popcount tree, Gray-code counter, piecewise-linear LUT, retiming, operand isolation, ALU resource sharing, time-division multiplexing, fixed-point Q-format multiply.

Defer to the synthesis tool for Booth/Wallace inference, DSP block mapping, and retiming. Hand-rolled clock gating is forbidden — use the library ICG cell.

### 14. Pre-synthesis checklist → [`checklists/pre-synthesis.md`](skills/rtl-style/checklists/pre-synthesis.md)

Nine groups: code style, sequential, combinational, synthesis correctness, generate/for, pipeline, documentation, lint, self-review. Run through every group before declaring code ready.

---

## Using the skill and agent

### As a Claude Code skill (RTL generation)

The `rtl-style` skill is auto-discovered when its directory is reachable from `~/.claude/skills/`. Two ways to wire it up:

1. **Junction (recommended on Windows)** — link from `~/.claude/skills/` back into this repo:
   ```
   cmd /c mklink /J "%USERPROFILE%\.claude\skills\rtl-style" "<repo-path>\skills\rtl-style"
   ```
   Single source of truth: edits in the repo are picked up immediately.

2. **Symlink (Linux/macOS)**:
   ```
   ln -s <repo-path>/skills/rtl-style ~/.claude/skills/rtl-style
   ```

Once linked, Claude Code will auto-load `SKILL.md` whenever a session involves RTL work. Reference files load lazily based on the task.

### As a Claude Code sub-agent (RTL review)

The `rtl-reviewer` agent is a single Markdown file. Two options:

1. **Symlink (recommended — works cross-volume).** Requires Windows 10/11 Developer Mode (Settings → For Developers → Developer Mode), or run the command as Administrator:
   ```
   cmd /c mklink "%USERPROFILE%\.claude\agents\rtl-reviewer.md" "<repo-path>\agents\rtl-reviewer.md"
   ```
   On Linux/macOS:
   ```
   ln -s <repo-path>/agents/rtl-reviewer.md ~/.claude/agents/rtl-reviewer.md
   ```

2. **Hardlink (same volume only).** Fails silently across drive letters — if your repo is on `E:` and `%USERPROFILE%` is on `C:`, this will not work:
   ```
   cmd /c mklink /H "%USERPROFILE%\.claude\agents\rtl-reviewer.md" "<repo-path>\agents\rtl-reviewer.md"
   ```

Then invoke from any project: ask Claude to "review this RTL with the rtl-reviewer agent." The agent runs 12 detection passes over the supplied files and returns a CRITICAL / HIGH / MEDIUM / LOW report with file:line citations and minimal-change fix snippets.

---

## Example RTL

`rtl/qmac_unit.sv` — a 4-lane signed Multiply-Accumulate unit. Reference implementation that conforms to the standard.

`rtl/qmac_unit_buggy.sv` — same unit, with deliberate violations (manual clock gating, `valid_o` combinationally depending on `ready_i`, missing `_q`/`_d` suffixes, `for`-loop hardware, etc.). Use it as a regression target when modifying `rtl-reviewer` — the agent should produce a non-empty report against this file.

---

## Style philosophy

- **Operational over pedagogical.** Every rule is enforceable by lint or review. Motivation paragraphs that don't constrain code don't appear.
- **Suffixes carry meaning.** A reader should know from a signal's name whether it crosses a register boundary (`_q`/`_d`), is active-low (`_n`), or is a port (`_i`/`_o`).
- **Defaults everywhere.** Every `always_comb` output and every `case` has a default. Latches are accidents, not features.
- **Sequential and combinational are physically separated.** `always_ff` only registers; `always_comb` only logic. Three-process FSMs. No mixed blocks.
- **Repeated hardware uses `generate`, never `for`.** A `for` loop in an `always` block is a code smell — likely a cascaded chain or a shared counter.
- **valid never depends on ready.** This is the single most common pipeline bug. The handshake protocol survives only if the producer's valid is a function of internal state, not the consumer's ready.
- **Trust the synthesis tool.** Don't hand-build Booth multipliers, don't hand-gate clocks, don't manually retime. Let the tool do its job.

---

## License

(Add license here.)
