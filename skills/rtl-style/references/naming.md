# Naming Conventions

## Modules and interfaces

| Rule | Example |
|------|---------|
| Lowercase + underscore, descriptive | `axi_dma_controller`, `noc_router_4x5` |
| Interfaces use `_if` suffix | `axi4_if`, `apb_if` |
| **Forbidden**: CamelCase or ALL_CAPS | ❌ `AxiDmaController`, ❌ `AXI_DMA` |

## Port direction suffixes

```systemverilog
input  logic        clk_i;          // input → _i
input  logic        rst_ni;         // active-low input
input  logic [31:0] data_i;
output logic        valid_o;        // output → _o
output logic [31:0] result_o;
```

## Registers and combinational inputs

```systemverilog
logic [7:0] data_q;     // FF output (registered)
logic [7:0] data_d;     // FF input  (combinational, "next state")
logic       enable_q;
logic       enable_d;

// Pair them
always_comb begin
    data_d = condition ? data_i : data_q;
end

always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) data_q <= '0;
    else         data_q <= data_d;
end
```

## Active-low signals

Append `_n` to any active-low signal:

```systemverilog
logic rst_ni;       // active-low reset (input)
logic arst_ni;      // async active-low reset
logic cs_n;         // chip select, active low
logic we_n;         // write enable, active low
logic oe_n;         // output enable, active low
```

## Handshake signals

```systemverilog
logic req_valid;    // request valid
logic req_ready;    // ready to accept request
logic rsp_valid;    // response valid
logic rsp_ready;    // ready to accept response
```

## Multiple clock domains

```systemverilog
input logic clk_sys_i;       // system clock
input logic clk_cpu_i;       // CPU clock
input logic clk_peri_i;      // peripheral clock
input logic clk_ddr_i;       // DDR clock
input logic rst_sys_ni;      // system reset
input logic rst_cpu_ni;      // CPU reset
```

## Constants and parameters

```systemverilog
parameter int ADDR_WIDTH = 32;
parameter int DATA_WIDTH = 64;
parameter int FIFO_DEPTH = 16;
localparam int COUNTER_MAX = 100;
localparam int ADDR_BITS   = $clog2(FIFO_DEPTH);    // derived

// ❌ Forbidden
parameter int addrWidth = 32;     // lowercase
parameter int AddrWidth = 32;     // CamelCase
```

## Type definitions

```systemverilog
// enum: _e suffix, members in UPPER_CASE
typedef enum logic [1:0] {
    IDLE   = 2'b00,
    ACTIVE = 2'b01,
    WAIT   = 2'b10,
    DONE   = 2'b11
} state_e;

// struct: _t suffix
typedef struct packed {
    logic [31:0] addr;
    logic [7:0]  len;
    logic        valid;
} axi_req_t;

// union: _u suffix
typedef union packed {
    logic [31:0] word;
    logic [7:0]  byte_arr [4];
} data_u;
```

## Pipeline stage naming

```systemverilog
// Preferred: s<N>_ prefix
logic [31:0] s1_data_q;     // stage 1 registered
logic [31:0] s1_data_d;     // stage 1 combinational
logic [31:0] s2_data_q;
logic        s2_valid_q;

// Or functional names
logic [31:0] fetch_data_q;
logic [31:0] decode_data_q;
logic [31:0] execute_data_q;
```

## Generate block naming

```systemverilog
genvar i;
generate
    for (i = 0; i < NUM_UNITS; i++) begin : gen_processing_units
        // Waveform: gen_processing_units[0], [1], ...
        processing_unit u_unit ( ... );
    end
endgenerate

// Conditional generate — every branch must be named
generate
    if (USE_PIPELINE) begin : gen_pipelined
        // ...
    end else begin : gen_combinational
        // ...
    end
endgenerate
```

## Submodule instances

```systemverilog
// Preferred: u_<role>
fifo    u_input_fifo  ( ... );
arbiter u_main_arbiter( ... );
mux     u_output_mux  ( ... );
```
