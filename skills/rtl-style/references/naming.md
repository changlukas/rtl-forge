# 命名規則完整細則

主文件對應章節：`rtl_style.md` §2

## 模組與介面

| 規則 | 範例 |
|------|------|
| 小寫 + 底線，描述功能 | `axi_dma_controller`, `noc_router_4x5` |
| 介面用 `_if` 後綴 | `axi4_if`, `apb_if` |
| **禁止** 駝峰或全大寫 | ❌ `AxiDmaController`, ❌ `AXI_DMA` |

## 信號方向後綴

```systemverilog
input  logic        clk_i;          // input → _i
input  logic        rst_ni;         // active-low input
input  logic [31:0] data_i;
output logic        valid_o;        // output → _o
output logic [31:0] result_o;
```

## 暫存器與組合輸入

```systemverilog
logic [7:0] data_q;     // FF output (registered)
logic [7:0] data_d;     // FF input  (combinational, "next state")
logic       enable_q;
logic       enable_d;

// 配對使用
always_comb begin
    data_d = condition ? data_i : data_q;
end

always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) data_q <= '0;
    else         data_q <= data_d;
end
```

## Active-Low 信號

任何 active-low 信號必須加 `_n` 後綴：

```systemverilog
logic rst_ni;       // active-low reset (input)
logic arst_ni;      // async active-low reset
logic cs_n;         // chip select, active low
logic we_n;         // write enable, active low
logic oe_n;         // output enable, active low
```

## 握手信號

```systemverilog
logic req_valid;    // 請求有效
logic req_ready;    // 準備接收請求
logic rsp_valid;    // 回應有效
logic rsp_ready;    // 準備接收回應
```

## 多時鐘域

```systemverilog
input logic clk_sys_i;       // 系統時鐘
input logic clk_cpu_i;       // CPU 時鐘
input logic clk_peri_i;      // 外設時鐘
input logic clk_ddr_i;       // DDR 時鐘
input logic rst_sys_ni;      // 系統重置
input logic rst_cpu_ni;      // CPU 重置
```

## 常數與參數

```systemverilog
parameter int ADDR_WIDTH = 32;
parameter int DATA_WIDTH = 64;
parameter int FIFO_DEPTH = 16;
localparam int COUNTER_MAX = 100;
localparam int ADDR_BITS = $clog2(FIFO_DEPTH);  // 衍生參數

// ❌ 禁止
parameter int addrWidth = 32;     // 小寫
parameter int AddrWidth = 32;     // 駝峰
```

## 類型定義

```systemverilog
// enum: _e 後綴，成員大寫
typedef enum logic [1:0] {
    IDLE   = 2'b00,
    ACTIVE = 2'b01,
    WAIT   = 2'b10,
    DONE   = 2'b11
} state_e;

// struct: _t 後綴
typedef struct packed {
    logic [31:0] addr;
    logic [7:0]  len;
    logic        valid;
} axi_req_t;

// union: _u 後綴
typedef union packed {
    logic [31:0] word;
    logic [7:0]  byte_arr [4];
} data_u;
```

## Pipeline Stage 命名

```systemverilog
// 推薦：s<N>_ 前綴
logic [31:0] s1_data_q;     // Stage 1 registered
logic [31:0] s1_data_d;     // Stage 1 combinational input
logic [31:0] s2_data_q;     // Stage 2 registered
logic        s2_valid_q;

// 或功能性命名
logic [31:0] fetch_data_q;
logic [31:0] decode_data_q;
logic [31:0] execute_data_q;
```

## Generate 塊命名

```systemverilog
genvar i;
generate
    for (i = 0; i < NUM_UNITS; i++) begin : gen_processing_units
        // 波形顯示：gen_processing_units[0], [1], ...
        processing_unit u_unit ( ... );
    end
endgenerate

// 條件 generate 的所有分支都要命名
generate
    if (USE_PIPELINE) begin : gen_pipelined
        // ...
    end else begin : gen_combinational
        // ...
    end
endgenerate
```

## Submodule Instance 命名

```systemverilog
// 【推薦】u_<功能>
fifo u_input_fifo ( ... );
arbiter u_main_arbiter ( ... );
mux u_output_mux ( ... );
```
