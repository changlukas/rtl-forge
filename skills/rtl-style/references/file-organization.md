# File Organization

## Directory layout

```
project/
├── rtl/
│   ├── top/
│   │   └── top_module.sv           # top-level module
│   ├── subsys_a/
│   │   ├── module_a.sv
│   │   └── module_b.sv
│   ├── subsys_b/
│   │   └── module_c.sv
│   └── pkg/
│       ├── common_pkg.sv           # shared package
│       └── design_pkg.sv           # design-specific package
├── include/
│   ├── config_defines.svh          # configuration defines
│   └── common_defines.svh          # shared defines
└── tb/
    ├── top_tb.sv
    └── module_a_tb.sv
```

## File naming and extensions

- **One file holds at most one main module.** No multi-module files.
- `.sv` for SystemVerilog modules.
- `.svh` for headers (define-only, no module body).
- `<name>_pkg.sv` for packages (e.g. `common_pkg.sv`, `design_pkg.sv`).
- File basename must match the module name: `axi_dma_controller.sv` → `module axi_dma_controller`.

## Header files (`.svh`)

- Header files may contain `` `define ``, `typedef`, `parameter`, function/task definitions.
- They must not contain `module ... endmodule`.
- Wrap with include guards:
  ```systemverilog
  `ifndef AXI4_IF_SVH
  `define AXI4_IF_SVH
  // ...
  `endif // AXI4_IF_SVH
  ```
- See `references/interfaces.md` for bus header conventions.

## Packages (`_pkg.sv`)

- Use packages to group related typedefs, parameters, and functions.
- Import inside a module: `module foo import design_pkg::*; #(...) (...);`
- Or selective import: `import design_pkg::axi_req_t;`

## Testbench

- Place under `tb/`. Naming: `<module>_tb.sv` for unit benches, `<scenario>_tb.sv` for system benches.
- Testbenches may use `for` loops, `initial`, `assert` freely — synthesizable rules do not apply.
