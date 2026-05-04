# SystemVerilog/Verilog RTL 編碼規範

> **AI 使用說明**：本文檔定義了 SystemVerilog/Verilog 的編碼標準。在生成任何 RTL 代碼時，必須嚴格遵循本規範。

## 目錄
1. [基本格式規則](#1-基本格式規則)
2. [命名規則](#2-命名規則)
3. [檔案組織](#3-檔案組織)
4. [模組結構](#4-模組結構)
5. [RTL 建模規則](#5-rtl-建模規則)
6. [時鐘與重置](#6-時鐘與重置)
7. [禁止使用的寫法](#7-禁止使用的寫法)
8. [常見的運算優化技巧](#8-常見的運算優化技巧)
9. [註解與文檔](#9-註解與文檔)
10. [檢查清單](#10-檢查清單)

---

## 1. 基本格式規則

### 1.1 縮排規則

**【強制】使用 4 格空格縮排，禁止使用 Tab**

```systemverilog
// ✓ 正確：4 格空格縮排
module example (
    input  logic       clk_i,
    input  logic [3:0] addr_i,
    output logic [7:0] data_o
);

    always_ff @(posedge clk_i) begin
        if (!rst_ni) begin
            data_o <= '0;
        end else begin
            data_o <= mem[addr_i];
        end
    end

endmodule

// ❌ 錯誤：2 格空格或使用 Tab
module bad_example (
  input logic clk_i  // 只有 2 格，錯誤
);
```

### 1.2 每行長度

- 建議每行不超過 100 字元
- 過長的行應適當斷行並對齊

```systemverilog
// ✓ 正確：長參數列表斷行對齊
module long_param_module #(
    parameter int PARAM_A      = 32,
    parameter int PARAM_B      = 64,
    parameter int PARAM_C      = 128,
    parameter int VERY_LONG_PARAMETER_NAME = 256
) (
    input  logic clk_i,
    output logic data_o
);
```

### 1.3 空格使用

```systemverilog
// ✓ 正確：運算子前後有空格
assign result = (a + b) * c;
assign valid  = req && !busy && (counter < MAX_COUNT);

// ✓ 正確：逗號後有空格
function void my_func(int a, int b, int c);

// ❌ 錯誤：缺少空格
assign result=(a+b)*c;
assign valid=req&&!busy;
```

### 1.4 空行使用

```systemverilog
module example;
    // 區塊之間用空行分隔
    
    // Signal declarations
    logic [31:0] addr;
    logic        valid;
    
    // Combinational logic
    always_comb begin
        next_state = IDLE;
    end
    
    // Sequential logic
    always_ff @(posedge clk_i) begin
        state_q <= next_state;
    end
    
endmodule
```

---

## 2. 命名規則

### 2.1 模組與介面

```systemverilog
// 【強制】小寫字母 + 底線，描述功能
module axi_dma_controller (...);
module noc_router_4x5 (...);
interface axi4_if #(...) (...);

// ❌ 禁止使用駝峰或大寫開頭
module AxiDmaController (...);   // 錯誤
module AXI_DMA_CONTROLLER (...); // 錯誤
```

### 2.2 信號命名

**時鐘與重置**
```systemverilog
// 【強制】使用統一的後綴
input logic clk_i;           // 輸入時鐘
input logic rst_ni;          // 低電位有效重置 (negative active input)
input logic arst_ni;         // 異步低電位重置

// 多時鐘域
input logic clk_sys_i;       // 系統時鐘
input logic clk_peri_i;      // 外設時鐘
input logic rst_sys_ni;      // 系統重置
```

**一般信號**
```systemverilog
// 【推薦】使用方向後綴
logic valid_o;               // 輸出信號，後綴 _o
logic ready_i;               // 輸入信號，後綴 _i
logic [31:0] data_o;         // 輸出數據

// 【強制】觸發器與組合邏輯命名
logic [7:0] data_q;          // 觸發器輸出 (registered, _q)
logic [7:0] data_d;          // 觸發器輸入 (data input, _d)
logic       enable_q;
logic       enable_d;

// 【推薦】握手信號命名
logic req_valid;             // 請求有效
logic req_ready;             // 準備接收
logic rsp_valid;             // 回應有效
logic rsp_ready;             // 準備接收回應

// Active-low 信號使用 _n 後綴
logic cs_n;                  // chip select, active low
logic we_n;                  // write enable, active low
logic oe_n;                  // output enable, active low
```

### 2.3 常數與參數

```systemverilog
// 【強制】大寫字母 + 底線
parameter int ADDR_WIDTH = 32;
parameter int DATA_WIDTH = 64;
parameter int FIFO_DEPTH = 16;
localparam int COUNTER_MAX = 100;

// 【禁止】小寫或駝峰
parameter int addrWidth = 32;     // 錯誤
parameter int AddrWidth = 32;     // 錯誤
```

### 2.4 類型定義

```systemverilog
// 【強制】enum 使用 _e 後綴，大寫成員
typedef enum logic [1:0] {
    IDLE   = 2'b00,
    ACTIVE = 2'b01,
    WAIT   = 2'b10,
    DONE   = 2'b11
} state_e;

// 【強制】struct 使用 _t 後綴
typedef struct packed {
    logic [31:0] addr;
    logic [7:0]  len;
    logic        valid;
} axi_req_t;

// 【強制】union 使用 _u 後綴
typedef union packed {
    logic [31:0] word;
    logic [7:0]  byte[4];
} data_u;
```

---

## 3. 檔案組織

### 3.1 目錄結構

```
project/
├── rtl/
│   ├── top/
│   │   └── top_module.sv           # 頂層模組
│   ├── subsys_a/
│   │   ├── module_a.sv
│   │   └── module_b.sv
│   ├── subsys_b/
│   │   └── module_c.sv
│   └── pkg/
│       ├── common_pkg.sv           # 通用 package
│       └── design_pkg.sv           # 設計專用 package
├── include/
│   ├── config_defines.svh          # 配置定義
│   └── common_defines.svh          # 通用定義
└── tb/
    ├── top_tb.sv
    └── module_a_tb.sv
```

### 3.2 檔案命名

- **【強制】一個檔案只包含一個主要模組**
- SystemVerilog 檔案使用 `.sv` 副檔名
- Header 檔案使用 `.svh` 副檔名
- Package 檔案命名為 `<name>_pkg.sv`

### 3.3 通用介面定義

**【強制】標準匯流排介面（如 AMBA、AXI、APB）必須使用獨立的 header file 定義**

將介面信號位寬、欄位定義等使用 `` `define`` 集中管理，提高可維護性和重用性。

**Header file 命名規則**
- AXI4 介面：`axi4_if.svh`
- APB 介面：`apb_if.svh`
- AHB 介面：`ahb_if.svh`
- 自訂介面：`<interface_name>_if.svh`

**範例：AXI4 介面定義**

檔案：`include/axi4_if.svh`
```systemverilog
// ============================================================================
// File        : axi4_if.svh
// Description : AXI4 interface signal width and field definitions
// ============================================================================

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

// ============================================================================
// AXI4 Write Address Channel
// ============================================================================
`define AXI4_AW_ADDR_WIDTH  `AXI4_ADDR_WIDTH
`define AXI4_AW_ID_WIDTH    `AXI4_ID_WIDTH
`define AXI4_AW_LEN_WIDTH   `AXI4_LEN_WIDTH
`define AXI4_AW_SIZE_WIDTH  `AXI4_SIZE_WIDTH
`define AXI4_AW_BURST_WIDTH `AXI4_BURST_WIDTH
`define AXI4_AW_USER_WIDTH  `AXI4_USER_WIDTH

// ============================================================================
// AXI4 Write Data Channel
// ============================================================================
`define AXI4_W_DATA_WIDTH   `AXI4_DATA_WIDTH
`define AXI4_W_STRB_WIDTH   `AXI4_STRB_WIDTH
`define AXI4_W_USER_WIDTH   `AXI4_USER_WIDTH

// ============================================================================
// AXI4 Write Response Channel
// ============================================================================
`define AXI4_B_ID_WIDTH     `AXI4_ID_WIDTH
`define AXI4_B_RESP_WIDTH   `AXI4_RESP_WIDTH
`define AXI4_B_USER_WIDTH   `AXI4_USER_WIDTH

// ============================================================================
// AXI4 Read Address Channel
// ============================================================================
`define AXI4_AR_ADDR_WIDTH  `AXI4_ADDR_WIDTH
`define AXI4_AR_ID_WIDTH    `AXI4_ID_WIDTH
`define AXI4_AR_LEN_WIDTH   `AXI4_LEN_WIDTH
`define AXI4_AR_SIZE_WIDTH  `AXI4_SIZE_WIDTH
`define AXI4_AR_BURST_WIDTH `AXI4_BURST_WIDTH
`define AXI4_AR_USER_WIDTH  `AXI4_USER_WIDTH

// ============================================================================
// AXI4 Read Data Channel
// ============================================================================
`define AXI4_R_DATA_WIDTH   `AXI4_DATA_WIDTH
`define AXI4_R_ID_WIDTH     `AXI4_ID_WIDTH
`define AXI4_R_RESP_WIDTH   `AXI4_RESP_WIDTH
`define AXI4_R_USER_WIDTH   `AXI4_USER_WIDTH

// ============================================================================
// AXI4 Burst Type Definitions
// ============================================================================
`define AXI4_BURST_FIXED    2'b00
`define AXI4_BURST_INCR     2'b01
`define AXI4_BURST_WRAP     2'b10

// ============================================================================
// AXI4 Response Type Definitions
// ============================================================================
`define AXI4_RESP_OKAY      2'b00
`define AXI4_RESP_EXOKAY    2'b01
`define AXI4_RESP_SLVERR    2'b10
`define AXI4_RESP_DECERR    2'b11

// ============================================================================
// AXI4 Size Encoding
// ============================================================================
`define AXI4_SIZE_1B        3'b000  // 1 byte
`define AXI4_SIZE_2B        3'b001  // 2 bytes
`define AXI4_SIZE_4B        3'b010  // 4 bytes
`define AXI4_SIZE_8B        3'b011  // 8 bytes
`define AXI4_SIZE_16B       3'b100  // 16 bytes
`define AXI4_SIZE_32B       3'b101  // 32 bytes
`define AXI4_SIZE_64B       3'b110  // 64 bytes
`define AXI4_SIZE_128B      3'b111  // 128 bytes

`endif // AXI4_IF_SVH
```

**使用範例：模組中使用 AXI4 介面**

檔案：`rtl/axi_master.sv`
```systemverilog
// ============================================================================
// File        : axi_master.sv
// Description : AXI4 master interface module
// ============================================================================

`include "axi4_if.svh"

module axi_master (
    // Clock and Reset
    input  logic clk_i,
    input  logic rst_ni,
    
    // AXI4 Write Address Channel
    output logic [`AXI4_AW_ADDR_WIDTH-1:0]  axi_awaddr_o,
    output logic [`AXI4_AW_ID_WIDTH-1:0]    axi_awid_o,
    output logic [`AXI4_AW_LEN_WIDTH-1:0]   axi_awlen_o,
    output logic [`AXI4_AW_SIZE_WIDTH-1:0]  axi_awsize_o,
    output logic [`AXI4_AW_BURST_WIDTH-1:0] axi_awburst_o,
    output logic                             axi_awvalid_o,
    input  logic                             axi_awready_i,
    
    // AXI4 Write Data Channel
    output logic [`AXI4_W_DATA_WIDTH-1:0]   axi_wdata_o,
    output logic [`AXI4_W_STRB_WIDTH-1:0]   axi_wstrb_o,
    output logic                             axi_wlast_o,
    output logic                             axi_wvalid_o,
    input  logic                             axi_wready_i,
    
    // AXI4 Write Response Channel
    input  logic [`AXI4_B_ID_WIDTH-1:0]     axi_bid_i,
    input  logic [`AXI4_B_RESP_WIDTH-1:0]   axi_bresp_i,
    input  logic                             axi_bvalid_i,
    output logic                             axi_bready_o
);

    // ========================================================================
    // Internal Signal Declarations
    // ========================================================================
    logic [`AXI4_AW_ADDR_WIDTH-1:0] next_addr;
    logic [`AXI4_W_DATA_WIDTH-1:0]  write_data;
    
    // ========================================================================
    // Write Transaction Logic
    // ========================================================================
    always_comb begin
        // 使用定義的常數
        axi_awsize_o  = `AXI4_SIZE_8B;      // 8 bytes per transfer
        axi_awburst_o = `AXI4_BURST_INCR;   // Incrementing burst
        axi_awlen_o   = 8'd15;               // 16 beat burst
    end
    
    // Response checking
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            error_o <= 1'b0;
        end else if (axi_bvalid_i && axi_bready_o) begin
            // 使用定義的回應類型檢查
            case (axi_bresp_i)
                `AXI4_RESP_OKAY:   error_o <= 1'b0;
                `AXI4_RESP_EXOKAY: error_o <= 1'b0;
                `AXI4_RESP_SLVERR: error_o <= 1'b1;
                `AXI4_RESP_DECERR: error_o <= 1'b1;
                default:           error_o <= 1'b1;
            endcase
        end
    end

endmodule : axi_master
```

**範例：APB 介面定義**

檔案：`include/apb_if.svh`
```systemverilog
// ============================================================================
// File        : apb_if.svh
// Description : APB interface signal width definitions
// ============================================================================

`ifndef APB_IF_SVH
`define APB_IF_SVH

// ============================================================================
// APB Parameter Definitions
// ============================================================================
`define APB_ADDR_WIDTH      32
`define APB_DATA_WIDTH      32
`define APB_STRB_WIDTH      (`APB_DATA_WIDTH/8)

// ============================================================================
// APB Signal Widths
// ============================================================================
`define APB_PADDR_WIDTH     `APB_ADDR_WIDTH
`define APB_PWDATA_WIDTH    `APB_DATA_WIDTH
`define APB_PRDATA_WIDTH    `APB_DATA_WIDTH
`define APB_PSTRB_WIDTH     `APB_STRB_WIDTH

// ============================================================================
// APB Protection Bits
// ============================================================================
`define APB_PPROT_WIDTH     3
`define APB_PPROT_NORMAL    3'b000
`define APB_PPROT_PRIV      3'b001

`endif // APB_IF_SVH
```

**優點說明**

1. **集中管理**：所有位寬定義在一個地方，修改時只需改一處
2. **一致性**：確保所有使用該介面的模組位寬一致
3. **可參數化**：可透過修改 header file 快速調整整個系統的介面位寬
4. **避免魔術數字**：使用有意義的常數名稱（如 `AXI4_RESP_OKAY`）而非 `2'b00`
5. **重用性**：多個專案可共用同一套介面定義

**命名慣例**

```systemverilog
// 【推薦】Define 命名：大寫字母 + 底線，前綴為介面名稱
`define AXI4_ADDR_WIDTH     32          // AXI4 介面相關
`define APB_DATA_WIDTH      32          // APB 介面相關
`define NOC_FLIT_WIDTH      128         // NoC 介面相關
`define PCIE_TLP_WIDTH      256         // PCIe 介面相關

// 【推薦】常數定義：包含介面名稱 + 類型 + 值
`define AXI4_BURST_INCR     2'b01       // AXI4 burst type
`define APB_RESP_ERROR      1'b1        // APB response
`define NOC_VC_HIGH_PRIO    2'b11       // NoC virtual channel
```

### 3.4 檔案模板

```systemverilog
// ============================================================================
// Copyright (c) 2024 Company Name
// File        : module_name.sv
// Description : 簡短描述模組的功能（1-2 句話）
// Author      : Author Name
// Created     : YYYY-MM-DD
// ============================================================================

`include "common_defines.svh"

module module_name
    import common_pkg::*;
    import design_pkg::*;
#(
    parameter int PARAM_A = 32,
    parameter int PARAM_B = 64
) (
    // ============================================================================
    // Clock and Reset
    // ============================================================================
    input  logic clk_i,
    input  logic rst_ni,
    
    // ============================================================================
    // Input Ports
    // ============================================================================
    input  logic [PARAM_A-1:0] data_i,
    input  logic               valid_i,
    input  logic               ready_i,
    
    // ============================================================================
    // Output Ports
    // ============================================================================
    output logic [PARAM_B-1:0] result_o,
    output logic               valid_o,
    output logic               error_o
);

    // ============================================================================
    // Local Parameters
    // ============================================================================
    localparam int INTERNAL_WIDTH = PARAM_A + PARAM_B;
    
    // ============================================================================
    // Signal Declarations
    // ============================================================================
    // State machine
    state_e state_q, state_d;
    
    // Internal signals
    logic [INTERNAL_WIDTH-1:0] temp_data;
    logic                      internal_valid;
    
    // ============================================================================
    // Combinational Logic
    // ============================================================================
    always_comb begin
        // Default assignments
        state_d = state_q;
        
        // State machine logic
        case (state_q)
            IDLE: begin
                if (valid_i) begin
                    state_d = ACTIVE;
                end
            end
            // ...
        endcase
    end
    
    // ============================================================================
    // Sequential Logic
    // ============================================================================
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            state_q   <= IDLE;
            result_o  <= '0;
            valid_o   <= 1'b0;
        end else begin
            state_q   <= state_d;
            result_o  <= temp_data[PARAM_B-1:0];
            valid_o   <= internal_valid;
        end
    end
    
    // ============================================================================
    // Submodule Instantiation
    // ============================================================================
    sub_module #(
        .PARAM_X (PARAM_A),
        .PARAM_Y (PARAM_B)
    ) u_sub_module (
        .clk_i   (clk_i),
        .rst_ni  (rst_ni),
        .data_i  (data_i),
        .valid_i (valid_i),
        .data_o  (temp_data),
        .valid_o (internal_valid)
    );
    
    // ============================================================================
    // Assertions
    // ============================================================================
    // synopsys translate_off
    `ifndef SYNTHESIS
    
    property p_valid_stable;
        @(posedge clk_i) disable iff (!rst_ni)
        valid_o && !ready_i |=> $stable(result_o);
    endproperty
    
    assert property (p_valid_stable)
        else $error("Result changed while valid is high");
    
    `endif
    // synopsys translate_on

endmodule : module_name
```

---

## 4. 模組結構

### 4.1 Port 宣告順序

**【強制】按以下順序宣告 Port**

1. 時鐘
2. 重置
3. 輸入信號（按功能分組）
4. 輸出信號（按功能分組）
5. 雙向信號（inout，盡量避免使用）

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

### 4.2 Port 對齊

```systemverilog
// ✓ 正確：類型、名稱、註解對齊
module aligned_ports (
    input  logic        clk_i,          // System clock
    input  logic        rst_ni,         // Active-low reset
    input  logic [31:0] addr_i,         // Address input
    input  logic [63:0] data_i,         // Data input
    output logic        ready_o,        // Ready signal
    output logic [63:0] result_o        // Computation result
);
```

### 4.3 參數化

```systemverilog
// ✓ 正確：使用 parameter 增加重用性
module parameterized_fifo #(
    parameter int DATA_WIDTH = 32,
    parameter int DEPTH      = 16,
    // 【推薦】使用 localparam 自動計算衍生參數
    localparam int ADDR_WIDTH = $clog2(DEPTH)
) (
    input  logic                  clk_i,
    input  logic                  rst_ni,
    input  logic [DATA_WIDTH-1:0] wdata_i,
    input  logic                  wen_i,
    output logic [DATA_WIDTH-1:0] rdata_o,
    input  logic                  ren_i,
    output logic                  full_o,
    output logic                  empty_o
);

    // Internal signals use calculated parameters
    logic [ADDR_WIDTH-1:0] wptr_q, rptr_q;
    logic [DATA_WIDTH-1:0] mem [DEPTH];
    
endmodule
```

---

## 5. RTL 建模規則

### 5.1 時序邏輯（Flip-Flops）

**【強制】使用 `always_ff` 建模時序邏輯**

```systemverilog
// ✓ 正確：標準時序邏輯模板
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        // 【強制】重置時所有暫存器必須有初始值
        counter_q <= '0;
        state_q   <= IDLE;
        valid_q   <= 1'b0;
    end else begin
        // 【強制】使用非阻塞賦值 (<=)
        counter_q <= counter_d;
        state_q   <= state_d;
        valid_q   <= valid_d;
    end
end

// ❌ 錯誤：使用 always @(posedge clk) 而非 always_ff
always @(posedge clk_i) begin  // 不明確是時序還是組合
    data_q <= data_d;
end

// ❌ 錯誤：使用阻塞賦值
always_ff @(posedge clk_i) begin
    data_q = data_d;  // 應使用 <= 而非 =
end
```

### 5.2 組合邏輯

**【強制】使用 `always_comb` 建模組合邏輯**

```systemverilog
// ✓ 正確：組合邏輯模板，避免產生 latch
always_comb begin
    // 【強制】所有輸出必須有預設值
    state_d   = state_q;
    counter_d = counter_q;
    valid_d   = valid_q;
    result_o  = '0;
    
    // 狀態機邏輯
    case (state_q)
        IDLE: begin
            if (start_i) begin
                state_d   = ACTIVE;
                counter_d = '0;
            end
        end
        
        ACTIVE: begin
            counter_d = counter_q + 1'b1;
            result_o  = counter_q * DATA_SCALE;
            
            if (counter_q == MAX_COUNT) begin
                state_d = DONE;
                valid_d = 1'b1;
            end
        end
        
        DONE: begin
            if (ack_i) begin
                state_d = IDLE;
                valid_d = 1'b0;
            end
        end
        
        // 【強制】必須有 default case
        default: begin
            state_d = IDLE;
        end
    endcase
end

// ❌ 錯誤：缺少預設值，會產生 latch
always_comb begin
    case (sel)
        2'b00: out = a;
        2'b01: out = b;
        // 缺少其他情況，out 會產生 latch！
    endcase
end

// ❌ 錯誤：使用 always @* 而非 always_comb
always @* begin  // 應使用 always_comb
    result = a + b;
end
```

### 5.3 連續賦值

```systemverilog
// ✓ 正確：簡單邏輯使用 assign
assign sum       = a + b + c;
assign is_valid  = req_valid && !fifo_full;
assign next_addr = addr_q + INCREMENT;

// 【推薦】複雜運算式應斷行對齊
assign complex_condition = (state_q == ACTIVE) &&
                          (counter_q < MAX_COUNT) &&
                          (!error_flag) &&
                          (data_valid_i);
```

---

### 5.4 狀態機

**【推薦】使用三段式狀態機**

```systemverilog
// State type definition
typedef enum logic [2:0] {
    IDLE       = 3'b001,
    FETCH      = 3'b010,
    EXECUTE    = 3'b011,
    WRITE_BACK = 3'b100,
    ERROR      = 3'b101
} state_e;

state_e state_q, state_d;

// 第一段：時序邏輯，更新狀態
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        state_q <= IDLE;
    end else begin
        state_q <= state_d;
    end
end

// 第二段：組合邏輯，計算下一狀態
always_comb begin
    // Default: stay in current state
    state_d = state_q;
    
    case (state_q)
        IDLE: begin
            if (start_i) begin
                state_d = FETCH;
            end
        end
        
        FETCH: begin
            if (fetch_done) begin
                state_d = EXECUTE;
            end else if (fetch_error) begin
                state_d = ERROR;
            end
        end
        
        EXECUTE: begin
            if (exec_done) begin
                state_d = WRITE_BACK;
            end
        end
        
        WRITE_BACK: begin
            if (wb_done) begin
                state_d = IDLE;
            end
        end
        
        ERROR: begin
            if (error_clear) begin
                state_d = IDLE;
            end
        end
        
        default: state_d = IDLE;
    endcase
end

// 第三段：組合邏輯，產生輸出
always_comb begin
    // Default outputs
    fetch_en  = 1'b0;
    exec_en   = 1'b0;
    wb_en     = 1'b0;
    error_o   = 1'b0;
    
    case (state_q)
        IDLE: begin
            // Outputs for IDLE state
        end
        
        FETCH: begin
            fetch_en = 1'b1;
        end
        
        EXECUTE: begin
            exec_en = 1'b1;
        end
        
        WRITE_BACK: begin
            wb_en = 1'b1;
        end
        
        ERROR: begin
            error_o = 1'b1;
        end
        
        default: begin
            // Default outputs
        end
    endcase
end
```

---

### 5.5 Generate 循環 vs For 循環

**【強制】可綜合 RTL 代碼應優先使用 `generate` 而非 `for` 循環**

#### 5.4.1 基本原則

| 特性 | `generate` | `for` 循環 |
|------|-----------|-----------|
| **展開時機** | 編譯時（elaboration） | 運行時 |
| **產生結果** | 並行硬體實例 | 串聯邏輯或迭代 |
| **適用場景** | 重複硬體結構 | Testbench、初始化 |
| **可綜合性** | ✓ 完全可綜合 | ⚠️ 僅部分情況可綜合 |
| **時序影響** | 並行，無額外延遲 | 可能產生長組合路徑 |

**【原則】**
- RTL 代碼中創建重複硬體結構 → 使用 `generate`
- Testbench 中的測試迭代 → 使用 `for`
- 組合邏輯中的簡單運算 → 謹慎使用 `for`，考慮 `generate`

#### 5.4.2 正確使用範例

**場景 1：創建多個模組實例**

```systemverilog
// ✓ 正確：使用 generate 創建並行的硬體實例
module parallel_adders #(
    parameter int NUM_ADDERS = 8,
    parameter int DATA_WIDTH = 32
) (
    input  logic [DATA_WIDTH-1:0] a_i [NUM_ADDERS],
    input  logic [DATA_WIDTH-1:0] b_i [NUM_ADDERS],
    output logic [DATA_WIDTH-1:0] sum_o [NUM_ADDERS]
);

    // Generate 創建 8 個獨立的加法器（並行硬體）
    genvar i;
    generate
        for (i = 0; i < NUM_ADDERS; i++) begin : gen_adders
            assign sum_o[i] = a_i[i] + b_i[i];
        end
    endgenerate

endmodule

// ❌ 錯誤：使用 for 循環（會產生串聯邏輯或無法綜合）
module bad_adders #(
    parameter int NUM_ADDERS = 8,
    parameter int DATA_WIDTH = 32
) (
    input  logic [DATA_WIDTH-1:0] a_i [NUM_ADDERS],
    input  logic [DATA_WIDTH-1:0] b_i [NUM_ADDERS],
    output logic [DATA_WIDTH-1:0] sum_o [NUM_ADDERS]
);

    integer i;
    always_comb begin
        for (i = 0; i < NUM_ADDERS; i++) begin
            sum_o[i] = a_i[i] + b_i[i];  // 可能無法正確綜合
        end
    end

endmodule
```

**場景 2：多位元操作**

```systemverilog
// ✓ 正確：使用 generate 創建並行邏輯
module parallel_xor_32 (
    input  logic [31:0] data_i,
    output logic        parity_o
);

    logic [31:0] xor_tree [5];  // log2(32) = 5 層
    
    // Level 0: 原始輸入
    assign xor_tree[0] = data_i;
    
    // 使用 generate 建立 XOR tree（並行結構）
    genvar level, i;
    generate
        for (level = 1; level < 5; level++) begin : gen_level
            for (i = 0; i < (32 >> level); i++) begin : gen_xor
                assign xor_tree[level][i] = xor_tree[level-1][2*i] ^ 
                                           xor_tree[level-1][2*i+1];
            end
        end
    endgenerate
    
    assign parity_o = xor_tree[4][0];

endmodule

// ❌ 錯誤：使用 for 循環（產生長組合路徑）
module bad_xor (
    input  logic [31:0] data_i,
    output logic        parity_o
);

    integer i;
    logic result;
    
    always_comb begin
        result = 1'b0;
        for (i = 0; i < 32; i++) begin
            result = result ^ data_i[i];  // 串聯 32 個 XOR！
        end
    end
    
    assign parity_o = result;

endmodule
```

**場景 3：陣列初始化與操作**

```systemverilog
// ✓ 正確：使用 generate 並行處理陣列
module array_processor #(
    parameter int ARRAY_SIZE = 16,
    parameter int DATA_WIDTH = 8
) (
    input  logic [DATA_WIDTH-1:0] data_i [ARRAY_SIZE],
    output logic [DATA_WIDTH-1:0] data_o [ARRAY_SIZE]
);

    genvar i;
    generate
        for (i = 0; i < ARRAY_SIZE; i++) begin : gen_process
            // 每個元素獨立並行處理
            assign data_o[i] = data_i[i] + 8'd10;
        end
    endgenerate

endmodule

// ✓ 可接受：For 用於初始化（initial block）
module memory_init (
    input  logic        clk_i,
    input  logic [7:0]  addr_i,
    output logic [31:0] data_o
);

    logic [31:0] mem [256];
    
    // Initial block 中可以使用 for（僅用於初始化）
    initial begin
        for (int i = 0; i < 256; i++) begin
            mem[i] = i * 4;  // 初始化記憶體
        end
    end
    
    assign data_o = mem[addr_i];

endmodule
```

**場景 4：條件性硬體生成**

```systemverilog
// ✓ 正確：使用 generate if 條件生成硬體
module configurable_pipeline #(
    parameter int NUM_STAGES = 4,
    parameter bit ENABLE_STAGE [NUM_STAGES] = '{1, 1, 0, 1}
) (
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic [31:0] data_i,
    output logic [31:0] data_o
);

    logic [31:0] stage_data [NUM_STAGES+1];
    assign stage_data[0] = data_i;
    
    genvar i;
    generate
        for (i = 0; i < NUM_STAGES; i++) begin : gen_stages
            if (ENABLE_STAGE[i]) begin : gen_enabled
                // 生成 pipeline stage
                always_ff @(posedge clk_i or negedge rst_ni) begin
                    if (!rst_ni) begin
                        stage_data[i+1] <= '0;
                    end else begin
                        stage_data[i+1] <= stage_data[i];
                    end
                end
            end else begin : gen_bypass
                // 生成 bypass
                assign stage_data[i+1] = stage_data[i];
            end
        end
    endgenerate
    
    assign data_o = stage_data[NUM_STAGES];

endmodule
```

#### 5.4.3 For 循環的合理使用場景

**場景 1：組合邏輯中的簡單累加/歸約運算**

```systemverilog
// ✓ 可接受：簡單的歸約運算（工具會優化）
function automatic logic [7:0] count_ones(input logic [31:0] data);
    integer i;
    count_ones = 8'b0;
    for (i = 0; i < 32; i++) begin
        count_ones = count_ones + data[i];
    end
endfunction

// 但 generate 的樹狀結構更好（並行度更高）
module tree_counter (
    input  logic [31:0] data_i,
    output logic [5:0]  count_o
);

    logic [4:0] level1 [16];
    logic [4:0] level2 [8];
    logic [4:0] level3 [4];
    logic [4:0] level4 [2];
    
    genvar i;
    generate
        // Level 1: 每 2 位相加
        for (i = 0; i < 16; i++) begin : gen_l1
            assign level1[i] = {4'b0, data_i[2*i]} + {4'b0, data_i[2*i+1]};
        end
        
        // Level 2: 每 2 個 level1 相加
        for (i = 0; i < 8; i++) begin : gen_l2
            assign level2[i] = level1[2*i] + level1[2*i+1];
        end
        
        // Level 3
        for (i = 0; i < 4; i++) begin : gen_l3
            assign level3[i] = level2[2*i] + level2[2*i+1];
        end
        
        // Level 4
        for (i = 0; i < 2; i++) begin : gen_l4
            assign level4[i] = level3[2*i] + level3[2*i+1];
        end
    endgenerate
    
    assign count_o = level4[0] + level4[1];

endmodule
```

**場景 2：Testbench 中的測試迭代**

```systemverilog
// ✓ 正確：Testbench 中使用 for 循環
module test_memory;
    logic [31:0] memory [256];
    
    initial begin
        // 寫入測試
        for (int i = 0; i < 256; i++) begin
            memory[i] = $random;
        end
        
        // 讀取驗證
        for (int i = 0; i < 256; i++) begin
            $display("Memory[%0d] = %h", i, memory[i]);
        end
    end
endmodule
```

#### 5.4.4 常見錯誤與修正

**錯誤 1：在 always 塊中用 for 創建硬體**

```systemverilog
// ❌ 錯誤：在 always_ff 中用 for 循環
module bad_registers (
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic [31:0] data_i [8],
    output logic [31:0] data_o [8]
);

    integer i;
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (i = 0; i < 8; i++) begin
                data_o[i] <= '0;
            end
        end else begin
            for (i = 0; i < 8; i++) begin
                data_o[i] <= data_i[i];  // 可能產生共享 counter
            end
        end
    end

endmodule

// ✓ 正確：使用 generate
module good_registers (
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic [31:0] data_i [8],
    output logic [31:0] data_o [8]
);

    genvar i;
    generate
        for (i = 0; i < 8; i++) begin : gen_regs
            always_ff @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni) begin
                    data_o[i] <= '0;
                end else begin
                    data_o[i] <= data_i[i];
                end
            end
        end
    endgenerate

endmodule
```

**錯誤 2：For 循環變數作為索引**

```systemverilog
// ❌ 錯誤：整數變數作為陣列索引
module bad_mux (
    input  logic [31:0] data_i [8],
    input  logic [2:0]  sel_i,
    output logic [31:0] data_o
);

    integer i;
    always_comb begin
        data_o = '0;
        for (i = 0; i < 8; i++) begin
            if (i == sel_i) begin  // 整數比較，效率低
                data_o = data_i[i];
            end
        end
    end

endmodule

// ✓ 正確：使用 case 或直接索引
module good_mux (
    input  logic [31:0] data_i [8],
    input  logic [2:0]  sel_i,
    output logic [31:0] data_o
);

    // 方法 1：直接索引（最簡單）
    assign data_o = data_i[sel_i];
    
    // 方法 2：使用 case（更明確）
    always_comb begin
        case (sel_i)
            3'd0:    data_o = data_i[0];
            3'd1:    data_o = data_i[1];
            3'd2:    data_o = data_i[2];
            3'd3:    data_o = data_i[3];
            3'd4:    data_o = data_i[4];
            3'd5:    data_o = data_i[5];
            3'd6:    data_o = data_i[6];
            3'd7:    data_o = data_i[7];
            default: data_o = '0;
        endcase
    end

endmodule
```

**錯誤 3：For 循環產生相依邏輯**

```systemverilog
// ❌ 錯誤：For 循環產生串聯的相依運算
module bad_accumulator (
    input  logic [7:0] data_i [16],
    output logic [11:0] sum_o
);

    integer i;
    logic [11:0] temp;
    
    always_comb begin
        temp = 12'b0;
        for (i = 0; i < 16; i++) begin
            temp = temp + data_i[i];  // 16 級串聯加法！
        end
    end
    
    assign sum_o = temp;

endmodule

// ✓ 正確：使用 generate 建立加法器樹
module good_accumulator (
    input  logic [7:0]  data_i [16],
    output logic [11:0] sum_o
);

    // Level 1: 16 -> 8
    logic [8:0] level1 [8];
    
    genvar i;
    generate
        for (i = 0; i < 8; i++) begin : gen_l1
            assign level1[i] = {1'b0, data_i[2*i]} + {1'b0, data_i[2*i+1]};
        end
    endgenerate
    
    // Level 2: 8 -> 4
    logic [9:0] level2 [4];
    generate
        for (i = 0; i < 4; i++) begin : gen_l2
            assign level2[i] = {1'b0, level1[2*i]} + {1'b0, level1[2*i+1]};
        end
    endgenerate
    
    // Level 3: 4 -> 2
    logic [10:0] level3 [2];
    generate
        for (i = 0; i < 2; i++) begin : gen_l3
            assign level3[i] = {1'b0, level2[2*i]} + {1'b0, level2[2*i+1]};
        end
    endgenerate
    
    // Level 4: 2 -> 1
    assign sum_o = {1'b0, level3[0]} + {1'b0, level3[1]};

endmodule
```

#### 5.4.5 Generate 循環最佳實踐

**命名規範**

```systemverilog
// 【推薦】為 generate 塊命名，方便除錯
genvar i;
generate
    for (i = 0; i < NUM_UNITS; i++) begin : gen_processing_units
        processing_unit u_unit (
            .clk_i   (clk_i),
            .data_i  (data_i[i]),
            .result_o(result_o[i])
        );
    end
endgenerate

// 波形中會顯示：gen_processing_units[0].u_unit
//               gen_processing_units[1].u_unit
//               ...
```

**嵌套 Generate**

```systemverilog
// ✓ 正確：嵌套 generate 創建 2D 陣列
module mesh_noc #(
    parameter int ROWS = 4,
    parameter int COLS = 5
) (
    input  logic clk_i,
    input  logic rst_ni
);

    genvar row, col;
    generate
        for (row = 0; row < ROWS; row++) begin : gen_rows
            for (col = 0; col < COLS; col++) begin : gen_cols
                router #(
                    .X_COORD(col),
                    .Y_COORD(row)
                ) u_router (
                    .clk_i  (clk_i),
                    .rst_ni (rst_ni)
                    // ... ports
                );
            end
        end
    endgenerate

endmodule
```

**條件 Generate**

```systemverilog
// ✓ 正確：根據參數條件生成不同硬體
module configurable_unit #(
    parameter bit USE_PIPELINE = 1'b1,
    parameter int DATA_WIDTH   = 32
) (
    input  logic                  clk_i,
    input  logic [DATA_WIDTH-1:0] data_i,
    output logic [DATA_WIDTH-1:0] data_o
);

    generate
        if (USE_PIPELINE) begin : gen_pipelined
            logic [DATA_WIDTH-1:0] stage1_q, stage2_q;
            
            always_ff @(posedge clk_i) begin
                stage1_q <= data_i;
                stage2_q <= stage1_q;
            end
            
            assign data_o = stage2_q;
            
        end else begin : gen_combinational
            assign data_o = data_i;
        end
    endgenerate

endmodule
```

#### 5.4.6 檢查清單

**使用 Generate 時檢查：**
- [ ] Generate 變數使用 `genvar` 宣告
- [ ] Generate 塊有明確命名
- [ ] 嵌套層級不超過 3 層（可讀性）
- [ ] 條件 generate 的所有分支都有命名

**避免使用 For 循環當：**
- [ ] 創建多個模組實例
- [ ] 需要並行處理陣列元素
- [ ] 建立樹狀結構（如加法器樹）
- [ ] 產生重複的硬體單元

**可以使用 For 循環當：**
- [ ] Testbench 中的測試迭代
- [ ] Initial block 中的初始化
- [ ] Function 中的簡單累加（且工具能優化）

---

### 5.6 Pipeline 撰寫風格

```systemverilog
// State type definition
typedef enum logic [2:0] {
    IDLE       = 3'b001,
    FETCH      = 3'b010,
    EXECUTE    = 3'b011,
    WRITE_BACK = 3'b100,
    ERROR      = 3'b101
} state_e;

state_e state_q, state_d;

// 第一段：時序邏輯，更新狀態
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        state_q <= IDLE;
    end else begin
        state_q <= state_d;
    end
end

// 第二段：組合邏輯，計算下一狀態
always_comb begin
    // Default: stay in current state
    state_d = state_q;
    
    case (state_q)
        IDLE: begin
            if (start_i) begin
                state_d = FETCH;
            end
        end
        
        FETCH: begin
            if (fetch_done) begin
                state_d = EXECUTE;
            end else if (fetch_error) begin
                state_d = ERROR;
            end
        end
        
        EXECUTE: begin
            if (exec_done) begin
                state_d = WRITE_BACK;
            end
        end
        
        WRITE_BACK: begin
            if (wb_done) begin
                state_d = IDLE;
            end
        end
        
        ERROR: begin
            if (error_clear) begin
                state_d = IDLE;
            end
        end
        
        default: state_d = IDLE;
    endcase
end

// 第三段：組合邏輯，產生輸出
always_comb begin
    // Default outputs
    fetch_en  = 1'b0;
    exec_en   = 1'b0;
    wb_en     = 1'b0;
    error_o   = 1'b0;
    
    case (state_q)
        IDLE: begin
            // Outputs for IDLE state
        end
        
        FETCH: begin
            fetch_en = 1'b1;
        end
        
        EXECUTE: begin
            exec_en = 1'b1;
        end
        
        WRITE_BACK: begin
            wb_en = 1'b1;
        end
        
        ERROR: begin
            error_o = 1'b1;
        end
        
        default: begin
            // Default outputs
        end
    endcase
end
```

### 5.6 Pipeline 撰寫風格

**【重要】Pipeline 是高性能數位設計的核心技術，必須遵循一致的撰寫風格**

#### 5.6.1 Pipeline 基本原則

**資料路徑與控制路徑分離**
```systemverilog
// ✓ 正確：清楚區分資料與控制信號
// Stage 1 -> Stage 2 data path
logic [31:0] s1_data_q, s2_data_q;
logic [7:0]  s1_addr_q, s2_addr_q;

// Stage 1 -> Stage 2 control path
logic s1_valid_q, s2_valid_q;
logic s1_op_add_q, s2_op_add_q;
```

**命名慣例**
```systemverilog
// 【推薦】使用 s<N>_ 前綴表示 pipeline stage
logic [31:0] s1_data_q;    // Stage 1 data (registered)
logic [31:0] s1_data_d;    // Stage 1 data (combinational input)
logic [31:0] s2_data_q;    // Stage 2 data (registered)
logic [31:0] s2_data_d;    // Stage 2 data (combinational input)

// 或使用功能性命名
logic [31:0] fetch_data_q;    // Fetch stage
logic [31:0] decode_data_q;   // Decode stage
logic [31:0] execute_data_q;  // Execute stage
```

#### 5.6.2 簡單 Pipeline（無背壓）

**單級 Pipeline 範例**
```systemverilog
module simple_pipeline #(
    parameter int DATA_WIDTH = 32
) (
    input  logic                    clk_i,
    input  logic                    rst_ni,
    input  logic [DATA_WIDTH-1:0]   data_i,
    input  logic                    valid_i,
    output logic [DATA_WIDTH-1:0]   result_o,
    output logic                    valid_o
);

    // ========================================================================
    // Stage 1: Input Register
    // ========================================================================
    logic [DATA_WIDTH-1:0] s1_data_q;
    logic                  s1_valid_q;
    
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            s1_data_q  <= '0;
            s1_valid_q <= 1'b0;
        end else begin
            s1_data_q  <= data_i;
            s1_valid_q <= valid_i;
        end
    end
    
    // ========================================================================
    // Stage 2: Processing
    // ========================================================================
    logic [DATA_WIDTH-1:0] s2_data_d;
    logic [DATA_WIDTH-1:0] s2_data_q;
    logic                  s2_valid_q;
    
    // Combinational processing
    always_comb begin
        s2_data_d = s1_data_q * 2 + 1;  // 簡單運算
    end
    
    // Register stage 2
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            s2_data_q  <= '0;
            s2_valid_q <= 1'b0;
        end else begin
            s2_data_q  <= s2_data_d;
            s2_valid_q <= s1_valid_q;
        end
    end
    
    // ========================================================================
    // Output
    // ========================================================================
    assign result_o = s2_data_q;
    assign valid_o  = s2_valid_q;

endmodule
```

**多級 Pipeline 範例（ALU）**
```systemverilog
module alu_pipeline (
    input  logic        clk_i,
    input  logic        rst_ni,
    
    // Input
    input  logic [31:0] operand_a_i,
    input  logic [31:0] operand_b_i,
    input  logic [2:0]  alu_op_i,      // Operation: ADD, SUB, MUL, etc.
    input  logic        valid_i,
    
    // Output
    output logic [31:0] result_o,
    output logic        valid_o
);

    // ========================================================================
    // Stage 1: Input Register
    // ========================================================================
    logic [31:0] s1_op_a_q, s1_op_b_q;
    logic [2:0]  s1_alu_op_q;
    logic        s1_valid_q;
    
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            s1_op_a_q    <= '0;
            s1_op_b_q    <= '0;
            s1_alu_op_q  <= '0;
            s1_valid_q   <= 1'b0;
        end else begin
            s1_op_a_q    <= operand_a_i;
            s1_op_b_q    <= operand_b_i;
            s1_alu_op_q  <= alu_op_i;
            s1_valid_q   <= valid_i;
        end
    end
    
    // ========================================================================
    // Stage 2: ALU Operation
    // ========================================================================
    logic [31:0] s2_result_d, s2_result_q;
    logic        s2_valid_q;
    
    // ALU operations (combinational)
    always_comb begin
        s2_result_d = '0;
        case (s1_alu_op_q)
            3'b000:  s2_result_d = s1_op_a_q + s1_op_b_q;        // ADD
            3'b001:  s2_result_d = s1_op_a_q - s1_op_b_q;        // SUB
            3'b010:  s2_result_d = s1_op_a_q & s1_op_b_q;        // AND
            3'b011:  s2_result_d = s1_op_a_q | s1_op_b_q;        // OR
            3'b100:  s2_result_d = s1_op_a_q ^ s1_op_b_q;        // XOR
            3'b101:  s2_result_d = s1_op_a_q << s1_op_b_q[4:0];  // SLL
            3'b110:  s2_result_d = s1_op_a_q >> s1_op_b_q[4:0];  // SRL
            default: s2_result_d = '0;
        endcase
    end
    
    // Register stage 2
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            s2_result_q <= '0;
            s2_valid_q  <= 1'b0;
        end else begin
            s2_result_q <= s2_result_d;
            s2_valid_q  <= s1_valid_q;
        end
    end
    
    // ========================================================================
    // Stage 3: Output Register (增加一級提升時序)
    // ========================================================================
    logic [31:0] s3_result_q;
    logic        s3_valid_q;
    
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            s3_result_q <= '0;
            s3_valid_q  <= 1'b0;
        end else begin
            s3_result_q <= s2_result_q;
            s3_valid_q  <= s2_valid_q;
        end
    end
    
    // Output assignment
    assign result_o = s3_result_q;
    assign valid_o  = s3_valid_q;

endmodule
```

#### 5.6.3 帶背壓的 Pipeline（Valid-Ready 握手）

**【重要】處理背壓時，valid 和 ready 信號的正確處理**

```systemverilog
module pipeline_with_backpressure #(
    parameter int DATA_WIDTH = 32
) (
    input  logic                    clk_i,
    input  logic                    rst_ni,
    
    // Input interface (valid-ready)
    input  logic [DATA_WIDTH-1:0]   data_i,
    input  logic                    valid_i,
    output logic                    ready_o,
    
    // Output interface (valid-ready)
    output logic [DATA_WIDTH-1:0]   data_o,
    output logic                    valid_o,
    input  logic                    ready_i
);

    // ========================================================================
    // Stage 1: Input Stage
    // ========================================================================
    logic [DATA_WIDTH-1:0] s1_data_q;
    logic                  s1_valid_q;
    logic                  s1_ready;
    
    // Stage 1 can accept new data when:
    // 1. It's empty (!s1_valid_q), OR
    // 2. Next stage is ready to accept (s2_ready)
    assign s1_ready = !s1_valid_q || s2_ready;
    assign ready_o  = s1_ready;
    
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            s1_data_q  <= '0;
            s1_valid_q <= 1'b0;
        end else begin
            if (s1_ready) begin
                s1_data_q  <= data_i;
                s1_valid_q <= valid_i;
            end
            // else: stall, keep current value
        end
    end
    
    // ========================================================================
    // Stage 2: Processing Stage
    // ========================================================================
    logic [DATA_WIDTH-1:0] s2_data_d, s2_data_q;
    logic                  s2_valid_q;
    logic                  s2_ready;
    
    // Combinational processing
    always_comb begin
        // 簡單處理：乘以 2 加 1
        s2_data_d = (s1_data_q << 1) + 1'b1;
    end
    
    // Stage 2 can accept new data when next stage is ready
    assign s2_ready = !s2_valid_q || ready_i;
    
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            s2_data_q  <= '0;
            s2_valid_q <= 1'b0;
        end else begin
            if (s2_ready) begin
                s2_data_q  <= s2_data_d;
                s2_valid_q <= s1_valid_q;
            end
            // else: stall, keep current value
        end
    end
    
    // ========================================================================
    // Output Assignment
    // ========================================================================
    assign data_o  = s2_data_q;
    assign valid_o = s2_valid_q;

endmodule
```

**Valid-Ready 握手規則**
```systemverilog
// 【強制】Valid-Ready 握手協定規則：
// 1. valid 一旦拉高，必須保持直到 ready 也為高（握手完成）
// 2. ready 可以在任何時候變化
// 3. 資料在 valid && ready 時傳輸
// 4. valid 不能依賴 ready（避免組合邏輯迴路）

// ✓ 正確：valid 獨立於 ready
always_ff @(posedge clk_i) begin
    if (condition) begin
        valid_q <= 1'b1;
        data_q  <= new_data;
    end else if (valid_q && ready_i) begin
        valid_q <= 1'b0;  // 握手完成，清除 valid
    end
end

// ❌ 錯誤：valid 依賴 ready（組合邏輯迴路）
assign valid_o = ready_i && some_condition;  // 危險！
```

#### 5.6.4 Pipeline 控制信號

**Stall（停頓）和 Flush（清空）**

```systemverilog
module pipeline_with_control #(
    parameter int DATA_WIDTH = 32,
    parameter int NUM_STAGES = 3
) (
    input  logic                    clk_i,
    input  logic                    rst_ni,
    
    // Control signals
    input  logic                    stall_i,      // 暫停 pipeline
    input  logic                    flush_i,      // 清空 pipeline
    
    // Data path
    input  logic [DATA_WIDTH-1:0]   data_i,
    input  logic                    valid_i,
    output logic [DATA_WIDTH-1:0]   result_o,
    output logic                    valid_o
);

    // ========================================================================
    // Pipeline Stages
    // ========================================================================
    logic [DATA_WIDTH-1:0] stage_data_q [NUM_STAGES];
    logic                  stage_valid_q [NUM_STAGES];
    
    // ========================================================================
    // Stage 1: Input with Stall/Flush Control
    // ========================================================================
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            stage_data_q[0]  <= '0;
            stage_valid_q[0] <= 1'b0;
        end else if (flush_i) begin
            // Flush: clear valid bits (convert to bubble)
            stage_valid_q[0] <= 1'b0;
            // 資料可以保留或清除（取決於設計需求）
        end else if (!stall_i) begin
            // Normal operation: advance pipeline
            stage_data_q[0]  <= data_i;
            stage_valid_q[0] <= valid_i;
        end
        // else: stall, keep current values
    end
    
    // ========================================================================
    // Middle Stages
    // ========================================================================
    genvar i;
    generate
        for (i = 1; i < NUM_STAGES; i++) begin : gen_pipeline_stages
            always_ff @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni) begin
                    stage_data_q[i]  <= '0;
                    stage_valid_q[i] <= 1'b0;
                end else if (flush_i) begin
                    stage_valid_q[i] <= 1'b0;
                end else if (!stall_i) begin
                    stage_data_q[i]  <= stage_data_q[i-1];
                    stage_valid_q[i] <= stage_valid_q[i-1];
                end
            end
        end
    endgenerate
    
    // ========================================================================
    // Output
    // ========================================================================
    assign result_o = stage_data_q[NUM_STAGES-1];
    assign valid_o  = stage_valid_q[NUM_STAGES-1];

endmodule
```

#### 5.6.5 Pipeline Bubble 處理

**插入 Bubble（空泡）處理資料相依性**

```systemverilog
module pipeline_with_bubble (
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic [31:0] data_i,
    input  logic        valid_i,
    input  logic        insert_bubble_i,  // 插入 bubble 信號
    output logic [31:0] data_o,
    output logic        valid_o
);

    // ========================================================================
    // Stage 1
    // ========================================================================
    logic [31:0] s1_data_q;
    logic        s1_valid_q;
    
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            s1_data_q  <= '0;
            s1_valid_q <= 1'b0;
        end else begin
            s1_data_q <= data_i;
            // 插入 bubble：強制 valid 為 0
            s1_valid_q <= valid_i && !insert_bubble_i;
        end
    end
    
    // ========================================================================
    // Stage 2
    // ========================================================================
    logic [31:0] s2_data_q;
    logic        s2_valid_q;
    
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            s2_data_q  <= '0;
            s2_valid_q <= 1'b0;
        end else begin
            s2_data_q  <= s1_data_q;
            s2_valid_q <= s1_valid_q;  // Bubble 會自動向後傳播
        end
    end
    
    assign data_o  = s2_data_q;
    assign valid_o = s2_valid_q;

endmodule
```

#### 5.6.6 進階：Skid Buffer

**【進階】Skid Buffer 用於打破 ready 信號的組合邏輯路徑**

```systemverilog
module skid_buffer #(
    parameter int DATA_WIDTH = 32
) (
    input  logic                    clk_i,
    input  logic                    rst_ni,
    
    // Input interface
    input  logic [DATA_WIDTH-1:0]   data_i,
    input  logic                    valid_i,
    output logic                    ready_o,
    
    // Output interface
    output logic [DATA_WIDTH-1:0]   data_o,
    output logic                    valid_o,
    input  logic                    ready_i
);

    // ========================================================================
    // Skid Buffer Registers
    // ========================================================================
    logic [DATA_WIDTH-1:0] data_q, skid_data_q;
    logic                  valid_q, skid_valid_q;
    logic                  use_skid;
    
    // ========================================================================
    // Skid Buffer Logic
    // ========================================================================
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            data_q       <= '0;
            valid_q      <= 1'b0;
            skid_data_q  <= '0;
            skid_valid_q <= 1'b0;
        end else begin
            // 正常路徑：輸入到輸出
            if (ready_i || !valid_q) begin
                data_q  <= data_i;
                valid_q <= valid_i;
            end
            
            // Skid 路徑：當 output stall 時暫存新資料
            if (valid_i && valid_q && !ready_i) begin
                skid_data_q  <= data_i;
                skid_valid_q <= 1'b1;
            end else if (ready_i) begin
                skid_valid_q <= 1'b0;
            end
        end
    end
    
    // ========================================================================
    // Output Multiplexing
    // ========================================================================
    assign use_skid = skid_valid_q;
    assign data_o   = use_skid ? skid_data_q : data_q;
    assign valid_o  = use_skid ? skid_valid_q : valid_q;
    
    // Ready 信號：當 skid buffer 為空時才能接受新資料
    assign ready_o  = !skid_valid_q;

endmodule
```

#### 5.6.7 參數化 Pipeline 設計

**【推薦】使用參數和 generate 建立可配置的 pipeline**

```systemverilog
module parameterized_pipeline #(
    parameter int DATA_WIDTH  = 32,
    parameter int NUM_STAGES  = 4,     // 可配置的 pipeline 級數
    parameter bit ENABLE_BYPASS = 1'b0 // 旁路選項
) (
    input  logic                    clk_i,
    input  logic                    rst_ni,
    
    // Control
    input  logic                    flush_i,
    input  logic                    stall_i,
    
    // Input interface
    input  logic [DATA_WIDTH-1:0]   data_i,
    input  logic                    valid_i,
    output logic                    ready_o,
    
    // Output interface
    output logic [DATA_WIDTH-1:0]   data_o,
    output logic                    valid_o,
    input  logic                    ready_i
);

    // ========================================================================
    // Pipeline Registers Array
    // ========================================================================
    logic [DATA_WIDTH-1:0] stage_data_q  [NUM_STAGES];
    logic                  stage_valid_q [NUM_STAGES];
    logic                  stage_ready   [NUM_STAGES];
    
    // ========================================================================
    // Generate Pipeline Stages
    // ========================================================================
    genvar i;
    generate
        // First stage: connect to input
        always_ff @(posedge clk_i or negedge rst_ni) begin
            if (!rst_ni) begin
                stage_data_q[0]  <= '0;
                stage_valid_q[0] <= 1'b0;
            end else if (flush_i) begin
                stage_valid_q[0] <= 1'b0;
            end else if (!stall_i && stage_ready[0]) begin
                stage_data_q[0]  <= data_i;
                stage_valid_q[0] <= valid_i;
            end
        end
        
        // Middle and last stages
        for (i = 1; i < NUM_STAGES; i++) begin : gen_stages
            always_ff @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni) begin
                    stage_data_q[i]  <= '0;
                    stage_valid_q[i] <= 1'b0;
                end else if (flush_i) begin
                    stage_valid_q[i] <= 1'b0;
                end else if (!stall_i && stage_ready[i]) begin
                    stage_data_q[i]  <= stage_data_q[i-1];
                    stage_valid_q[i] <= stage_valid_q[i-1];
                end
            end
        end
        
        // Ready signal propagation (combinational)
        for (i = 0; i < NUM_STAGES-1; i++) begin : gen_ready
            assign stage_ready[i] = !stage_valid_q[i+1] || stage_ready[i+1];
        end
    endgenerate
    
    // Last stage ready depends on output ready
    assign stage_ready[NUM_STAGES-1] = ready_i || !stage_valid_q[NUM_STAGES-1];
    
    // ========================================================================
    // Optional Bypass Path (NUM_STAGES == 0)
    // ========================================================================
    generate
        if (ENABLE_BYPASS && NUM_STAGES == 0) begin : gen_bypass
            // 直接連接輸入到輸出
            assign data_o  = data_i;
            assign valid_o = valid_i;
            assign ready_o = ready_i;
        end else begin : gen_normal
            // 正常 pipeline 輸出
            assign data_o  = stage_data_q[NUM_STAGES-1];
            assign valid_o = stage_valid_q[NUM_STAGES-1];
            assign ready_o = stage_ready[0];
        end
    endgenerate

endmodule
```

**可重用的 Pipeline Register Slice**

```systemverilog
// 可重用的單級 pipeline register slice
module pipe_reg_slice #(
    parameter int DATA_WIDTH = 32,
    parameter bit USE_READY  = 1'b1  // 是否使用 ready 信號
) (
    input  logic                    clk_i,
    input  logic                    rst_ni,
    
    // Input
    input  logic [DATA_WIDTH-1:0]   data_i,
    input  logic                    valid_i,
    output logic                    ready_o,
    
    // Output
    output logic [DATA_WIDTH-1:0]   data_o,
    output logic                    valid_o,
    input  logic                    ready_i
);

    generate
        if (USE_READY) begin : gen_with_backpressure
            // 帶背壓控制
            logic [DATA_WIDTH-1:0] data_q;
            logic                  valid_q;
            
            assign ready_o = !valid_q || ready_i;
            
            always_ff @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni) begin
                    data_q  <= '0;
                    valid_q <= 1'b0;
                end else if (ready_o) begin
                    data_q  <= data_i;
                    valid_q <= valid_i;
                end
            end
            
            assign data_o  = data_q;
            assign valid_o = valid_q;
            
        end else begin : gen_without_backpressure
            // 無背壓，簡單 pipeline register
            logic [DATA_WIDTH-1:0] data_q;
            logic                  valid_q;
            
            always_ff @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni) begin
                    data_q  <= '0;
                    valid_q <= 1'b0;
                end else begin
                    data_q  <= data_i;
                    valid_q <= valid_i;
                end
            end
            
            assign data_o  = data_q;
            assign valid_o = valid_q;
            assign ready_o = 1'b1;  // 永遠 ready
        end
    endgenerate

endmodule
```

**使用範例：組合多個 Pipeline Slice**

```systemverilog
module multi_stage_pipe #(
    parameter int DATA_WIDTH = 64,
    parameter int NUM_STAGES = 5
) (
    input  logic                    clk_i,
    input  logic                    rst_ni,
    input  logic [DATA_WIDTH-1:0]   data_i,
    input  logic                    valid_i,
    output logic                    ready_o,
    output logic [DATA_WIDTH-1:0]   data_o,
    output logic                    valid_o,
    input  logic                    ready_i
);

    // Stage interconnect signals
    logic [DATA_WIDTH-1:0] stage_data  [NUM_STAGES+1];
    logic                  stage_valid [NUM_STAGES+1];
    logic                  stage_ready [NUM_STAGES+1];
    
    // Connect input
    assign stage_data[0]  = data_i;
    assign stage_valid[0] = valid_i;
    assign ready_o        = stage_ready[0];
    
    // Connect output
    assign data_o         = stage_data[NUM_STAGES];
    assign valid_o        = stage_valid[NUM_STAGES];
    assign stage_ready[NUM_STAGES] = ready_i;
    
    // Generate pipeline stages
    genvar i;
    generate
        for (i = 0; i < NUM_STAGES; i++) begin : gen_pipe_stages
            pipe_reg_slice #(
                .DATA_WIDTH (DATA_WIDTH),
                .USE_READY  (1'b1)
            ) u_pipe_slice (
                .clk_i    (clk_i),
                .rst_ni   (rst_ni),
                .data_i   (stage_data[i]),
                .valid_i  (stage_valid[i]),
                .ready_o  (stage_ready[i]),
                .data_o   (stage_data[i+1]),
                .valid_o  (stage_valid[i+1]),
                .ready_i  (stage_ready[i+1])
            );
        end
    endgenerate

endmodule
```

#### 5.6.8 Pipeline 設計檢查清單

**設計 Pipeline 時必須檢查：**

- [ ] 每一級 pipeline 都有明確的 `_q` 暫存器
- [ ] Valid 信號正確地跟隨資料傳播
- [ ] 如有背壓，ready 邏輯正確實現
- [ ] Valid 不依賴 ready（避免組合迴路）
- [ ] Stall 時資料不會丟失
- [ ] Flush 時正確清除 valid 位元
- [ ] 沒有跨 stage 的組合邏輯路徑
- [ ] 各 stage 之間的 timing 滿足要求
- [ ] 資料相依性（data hazard）正確處理
- [ ] 參數化設計時考慮邊界情況（NUM_STAGES = 0, 1）

**常見錯誤**

```systemverilog
// ❌ 錯誤 1：valid 依賴 ready（組合迴路）
assign valid_o = ready_i && internal_valid;

// ❌ 錯誤 2：跨 stage 組合邏輯
assign s2_result = s1_data_q + s2_data_q;  // 兩個不同 stage 的資料直接運算

// ❌ 錯誤 3：stall 時資料丟失
always_ff @(posedge clk_i) begin
    if (!stall_i) begin
        data_q <= data_i;
    end else begin
        data_q <= '0;  // 錯誤！stall 時應該保持原值
    end
end

// ❌ 錯誤 4：flush 沒有清除 valid
always_ff @(posedge clk_i) begin
    if (flush_i) begin
        data_q <= '0;  // 只清資料不清 valid，無效！
    end
end

// ❌ 錯誤 5：參數化設計未處理邊界情況
logic [DATA_WIDTH-1:0] stage_q [NUM_STAGES];
assign output = stage_q[NUM_STAGES-1];  // NUM_STAGES=0 時會出錯！
```

---

## 6. 時鐘與重置

### 6.1 時鐘命名

```systemverilog
// 【推薦】多時鐘域清楚命名
input logic clk_sys_i;      // 系統時鐘
input logic clk_cpu_i;      // CPU 時鐘
input logic clk_peri_i;     // 外設時鐘
input logic clk_ddr_i;      // DDR 時鐘
```

### 6.2 重置策略

**同步重置**
```systemverilog
// ✓ 適用於大部分設計（面積小，時序友好）
always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
        // Synchronous reset logic
        data_q <= '0;
    end else begin
        data_q <= data_d;
    end
end
```

**異步重置**
```systemverilog
// ✓ 適用於關鍵控制路徑或跨時鐘域
always_ff @(posedge clk_i or negedge arst_ni) begin
    if (!arst_ni) begin
        // Asynchronous reset logic
        critical_flag_q <= 1'b0;
    end else begin
        critical_flag_q <= critical_flag_d;
    end
end
```

### 6.3 禁止的時鐘使用

```systemverilog
// ❌ 禁止：手動 clock gating（應由工具處理）
assign gated_clk = clk_i & enable;

always_ff @(posedge gated_clk) begin  // 危險！
    data_q <= data_d;
end

// ❌ 禁止：使用信號作為時鐘
always_ff @(posedge data_valid) begin  // 錯誤！
    counter <= counter + 1;
end

// ✓ 正確：使用 enable 信號
always_ff @(posedge clk_i) begin
    if (enable) begin
        counter_q <= counter_q + 1'b1;
    end
end
```

---

## 7. 禁止使用的寫法

### 7.1 混合阻塞與非阻塞賦值

```systemverilog
// ❌ 錯誤：在同一 always 塊混用
always_ff @(posedge clk_i) begin
    a <= b;        // 非阻塞
    c = a + 1;     // 阻塞 - 嚴重錯誤！
end

// ✓ 正確：時序邏輯只用非阻塞賦值
always_ff @(posedge clk_i) begin
    a <= b;
    c <= a + 1'b1;
end

// ✓ 正確：組合邏輯只用阻塞賦值
always_comb begin
    temp = a + b;
    result = temp * c;
end
```

### 7.2 多重驅動

```systemverilog
// ❌ 錯誤：多個 always 塊驅動同一信號
always_ff @(posedge clk_i) begin
    data_q <= data_i;
end

always_comb begin
    data_q = other_value;  // 錯誤：data_q 被兩處驅動！
end

// ✓ 正確：只有一處驅動
always_comb begin
    data_d = condition ? data_i : other_value;
end

always_ff @(posedge clk_i) begin
    data_q <= data_d;
end
```

### 7.3 不完整的敏感度列表

```systemverilog
// ❌ 錯誤：使用 always @(...) 且敏感度列表不完整
always @(a) begin  // 缺少 b 和 c
    result = a + b + c;
end

// ✓ 正確：使用 always_comb（自動處理敏感度）
always_comb begin
    result = a + b + c;
end
```

### 7.4 Latch 產生

```systemverilog
// ❌ 錯誤：組合邏輯缺少預設值
always_comb begin
    case (sel)
        2'b00: out = a;
        2'b01: out = b;
        // 缺少 2'b10 和 2'b11，產生 latch！
    endcase
end

// ✓ 正確：有預設值或完整的 case
always_comb begin
    case (sel)
        2'b00:   out = a;
        2'b01:   out = b;
        2'b10:   out = c;
        default: out = d;
    endcase
end

// ✓ 正確：使用預設賦值
always_comb begin
    out = d;  // 預設值
    case (sel)
        2'b00: out = a;
        2'b01: out = b;
        2'b10: out = c;
    endcase
end
```

### 7.5 位寬不匹配

```systemverilog
// ❌ 錯誤：隱式位寬轉換
logic [7:0]  byte_data;
logic [15:0] word_data;
assign byte_data = word_data;  // 高位被截斷，可能非預期

// ✓ 正確：明確截斷
assign byte_data = word_data[7:0];

// ✓ 正確：明確擴展
assign word_data = {8'b0, byte_data};  // 零擴展
```

### 7.6 使用 `x` 或 `z` 在可綜合代碼

```systemverilog
// ❌ 錯誤：在可綜合代碼使用 x
logic [3:0] data;
assign data = 4'bxxxx;  // 綜合工具行為未定義

// ✓ 正確：使用明確的值
assign data = 4'b0000;

// 注意：`x` 只能用於 testbench
initial begin
    data = 4'bxxxx;  // 在 testbench 中 OK
end
```

### 7.7 濫用 For 循環創建硬體

**【強制】不要在可綜合 RTL 中用 for 循環創建重複硬體結構**

```systemverilog
// ❌ 錯誤：For 循環創建硬體實例
module bad_example (
    input  logic        clk_i,
    input  logic [7:0]  data_i [16],
    output logic [7:0]  data_o [16]
);

    integer i;
    always_ff @(posedge clk_i) begin
        for (i = 0; i < 16; i++) begin
            data_o[i] <= data_i[i] + 8'd1;  // 可能產生意外的共享邏輯
        end
    end

endmodule

// ✓ 正確：使用 generate 創建獨立並行硬體
module good_example (
    input  logic        clk_i,
    input  logic [7:0]  data_i [16],
    output logic [7:0]  data_o [16]
);

    genvar i;
    generate
        for (i = 0; i < 16; i++) begin : gen_registers
            always_ff @(posedge clk_i) begin
                data_o[i] <= data_i[i] + 8'd1;  // 16 個獨立的加法器
            end
        end
    endgenerate

endmodule

// ❌ 錯誤：For 循環產生串聯邏輯路徑
module bad_accumulator (
    input  logic [7:0] data_i [8],
    output logic [10:0] sum_o
);

    integer i;
    logic [10:0] temp;
    
    always_comb begin
        temp = 11'b0;
        for (i = 0; i < 8; i++) begin
            temp = temp + data_i[i];  // 串聯 8 級加法！時序差
        end
    end
    
    assign sum_o = temp;

endmodule

// ✓ 正確：使用 generate 創建並行加法樹
module good_accumulator (
    input  logic [7:0]  data_i [8],
    output logic [10:0] sum_o
);

    logic [8:0] level1 [4];
    logic [9:0] level2 [2];
    
    genvar i;
    generate
        // Level 1: 8 -> 4
        for (i = 0; i < 4; i++) begin : gen_l1
            assign level1[i] = {1'b0, data_i[2*i]} + {1'b0, data_i[2*i+1]};
        end
        
        // Level 2: 4 -> 2
        for (i = 0; i < 2; i++) begin : gen_l2
            assign level2[i] = {1'b0, level1[2*i]} + {1'b0, level1[2*i+1]};
        end
    endgenerate
    
    // Final stage
    assign sum_o = {1'b0, level2[0]} + {1'b0, level2[1]};

endmodule
```

**【參考】詳見 [5.5 Generate 循環 vs For 循環](#55-generate-循環-vs-for-循環) 完整說明**

---

## 8. 常見的運算優化技巧

### 8.1 加法器優化

#### 8.1.1 基本加法器

```systemverilog
// 標準加法器（綜合工具會自動優化）
logic [31:0] sum;
assign sum = a + b;
```

#### 8.1.2 進位保存加法器（Carry-Save Adder）

**【適用】多個運算元相加（如：a + b + c + d）**

```systemverilog
// ✓ 正確：使用進位保存加法器減少關鍵路徑
module carry_save_adder_4to2 (
    input  logic [31:0] a_i,
    input  logic [31:0] b_i,
    input  logic [31:0] c_i,
    input  logic [31:0] d_i,
    output logic [31:0] sum_o
);

    // Stage 1: CSA tree (3:2 compressor)
    logic [31:0] s1_sum, s1_carry;
    logic [31:0] s2_sum, s2_carry;
    
    // First level: a + b + c -> sum + carry
    assign s1_sum   = a_i ^ b_i ^ c_i;
    assign s1_carry = ((a_i & b_i) | (b_i & c_i) | (c_i & a_i)) << 1;
    
    // Second level: sum + carry + d
    assign s2_sum   = s1_sum ^ s1_carry ^ d_i;
    assign s2_carry = ((s1_sum & s1_carry) | (s1_carry & d_i) | (d_i & s1_sum)) << 1;
    
    // Final: carry propagate adder
    assign sum_o = s2_sum + s2_carry;

endmodule
```

#### 8.1.3 飽和加法（Saturation Addition）

```systemverilog
// 飽和加法：防止溢出
module saturating_adder #(
    parameter int WIDTH = 16
) (
    input  logic [WIDTH-1:0] a_i,
    input  logic [WIDTH-1:0] b_i,
    output logic [WIDTH-1:0] sum_o
);

    logic [WIDTH:0] temp_sum;  // 擴展 1 位檢查溢出
    
    assign temp_sum = {1'b0, a_i} + {1'b0, b_i};
    
    // 飽和處理
    assign sum_o = temp_sum[WIDTH] ? {WIDTH{1'b1}} : temp_sum[WIDTH-1:0];

endmodule
```

### 8.2 乘法器優化

#### 8.2.1 常數乘法優化

**【重要】乘以 2 的冪次使用移位**

```systemverilog
// ❌ 不好：使用乘法器
assign result = data * 8;

// ✓ 好：使用移位
assign result = data << 3;

// ✓ 好：乘以 (2^n ± 1) 可優化
assign result = (data << 5) - data;  // data * 31 = data * (32 - 1)
assign result = (data << 4) + data;  // data * 17 = data * (16 + 1)
```

**常見常數乘法分解**

```systemverilog
// 乘以 3:  a * 3 = (a << 1) + a
// 乘以 5:  a * 5 = (a << 2) + a
// 乘以 7:  a * 7 = (a << 3) - a
// 乘以 9:  a * 9 = (a << 3) + a
// 乘以 15: a * 15 = (a << 4) - a
// 乘以 17: a * 17 = (a << 4) + a

module const_multiplier (
    input  logic [15:0] data_i,
    output logic [19:0] mul3_o,   // data * 3
    output logic [19:0] mul5_o,   // data * 5
    output logic [19:0] mul7_o    // data * 7
);

    assign mul3_o = {data_i, 2'b0} + {2'b0, data_i};           // (data << 2) + data
    assign mul5_o = {data_i, 3'b0} + {3'b0, data_i};           // (data << 3) + data
    assign mul7_o = {data_i, 4'b0} - {4'b0, data_i};           // (data << 4) - data

endmodule
```

#### 8.2.2 Booth 編碼乘法器

**【進階】減少部分積數量**

```systemverilog
// Radix-4 Booth 編碼乘法器（僅示意，實際由工具生成）
module booth_multiplier #(
    parameter int WIDTH = 16
) (
    input  logic [WIDTH-1:0]   a_i,
    input  logic [WIDTH-1:0]   b_i,
    output logic [2*WIDTH-1:0] product_o
);

    // 實務上：讓綜合工具自動推斷最佳乘法器結構
    // 對於 ASIC，工具會使用 Booth 或 Wallace tree
    // 對於 FPGA，工具會使用 DSP block
    
    assign product_o = a_i * b_i;

endmodule
```

#### 8.2.3 Pipeline 乘法器

```systemverilog
module pipelined_multiplier #(
    parameter int WIDTH = 32,
    parameter int STAGES = 3  // Pipeline 級數
) (
    input  logic                clk_i,
    input  logic                rst_ni,
    input  logic [WIDTH-1:0]    a_i,
    input  logic [WIDTH-1:0]    b_i,
    input  logic                valid_i,
    output logic [2*WIDTH-1:0]  product_o,
    output logic                valid_o
);

    // Pipeline 暫存器
    logic [WIDTH-1:0]   a_q [STAGES];
    logic [WIDTH-1:0]   b_q [STAGES];
    logic               valid_q [STAGES];
    logic [2*WIDTH-1:0] product_q [STAGES];
    
    // Stage 0: Input register
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            a_q[0]     <= '0;
            b_q[0]     <= '0;
            valid_q[0] <= 1'b0;
        end else begin
            a_q[0]     <= a_i;
            b_q[0]     <= b_i;
            valid_q[0] <= valid_i;
        end
    end
    
    // Multiplication (let tool pipeline it)
    assign product_q[0] = a_q[0] * b_q[0];
    
    // Pipeline stages
    genvar i;
    generate
        for (i = 1; i < STAGES; i++) begin : gen_pipe_stages
            always_ff @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni) begin
                    product_q[i] <= '0;
                    valid_q[i]   <= 1'b0;
                end else begin
                    product_q[i] <= product_q[i-1];
                    valid_q[i]   <= valid_q[i-1];
                end
            end
        end
    endgenerate
    
    assign product_o = product_q[STAGES-1];
    assign valid_o   = valid_q[STAGES-1];

endmodule
```

### 8.3 除法器優化

#### 8.3.1 常數除法優化

**【重要】除以 2 的冪次使用移位**

```systemverilog
// ❌ 不好：使用除法器（面積大、延遲長）
assign result = data / 16;

// ✓ 好：使用算術右移
assign result = data >>> 4;  // 有號數除以 16
assign result = data >> 4;   // 無號數除以 16
```

#### 8.3.2 倒數乘法替代除法

```systemverilog
// 【技巧】除以常數 = 乘以其倒數（定點數）
// 例如：x / 3 ≈ (x * 0x55555556) >> 32  (for 32-bit unsigned)

module divide_by_3 (
    input  logic [31:0] dividend_i,
    output logic [31:0] quotient_o
);

    // 1/3 ≈ 0.333... ≈ 0x55555556 / 2^32
    localparam logic [31:0] RECIPROCAL = 32'h55555556;
    
    logic [63:0] product;
    assign product = dividend_i * RECIPROCAL;
    assign quotient_o = product[63:32];  // 取高 32 位

endmodule
```

#### 8.3.3 迭代除法器

```systemverilog
// 非恢復性除法（Non-restoring division）
module iterative_divider #(
    parameter int WIDTH = 32
) (
    input  logic               clk_i,
    input  logic               rst_ni,
    input  logic [WIDTH-1:0]   dividend_i,
    input  logic [WIDTH-1:0]   divisor_i,
    input  logic               start_i,
    output logic [WIDTH-1:0]   quotient_o,
    output logic [WIDTH-1:0]   remainder_o,
    output logic               valid_o,
    output logic               div_by_zero_o
);

    // 狀態機
    typedef enum logic [1:0] {
        IDLE,
        COMPUTE,
        DONE
    } state_e;
    
    state_e state_q, state_d;
    logic [WIDTH-1:0]   quotient_q, quotient_d;
    logic [2*WIDTH-1:0] remainder_q, remainder_d;
    logic [5:0]         counter_q, counter_d;
    
    always_comb begin
        state_d     = state_q;
        quotient_d  = quotient_q;
        remainder_d = remainder_q;
        counter_d   = counter_q;
        valid_o     = 1'b0;
        
        case (state_q)
            IDLE: begin
                if (start_i) begin
                    if (divisor_i == '0) begin
                        state_d = DONE;
                        div_by_zero_o = 1'b1;
                    end else begin
                        state_d     = COMPUTE;
                        remainder_d = {32'b0, dividend_i};
                        quotient_d  = '0;
                        counter_d   = WIDTH;
                    end
                end
            end
            
            COMPUTE: begin
                // 左移 remainder
                remainder_d = remainder_q << 1;
                
                // 減法並判斷
                if (remainder_d[2*WIDTH-1:WIDTH] >= divisor_i) begin
                    remainder_d[2*WIDTH-1:WIDTH] = remainder_d[2*WIDTH-1:WIDTH] - divisor_i;
                    quotient_d = (quotient_q << 1) | 1'b1;
                end else begin
                    quotient_d = quotient_q << 1;
                end
                
                counter_d = counter_q - 1'b1;
                
                if (counter_q == 1) begin
                    state_d = DONE;
                end
            end
            
            DONE: begin
                valid_o = 1'b1;
                if (start_i) begin
                    state_d = IDLE;
                end
            end
        endcase
    end
    
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            state_q     <= IDLE;
            quotient_q  <= '0;
            remainder_q <= '0;
            counter_q   <= '0;
        end else begin
            state_q     <= state_d;
            quotient_q  <= quotient_d;
            remainder_q <= remainder_d;
            counter_q   <= counter_d;
        end
    end
    
    assign quotient_o  = quotient_q;
    assign remainder_o = remainder_q[WIDTH-1:0];

endmodule
```

### 8.4 比較器優化

#### 8.4.1 減法比較

```systemverilog
// 比較可以通過減法實現
logic [31:0] a, b;
logic        a_gt_b, a_eq_b, a_lt_b;

// 使用減法結果判斷
logic [32:0] diff;
assign diff = {1'b0, a} - {1'b0, b};

assign a_gt_b = !diff[32] && |diff[31:0];  // 正數且非零
assign a_eq_b = ~|diff;                     // 全零
assign a_lt_b = diff[32];                   // 負數
```

#### 8.4.2 並行比較

```systemverilog
// 大位寬比較可以分解
module fast_comparator_64 (
    input  logic [63:0] a_i,
    input  logic [63:0] b_i,
    output logic        equal_o,
    output logic        greater_o
);

    // 分成 4 個 16-bit 比較，減少扇入
    logic [3:0] eq_part;
    logic [3:0] gt_part;
    
    genvar i;
    generate
        for (i = 0; i < 4; i++) begin : gen_compare
            assign eq_part[i] = (a_i[i*16+:16] == b_i[i*16+:16]);
            assign gt_part[i] = (a_i[i*16+:16] > b_i[i*16+:16]);
        end
    endgenerate
    
    // 最終結果
    assign equal_o = &eq_part;
    assign greater_o = gt_part[3] || 
                      (eq_part[3] && gt_part[2]) ||
                      (eq_part[3] && eq_part[2] && gt_part[1]) ||
                      (eq_part[3] && eq_part[2] && eq_part[1] && gt_part[0]);

endmodule
```

### 8.5 查找表（LUT）優化

#### 8.5.1 小型 LUT

```systemverilog
// ROM-based LUT 用於小型函數
module sin_lut (
    input  logic [7:0]  angle_i,   // 0-255 代表 0-360 度
    output logic [15:0] sin_o      // 定點數 sin 值
);

    // 256 個 sin 值查找表
    logic [15:0] lut [256];
    
    initial begin
        // 初始化 LUT（可由外部工具生成）
        lut[0]   = 16'h0000;  // sin(0)
        lut[1]   = 16'h0324;  // sin(1.4°)
        // ... 其餘值
        lut[255] = 16'hFCDC;  // sin(358.6°)
    end
    
    assign sin_o = lut[angle_i];

endmodule
```

#### 8.5.2 分段線性逼近（Piecewise Linear Approximation）

```systemverilog
// 【技巧】大函數可用分段線性逼近節省面積
module sqrt_approx (
    input  logic [15:0] x_i,
    output logic [7:0]  sqrt_o
);

    // 將輸入分成 16 段，每段用線性逼近
    logic [3:0] segment;
    logic [3:0] offset;
    
    assign segment = x_i[15:12];  // 高 4 位決定段
    assign offset  = x_i[11:8];   // 次高 4 位用於插值
    
    // 每段的基值和斜率（查表）
    logic [7:0] base [16];
    logic [7:0] slope [16];
    
    // sqrt(x) ≈ base[seg] + slope[seg] * offset
    assign sqrt_o = base[segment] + ((slope[segment] * offset) >> 4);

endmodule
```

### 8.6 資源共享

#### 8.6.1 運算器復用

```systemverilog
module resource_sharing (
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic [31:0] a_i,
    input  logic [31:0] b_i,
    input  logic [31:0] c_i,
    input  logic [1:0]  sel_i,  // 選擇運算
    output logic [31:0] result_o
);

    // ❌ 不好：多個運算器
    // logic [31:0] add_result = a_i + b_i;
    // logic [31:0] sub_result = a_i - b_i;
    // logic [31:0] and_result = a_i & b_i;
    
    // ✓ 好：共享運算器
    logic [31:0] op1, op2;
    logic [31:0] alu_result;
    
    // Multiplexer for operands
    always_comb begin
        case (sel_i)
            2'b00: begin
                op1 = a_i;
                op2 = b_i;
            end
            2'b01: begin
                op1 = a_i;
                op2 = ~b_i + 1'b1;  // 減法 = 加負數
            end
            2'b10: begin
                op1 = a_i;
                op2 = b_i;
            end
            default: begin
                op1 = '0;
                op2 = '0;
            end
        endcase
    end
    
    // 共享加法器
    assign alu_result = (sel_i == 2'b10) ? (op1 & op2) : (op1 + op2);
    
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            result_o <= '0;
        end else begin
            result_o <= alu_result;
        end
    end

endmodule
```

#### 8.6.2 時分複用（Time-Division Multiplexing）

```systemverilog
// 【技巧】一個乘法器處理多個通道
module tdm_multiplier #(
    parameter int NUM_CHANNELS = 4,
    parameter int DATA_WIDTH   = 16
) (
    input  logic                    clk_i,
    input  logic                    rst_ni,
    input  logic [DATA_WIDTH-1:0]   data_i [NUM_CHANNELS],
    input  logic [DATA_WIDTH-1:0]   coeff_i [NUM_CHANNELS],
    output logic [2*DATA_WIDTH-1:0] result_o [NUM_CHANNELS]
);

    // 單一乘法器
    logic [DATA_WIDTH-1:0]   mul_a, mul_b;
    logic [2*DATA_WIDTH-1:0] mul_result;
    
    // 通道選擇
    logic [1:0] channel_q;
    
    // 輪流處理各通道
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            channel_q <= '0;
        end else begin
            channel_q <= (channel_q == NUM_CHANNELS-1) ? '0 : channel_q + 1'b1;
        end
    end
    
    // Multiplexer
    assign mul_a = data_i[channel_q];
    assign mul_b = coeff_i[channel_q];
    
    // 共享乘法器
    assign mul_result = mul_a * mul_b;
    
    // 結果分配
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            foreach (result_o[i]) result_o[i] <= '0;
        end else begin
            result_o[channel_q] <= mul_result;
        end
    end

endmodule
```

### 8.7 位操作優化

#### 8.7.1 計數器優化

```systemverilog
// 【技巧】Gray code counter（降低功耗）
module gray_counter #(
    parameter int WIDTH = 8
) (
    input  logic              clk_i,
    input  logic              rst_ni,
    input  logic              enable_i,
    output logic [WIDTH-1:0]  gray_o,
    output logic [WIDTH-1:0]  binary_o
);

    logic [WIDTH-1:0] binary_q;
    
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            binary_q <= '0;
        end else if (enable_i) begin
            binary_q <= binary_q + 1'b1;
        end
    end
    
    // Binary to Gray conversion
    assign gray_o = binary_q ^ (binary_q >> 1);
    assign binary_o = binary_q;

endmodule
```

#### 8.7.2 Population Count（數 1 的個數）

```systemverilog
// 【技巧】Parallel population count
function automatic logic [5:0] popcount_32(input logic [31:0] data);
    logic [5:0] count;
    int i;
    count = '0;
    for (i = 0; i < 32; i++) begin
        count = count + data[i];
    end
    return count;
endfunction

// 更快的 tree 結構實現
module fast_popcount (
    input  logic [31:0] data_i,
    output logic [5:0]  count_o
);

    logic [15:0] stage1 [2];
    logic [7:0]  stage2 [2];
    logic [3:0]  stage3 [2];
    logic [1:0]  stage4 [2];
    
    // Stage 1: 每 2 位計數
    genvar i;
    generate
        for (i = 0; i < 16; i++) begin : gen_stage1
            assign stage1[i] = data_i[2*i] + data_i[2*i+1];
        end
    endgenerate
    
    // Stage 2: 每 4 位計數
    generate
        for (i = 0; i < 8; i++) begin : gen_stage2
            assign stage2[i] = stage1[2*i] + stage1[2*i+1];
        end
    endgenerate
    
    // Stage 3, 4... 依此類推
    // （完整實現略）
    
    assign count_o = /* 最終加總 */;

endmodule
```

#### 8.7.3 Leading Zero Count

```systemverilog
// 【重要】找出最高位 1 的位置（優先級編碼器）
module leading_zero_count (
    input  logic [31:0] data_i,
    output logic [5:0]  lzc_o,
    output logic        all_zero_o
);

    always_comb begin
        lzc_o = 6'd32;
        all_zero_o = 1'b1;
        
        for (int i = 31; i >= 0; i--) begin
            if (data_i[i]) begin
                lzc_o = 31 - i;
                all_zero_o = 1'b0;
                break;
            end
        end
    end

endmodule
```

### 8.8 定點數運算

#### 8.8.1 定點數乘法

```systemverilog
// Q格式定點數乘法：Qm.n × Qm.n = Q(2m).(2n)，需要調整
module fixed_point_multiply (
    input  logic signed [15:0] a_i,    // Q8.8 格式
    input  logic signed [15:0] b_i,    // Q8.8 格式
    output logic signed [15:0] prod_o  // Q8.8 格式
);

    logic signed [31:0] temp_prod;
    
    // 32-bit 乘積是 Q16.16
    assign temp_prod = a_i * b_i;
    
    // 取中間 16 位得到 Q8.8
    assign prod_o = temp_prod[23:8];
    
    // 或者四捨五入
    // assign prod_o = temp_prod[23:8] + temp_prod[7];

endmodule
```

#### 8.8.2 定點數除法

```systemverilog
// Q格式定點數除法
module fixed_point_divide (
    input  logic signed [15:0] dividend_i,  // Q8.8
    input  logic signed [15:0] divisor_i,   // Q8.8
    output logic signed [15:0] quotient_o   // Q8.8
);

    // 將被除數左移以保持精度
    logic signed [31:0] dividend_extended;
    logic signed [31:0] quotient_temp;
    
    assign dividend_extended = {dividend_i, 8'b0};  // 左移 8 位
    assign quotient_temp = dividend_extended / divisor_i;
    
    // 取低 16 位
    assign quotient_o = quotient_temp[15:0];

endmodule
```

### 8.9 時序優化技巧

#### 8.9.1 Retiming（重定時）

```systemverilog
// ❌ 時序差：長組合邏輯鏈
module bad_timing (
    input  logic clk_i,
    input  logic [31:0] a_i,
    output logic [31:0] result_o
);

    logic [31:0] temp1, temp2, temp3, result_q;
    
    // 長組合路徑
    assign temp1 = a_i * 2;
    assign temp2 = temp1 + 100;
    assign temp3 = temp2 << 3;
    
    always_ff @(posedge clk_i) begin
        result_q <= temp3;  // 關鍵路徑太長！
    end
    
    assign result_o = result_q;

endmodule

// ✓ 好：插入 pipeline 平衡時序
module good_timing (
    input  logic clk_i,
    input  logic [31:0] a_i,
    output logic [31:0] result_o
);

    logic [31:0] s1_q, s2_q, s3_q;
    
    // 分散運算到不同級
    always_ff @(posedge clk_i) begin
        s1_q <= a_i * 2;
        s2_q <= s1_q + 100;
        s3_q <= s2_q << 3;
    end
    
    assign result_o = s3_q;

endmodule
```

#### 8.9.2 Register Balancing

```systemverilog
// 【技巧】平衡 pipeline 各級延遲
// 使用工具自動 retiming，或手動調整邏輯分布
```

### 8.10 功耗優化

#### 8.10.1 Clock Gating

```systemverilog
// 【重要】時鐘門控減少動態功耗
module clock_gating_example (
    input  logic clk_i,
    input  logic enable_i,
    input  logic [31:0] data_i,
    output logic [31:0] data_o
);

    logic gated_clk;
    logic enable_q;
    
    // Latch enable signal（ICG - Integrated Clock Gating）
    always_latch begin
        if (!clk_i) begin
            enable_q = enable_i;
        end
    end
    
    // Gated clock
    assign gated_clk = clk_i & enable_q;
    
    // Use gated clock
    always_ff @(posedge gated_clk) begin
        data_o <= data_i;
    end

endmodule

// 【注意】實務上使用 library 提供的 ICG cell
// 不要手動實現 clock gating
```

#### 8.10.2 Operand Isolation

```systemverilog
// 【技巧】當運算器不使用時，隔離輸入避免翻轉
module operand_isolation (
    input  logic [31:0] a_i,
    input  logic [31:0] b_i,
    input  logic        enable_i,
    output logic [31:0] result_o
);

    logic [31:0] a_gated, b_gated;
    
    // 當 enable 為 0 時，固定輸入為 0，避免運算器翻轉
    assign a_gated = enable_i ? a_i : '0;
    assign b_gated = enable_i ? b_i : '0;
    
    assign result_o = a_gated * b_gated;

endmodule
```

### 8.11 優化技巧總結

| 技巧 | 適用場景 | 效果 |
|------|---------|------|
| 常數乘法優化 | 乘以 2^n 或 (2^n ± 1) | 節省乘法器 |
| CSA 加法器 | 多運算元加法 | 減少延遲 |
| 倒數乘法 | 除以常數 | 避免除法器 |
| Pipeline | 高吞吐量需求 | 提升頻率 |
| 資源共享 | 多個類似運算 | 減少面積 |
| LUT | 複雜函數 | 減少運算邏輯 |
| Gray code | 跨時鐘域計數器 | 降低亞穩態 |
| Clock gating | 條件性運算 | 降低功耗 |
| Operand isolation | 閒置運算器 | 降低功耗 |

---

## 9. 註解與文檔

### 9.1 註解原則

**【原則】註解應解釋「為什麼」而非「是什麼」**

```systemverilog
// ❌ 不好的註解：重複代碼內容
counter <= counter + 1;  // Increment counter

// ✓ 好的註解：解釋原因或意圖
counter <= counter + 1;  // Watchdog timer needs 100 cycles before timeout

// ✓ 好的註解：解釋複雜邏輯
// AXI4 spec requires WVALID to remain high until WREADY
// is asserted. We use this flag to track the handshake state.
assign wvalid_hold = wvalid_q && !wready_i;
```

### 9.2 模組文檔

```systemverilog
// ============================================================================
// Module: axi_dma_controller
// 
// Description:
//   Implements a multi-channel DMA controller with AXI4 master interface.
//   Supports the following features:
//   - Up to 16 independent DMA channels
//   - Scatter-gather descriptor chains
//   - Priority-based arbitration
//   - Burst optimization for sequential transfers
//
// Parameters:
//   NUM_CHANNELS : Number of DMA channels (1-16)
//   DATA_WIDTH   : AXI data bus width (32/64/128/256)
//   ADDR_WIDTH   : Address bus width (32/64)
//   MAX_BURST    : Maximum burst length (1-256)
//
// Interfaces:
//   AXI4 Master  : Memory access interface
//   APB Slave    : Configuration registers
//
// Authors: John Doe
// Date: 2024-01-15
// Version: 1.2
// ============================================================================
```

### 9.3 複雜邏輯說明

```systemverilog
/* Credit-based flow control implementation
 * 
 * Each output port maintains a credit counter that tracks available
 * buffer space in the downstream router. Credits are:
 * - Decremented when a flit is sent
 * - Incremented when receiving credit return packets
 * 
 * A transmission is allowed only when:
 * 1. credit_q > 0 (buffer space available)
 * 2. valid_i is high (data ready to send)
 * 3. !blocked (no backpressure from routing logic)
 */
always_comb begin
    tx_allowed = (credit_q > '0) && valid_i && !blocked;
end
```

### 9.4 TODO 與 FIXME

```systemverilog
// TODO(username): Add support for unaligned transfers
// FIXME(username): Race condition when enable changes during active transfer
// NOTE: This implementation assumes little-endian byte ordering
// HACK: Temporary workaround until tool bug is fixed (Issue #1234)
```

---

## 10. 檢查清單

### 10.1 代碼生成前檢查

在生成任何 RTL 代碼前，確認：

- [ ] 使用 4 格空格縮排
- [ ] 模組名稱符合命名規則（小寫+底線）
- [ ] 所有信號都有明確的方向後綴（_i, _o）或用途後綴（_q, _d）
- [ ] 參數使用大寫字母命名
- [ ] 時鐘信號命名為 `clk_*_i`
- [ ] 重置信號命名為 `rst_*ni` 或 `arst_*ni`

### 10.2 時序邏輯檢查

- [ ] 使用 `always_ff` 而非 `always`
- [ ] 使用非阻塞賦值 `<=`
- [ ] 所有觸發器在重置時有初始值
- [ ] 重置條件正確（同步或異步）

### 10.3 組合邏輯檢查

- [ ] 使用 `always_comb` 而非 `always @*`
- [ ] 使用阻塞賦值 `=`
- [ ] 所有輸出有預設值（避免 latch）
- [ ] 所有 `case` 語句有 `default`
- [ ] 所有條件分支完整（避免 latch）

### 10.4 綜合前檢查

- [ ] 無多重驅動
- [ ] 無 latch（非預期的）
- [ ] 無組合邏輯迴路
- [ ] 位寬匹配，無隱式截斷
- [ ] 無使用 `x` 或 `z` 值
- [ ] 無 clock gating（除非明確需要）
- [ ] 參數化正確，可重用
- [ ] **重複硬體結構使用 `generate` 而非 `for` 循環**
- [ ] **`for` 循環僅用於 testbench 或簡單初始化**
- [ ] **所有 `generate` 塊都有明確命名**

### 10.5 文檔檢查

- [ ] 模組頂部有完整描述
- [ ] 複雜邏輯有註解說明
- [ ] 參數有說明文檔
- [ ] Port 有必要的註解

---

## 附錄 A：常見錯誤範例

### A.1 Clock Domain Crossing (CDC)

```systemverilog
// ❌ 錯誤：直接傳遞信號跨時鐘域
logic sig_clk_a;
logic sig_clk_b;

always_ff @(posedge clk_a) sig_clk_a <= ...;
always_ff @(posedge clk_b) sig_clk_b <= sig_clk_a;  // 亞穩態風險！

// ✓ 正確：使用同步器
logic sig_clk_a;
logic sig_sync_1, sig_sync_2;

always_ff @(posedge clk_a) sig_clk_a <= ...;

// 雙級同步器
always_ff @(posedge clk_b) begin
    sig_sync_1 <= sig_clk_a;
    sig_sync_2 <= sig_sync_1;
end
```

### A.2 Reset 時序

```systemverilog
// ❌ 錯誤：異步重置未使用 or negedge
always_ff @(posedge clk_i) begin
    if (!rst_ni) begin  // 異步重置但沒在敏感度列表
        data_q <= '0;
    end
end

// ✓ 正確
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        data_q <= '0;
    end
end
```

### A.3 算術運算位寬

```systemverilog
// ❌ 錯誤：運算溢出
logic [7:0] a, b;
logic [7:0] sum;
assign sum = a + b;  // 結果可能溢出

// ✓ 正確：擴展位寬
logic [7:0] a, b;
logic [8:0] sum;
assign sum = {1'b0, a} + {1'b0, b};
```

---

## 附錄 B：參考資源

- IEEE 1800-2017 SystemVerilog LRM
- Google SystemVerilog Style Guide
- Cliff Cummings Papers (sunburst-design.com)
- lowRISC Style Guide

---

**版本**: 1.0  
**最後更新**: 2025-12-09  
**維護者**: Lucas
