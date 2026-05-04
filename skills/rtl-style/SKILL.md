---
name: rtl-style
description: SystemVerilog/Verilog RTL coding style guide and templates. Use when writing, generating, or modifying SystemVerilog/Verilog RTL code, including modules, always_ff/always_comb blocks, FSM, pipeline, AXI/APB interfaces, generate blocks. Enforces naming conventions (_i/_o/_q/_d/_n suffixes), forbids common pitfalls (latch generation, blocking/non-blocking mix, for-loop hardware abuse), and provides ready-to-copy module/FSM/pipeline/AXI4 templates.
---

# SystemVerilog RTL Style Guide

本 skill 定義 SystemVerilog/Verilog RTL 的編碼標準。生成任何 RTL 代碼前必須遵循。

完整規範主文件：`E:\03_Learning\rtl-forge\rtl_style.md`（v1.0，維護者 Lucas）

---

## 強制規則（核心摘要 — 必須記住）

### 格式
- **4 格空格縮排**，禁止使用 Tab
- 每行 ≤ 100 字元
- 運算子前後、逗號後必須有空格

### 命名後綴（最常違反項）
| 後綴 | 用途 | 範例 |
|------|------|------|
| `_i` | input port | `data_i`, `valid_i` |
| `_o` | output port | `result_o`, `valid_o` |
| `_q` | registered (FF output) | `state_q`, `counter_q` |
| `_d` | combinational input to FF | `state_d`, `counter_d` |
| `_n` | active-low | `rst_ni`, `cs_n`, `we_n` |
| `_e` | enum type | `state_e` |
| `_t` | struct/typedef | `axi_req_t` |

- Module / signal：小寫 + 底線（`axi_dma_controller`、`fetch_done`）
- Parameter / localparam / `define：全大寫 + 底線（`ADDR_WIDTH`、`AXI4_RESP_OKAY`）
- Pipeline stage：`s<N>_<signal>_q`（如 `s1_data_q`、`s2_valid_q`）

### 時序邏輯（FF）
```systemverilog
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        data_q <= '0;       // 重置必須有初始值
        state_q <= IDLE;
    end else begin
        data_q <= data_d;   // 必須用非阻塞 <=
        state_q <= state_d;
    end
end
```

### 組合邏輯
```systemverilog
always_comb begin
    out = default_val;       // 所有輸出必須有預設值
    state_d = state_q;       // 預設保持當前狀態
    case (sel)
        2'b00:   out = a;
        2'b01:   out = b;
        default: out = c;    // case 必須有 default（避免 latch）
    endcase
end
```

### 重複硬體：強制 `generate`，禁止 `for`
```systemverilog
// ✓ 正確
genvar i;
generate
    for (i = 0; i < N; i++) begin : gen_units
        adder u_adder ( ... );  // 並行硬體實例
    end
endgenerate

// ❌ 錯誤：在 always 塊中用 for 產生硬體
always_comb begin
    for (i = 0; i < N; i++) sum = sum + data[i];  // 串聯邏輯
end
```
`for` 循環**僅**可用於 testbench / initial 初始化 / function 內簡單累加。

### Pipeline 鐵則
- 每級用 `s<N>_<signal>_q` 命名
- valid **不能**依賴 ready（避免組合迴路）
- Stall 時保持原值，flush 時清 valid 但保留資料
- 詳見 `references/pipeline.md`

### 標準匯流排
AXI/APB/AHB 介面定義放獨立 `.svh` 檔，用 `` `define `` 集中位寬與常數。詳見 `references/interfaces.md`。

---

## 漸進式子檔載入

**只在需要時讀取**對應子檔。不要一次載入所有檔案。

| 任務情境 | 載入檔案 |
|---------|---------|
| 撰寫新模組（外殼/Port） | `references/module-structure.md` + `templates/module.sv` |
| 命名規則細節 | `references/naming.md` |
| 寫狀態機 | `references/fsm.md` + `templates/fsm.sv` |
| 寫 Pipeline（含背壓） | `references/pipeline.md` + `templates/pipeline.sv` |
| 處理重複硬體陣列 | `references/generate-vs-for.md` |
| AXI / APB / AHB 介面 | `references/interfaces.md` + `templates/axi4_if.svh` |
| 運算優化（CSA、移位、LZC、popcount） | `references/optimization.md` |
| Debug 違規或檢查 | `references/forbidden-patterns.md` |
| 完成代碼前最終檢查 | `checklists/pre-synthesis.md` |

---

## 工作流程（生成 RTL 時）

1. **先想清楚輸入/輸出/處理**：列出 Port 與資料流方向
2. **複製對應 template**：從 `templates/` 取最接近的骨架
3. **套用命名後綴**：`_i`/`_o`/`_q`/`_d`/`_n`
4. **時序與組合分離**：`always_ff` 只放暫存器，`always_comb` 只放組合
5. **加 default**：所有 `case` 與所有組合輸出
6. **檢查清單**：完成後對照 `checklists/pre-synthesis.md`
