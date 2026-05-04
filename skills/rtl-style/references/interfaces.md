# Standard Bus Interfaces (AXI / APB / AHB)

## Mandatory rules

- Standard bus interfaces (AXI4 / AXI-Lite / APB / AHB / PCIe / NoC ...) must use a dedicated header file.
- Use `` `define `` to centralize widths and constants.
- Header naming: `<interface_name>_if.svh`.
- Path: `include/<interface>_if.svh`.

## Why centralize in `.svh`

1. Width changes touch one location.
2. All modules using the interface stay width-consistent.
3. Named constants (e.g. `AXI4_RESP_OKAY`) replace magic numbers.
4. Reusable across projects.

## Naming conventions

```systemverilog
// Interface-prefix + purpose + WIDTH/constant
`define AXI4_ADDR_WIDTH     32
`define APB_DATA_WIDTH      32
`define NOC_FLIT_WIDTH      128
`define PCIE_TLP_WIDTH      256

// Constants: interface + type + value
`define AXI4_BURST_INCR     2'b01       // AXI4 burst type
`define AXI4_RESP_OKAY      2'b00       // AXI4 response
`define APB_RESP_ERROR      1'b1        // APB response
```

## Skeleton

```systemverilog
`ifndef AXI4_IF_SVH
`define AXI4_IF_SVH

// ============================================================================
// AXI4 Parameter Definitions
// ============================================================================
`define AXI4_ADDR_WIDTH     32
`define AXI4_DATA_WIDTH     64
`define AXI4_ID_WIDTH       4
`define AXI4_USER_WIDTH     8

// Derived widths
`define AXI4_STRB_WIDTH     (`AXI4_DATA_WIDTH/8)
`define AXI4_BURST_WIDTH    2
`define AXI4_SIZE_WIDTH     3
`define AXI4_LEN_WIDTH      8
`define AXI4_RESP_WIDTH     2

// Per-channel derived widths (point at a single source)
`define AXI4_AW_ADDR_WIDTH  `AXI4_ADDR_WIDTH
`define AXI4_AW_LEN_WIDTH   `AXI4_LEN_WIDTH
// ...

// Constant encodings
`define AXI4_BURST_FIXED    2'b00
`define AXI4_BURST_INCR     2'b01
`define AXI4_BURST_WRAP     2'b10

`define AXI4_RESP_OKAY      2'b00
`define AXI4_RESP_EXOKAY    2'b01
`define AXI4_RESP_SLVERR    2'b10
`define AXI4_RESP_DECERR    2'b11

`endif // AXI4_IF_SVH
```

Full AXI4 template: `templates/axi4_if.svh`.

## Usage in a module

```systemverilog
`include "axi4_if.svh"

module axi_master (
    input  logic clk_i,
    input  logic rst_ni,

    // AXI4 Write Address Channel
    output logic [`AXI4_AW_ADDR_WIDTH-1:0]  axi_awaddr_o,
    output logic [`AXI4_AW_ID_WIDTH-1:0]    axi_awid_o,
    output logic [`AXI4_AW_LEN_WIDTH-1:0]   axi_awlen_o,
    output logic [`AXI4_AW_SIZE_WIDTH-1:0]  axi_awsize_o,
    output logic [`AXI4_AW_BURST_WIDTH-1:0] axi_awburst_o,
    output logic                             axi_awvalid_o,
    input  logic                             axi_awready_i
);

    always_comb begin
        axi_awsize_o  = `AXI4_SIZE_8B;
        axi_awburst_o = `AXI4_BURST_INCR;
        axi_awlen_o   = 8'd15;
    end

    // Use named response codes
    case (axi_bresp_i)
        `AXI4_RESP_OKAY,
        `AXI4_RESP_EXOKAY: error_o <= 1'b0;
        `AXI4_RESP_SLVERR,
        `AXI4_RESP_DECERR: error_o <= 1'b1;
        default:           error_o <= 1'b1;
    endcase

endmodule
```

## APB example

```systemverilog
`ifndef APB_IF_SVH
`define APB_IF_SVH

`define APB_ADDR_WIDTH      32
`define APB_DATA_WIDTH      32
`define APB_STRB_WIDTH      (`APB_DATA_WIDTH/8)

`define APB_PADDR_WIDTH     `APB_ADDR_WIDTH
`define APB_PWDATA_WIDTH    `APB_DATA_WIDTH
`define APB_PRDATA_WIDTH    `APB_DATA_WIDTH
`define APB_PSTRB_WIDTH     `APB_STRB_WIDTH

`define APB_PPROT_WIDTH     3
`define APB_PPROT_NORMAL    3'b000
`define APB_PPROT_PRIV      3'b001

`endif
```

## Signal naming (AXI master perspective)

| Direction | Channel | Signal | Suffix |
|-----------|---------|--------|--------|
| Master out | AW | `axi_awaddr_o`, `axi_awvalid_o` | `_o` |
| Master in  | AW | `axi_awready_i` | `_i` |
| Master out | W  | `axi_wdata_o`, `axi_wvalid_o`, `axi_wlast_o` | `_o` |
| Master in  | W  | `axi_wready_i` | `_i` |
| Master in  | B  | `axi_bresp_i`, `axi_bvalid_i` | `_i` |
| Master out | B  | `axi_bready_o` | `_o` |
