# 模組結構與 Port 對齊

主文件對應章節：`rtl_style.md` §3.4, §4

## Port 宣告順序（強制）

1. 時鐘（clk）
2. 重置（rst）
3. 輸入信號（按功能分組）
4. 輸出信號（按功能分組）
5. 雙向信號（inout，盡量避免）

```systemverilog
module example #(
    parameter int DATA_WIDTH = 32
) (
    // Clock and Reset (always first)
    input  logic clk_i,
    input  logic rst_ni,

    // Control inputs
    input  logic start_i,
    input  logic stop_i,

    // Data inputs
    input  logic [DATA_WIDTH-1:0] data_i,
    input  logic                  valid_i,

    // Status outputs
    output logic busy_o,
    output logic done_o,

    // Data outputs
    output logic [DATA_WIDTH-1:0] result_o,
    output logic                  valid_o
);
```

## Port 對齊（強制）

類型、名稱、註解三欄對齊：

```systemverilog
module aligned_ports (
    input  logic        clk_i,          // System clock
    input  logic        rst_ni,         // Active-low reset
    input  logic [31:0] addr_i,         // Address input
    input  logic [63:0] data_i,         // Data input
    output logic        ready_o,        // Ready signal
    output logic [63:0] result_o        // Computation result
);
```

## 參數化

```systemverilog
module parameterized_fifo #(
    parameter int DATA_WIDTH = 32,
    parameter int DEPTH      = 16,
    // 衍生參數用 localparam 自動計算
    localparam int ADDR_WIDTH = $clog2(DEPTH)
) (
    input  logic                  clk_i,
    input  logic                  rst_ni,
    input  logic [DATA_WIDTH-1:0] wdata_i,
    input  logic                  wen_i,
    output logic [DATA_WIDTH-1:0] rdata_o,
    output logic                  full_o,
    output logic                  empty_o
);

    logic [ADDR_WIDTH-1:0] wptr_q, rptr_q;
    logic [DATA_WIDTH-1:0] mem [DEPTH];
endmodule
```

## 內部分區註解

模組內部用 banner 註解區分：

```systemverilog
    // ========================================================================
    // Local Parameters
    // ========================================================================
    localparam int INTERNAL_WIDTH = PARAM_A + PARAM_B;

    // ========================================================================
    // Signal Declarations
    // ========================================================================
    state_e state_q, state_d;
    logic [INTERNAL_WIDTH-1:0] temp_data;

    // ========================================================================
    // Combinational Logic
    // ========================================================================
    always_comb begin
        // ...
    end

    // ========================================================================
    // Sequential Logic
    // ========================================================================
    always_ff @(posedge clk_i or negedge rst_ni) begin
        // ...
    end

    // ========================================================================
    // Submodule Instantiation
    // ========================================================================
    sub_module #(
        .PARAM_X (PARAM_A),
        .PARAM_Y (PARAM_B)
    ) u_sub_module (
        .clk_i   (clk_i),
        .rst_ni  (rst_ni),
        .data_i  (data_i),
        .data_o  (temp_data)
    );
```

## Submodule 實例化（命名連接，禁止位置連接）

```systemverilog
// ✓ 正確：named connection
fifo #(
    .DATA_WIDTH (32),
    .DEPTH      (16)
) u_input_fifo (
    .clk_i   (clk_i),
    .rst_ni  (rst_ni),
    .wdata_i (input_data),
    .wen_i   (input_valid),
    .rdata_o (fifo_data),
    .full_o  (fifo_full)
);

// ❌ 錯誤：位置連接
fifo u_fifo (clk_i, rst_ni, data, valid, ...);
```

## 完整檔案模板

直接使用 `templates/module.sv`。
