# 標準匯流排介面（AXI/APB/AHB）

主文件對應章節：`rtl_style.md` §3.3

## 強制規則

- 標準匯流排（AXI4/AXI-Lite/APB/AHB/PCIe/NoC...）必須使用獨立的 header file
- 用 `` `define `` 集中所有位寬與常數
- Header 命名：`<interface_name>_if.svh`
- 路徑：`include/<interface>_if.svh`

## 為何使用 `.svh` 集中管理

1. 修改位寬只需改一處
2. 確保所有使用該介面的模組位寬一致
3. 用有意義的常數名稱（如 `AXI4_RESP_OKAY`）取代魔術數字
4. 跨專案重用

## 命名慣例

```systemverilog
// 介面前綴 + 用途 + WIDTH/常數
`define AXI4_ADDR_WIDTH     32          // AXI4 介面
`define APB_DATA_WIDTH      32          // APB 介面
`define NOC_FLIT_WIDTH      128         // NoC 介面
`define PCIE_TLP_WIDTH      256         // PCIe 介面

// 常數定義：介面名稱 + 類型 + 值
`define AXI4_BURST_INCR     2'b01       // AXI4 burst type
`define AXI4_RESP_OKAY      2'b00       // AXI4 response
`define APB_RESP_ERROR      1'b1        // APB response
```

## 標準骨架

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

// 各 channel 的衍生 widths（指向同一個 source）
`define AXI4_AW_ADDR_WIDTH  `AXI4_ADDR_WIDTH
`define AXI4_AW_LEN_WIDTH   `AXI4_LEN_WIDTH
// ...

// 常數編碼
`define AXI4_BURST_FIXED    2'b00
`define AXI4_BURST_INCR     2'b01
`define AXI4_BURST_WRAP     2'b10

`define AXI4_RESP_OKAY      2'b00
`define AXI4_RESP_EXOKAY    2'b01
`define AXI4_RESP_SLVERR    2'b10
`define AXI4_RESP_DECERR    2'b11

`endif // AXI4_IF_SVH
```

完整 AXI4 範本見 `templates/axi4_if.svh`。

## 在模組中使用

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

    // 使用定義的常數
    always_comb begin
        axi_awsize_o  = `AXI4_SIZE_8B;
        axi_awburst_o = `AXI4_BURST_INCR;
        axi_awlen_o   = 8'd15;
    end

    // 使用定義的 response 類型檢查
    case (axi_bresp_i)
        `AXI4_RESP_OKAY,
        `AXI4_RESP_EXOKAY: error_o <= 1'b0;
        `AXI4_RESP_SLVERR,
        `AXI4_RESP_DECERR: error_o <= 1'b1;
        default:           error_o <= 1'b1;
    endcase

endmodule
```

## APB 介面範例

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

## 訊號命名（AXI 範例）

| 方向 | Channel | 信號 | 後綴 |
|------|---------|------|------|
| Master out | AW | `axi_awaddr_o`, `axi_awvalid_o` | `_o` |
| Master in | AW | `axi_awready_i` | `_i` |
| Master out | W | `axi_wdata_o`, `axi_wvalid_o`, `axi_wlast_o` | `_o` |
| Master in | W | `axi_wready_i` | `_i` |
| Master in | B | `axi_bresp_i`, `axi_bvalid_i` | `_i` |
| Master out | B | `axi_bready_o` | `_o` |
