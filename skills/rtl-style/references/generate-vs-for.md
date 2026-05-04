# Generate vs For 循環

主文件對應章節：`rtl_style.md` §5.5

## 鐵則

| 用途 | 用法 |
|------|------|
| 創建並行硬體實例 | **`generate`** |
| 樹狀結構（adder tree, XOR tree） | **`generate`** |
| 重複的暫存器/邏輯陣列 | **`generate`** |
| 條件性硬體生成 | **`generate if`** |
| Testbench 測試迭代 | `for` |
| `initial` 區塊初始化 | `for` |
| Function 內簡單累加 | `for` (謹慎) |

## 對照表

| 特性 | `generate` | `for` |
|------|-----------|-------|
| 展開時機 | 編譯時 (elaboration) | 運行時 |
| 產生結果 | 並行硬體實例 | 串聯邏輯或迭代 |
| 可綜合性 | ✓ 完全可綜合 | ⚠️ 僅部分可綜合 |
| 時序影響 | 並行，無額外延遲 | 可能產生長組合路徑 |

## 正確：generate 創建並行實例

```systemverilog
module parallel_adders #(
    parameter int N  = 8,
    parameter int DW = 32
) (
    input  logic [DW-1:0] a_i [N],
    input  logic [DW-1:0] b_i [N],
    output logic [DW-1:0] sum_o [N]
);
    genvar i;
    generate
        for (i = 0; i < N; i++) begin : gen_adders
            assign sum_o[i] = a_i[i] + b_i[i];
        end
    endgenerate
endmodule
```

## 正確：generate 創建並行 FF 陣列

```systemverilog
genvar i;
generate
    for (i = 0; i < 8; i++) begin : gen_regs
        always_ff @(posedge clk_i or negedge rst_ni) begin
            if (!rst_ni) data_o[i] <= '0;
            else         data_o[i] <= data_i[i];
        end
    end
endgenerate
```

## 正確：generate 建立加法器樹

```systemverilog
// 16 → 8 → 4 → 2 → 1，並行 log2(N) 級
logic [8:0]  level1 [8];
logic [9:0]  level2 [4];
logic [10:0] level3 [2];

genvar i;
generate
    for (i = 0; i < 8; i++) begin : gen_l1
        assign level1[i] = {1'b0, data_i[2*i]} + {1'b0, data_i[2*i+1]};
    end
    for (i = 0; i < 4; i++) begin : gen_l2
        assign level2[i] = {1'b0, level1[2*i]} + {1'b0, level1[2*i+1]};
    end
    for (i = 0; i < 2; i++) begin : gen_l3
        assign level3[i] = {1'b0, level2[2*i]} + {1'b0, level2[2*i+1]};
    end
endgenerate
assign sum_o = {1'b0, level3[0]} + {1'b0, level3[1]};
```

## 正確：條件 generate

```systemverilog
generate
    if (USE_PIPELINE) begin : gen_pipelined
        always_ff @(posedge clk_i) data_o <= data_i;
    end else begin : gen_combinational
        assign data_o = data_i;
    end
endgenerate
```

## 錯誤：for 在 always 中產生硬體

```systemverilog
// ❌ 錯誤：可能產生意外的共享 counter
integer i;
always_ff @(posedge clk_i) begin
    for (i = 0; i < 8; i++) begin
        data_o[i] <= data_i[i];
    end
end

// ❌ 錯誤：8 級串聯加法（時序差）
always_comb begin
    sum = '0;
    for (i = 0; i < 8; i++) begin
        sum = sum + data[i];
    end
end
```

## 錯誤：for 用整數比較選擇

```systemverilog
// ❌ 錯誤
always_comb begin
    data_o = '0;
    for (i = 0; i < 8; i++) begin
        if (i == sel_i) data_o = data_i[i];
    end
end

// ✓ 正確 1：直接索引
assign data_o = data_i[sel_i];

// ✓ 正確 2：case
always_comb begin
    case (sel_i)
        3'd0: data_o = data_i[0];
        3'd1: data_o = data_i[1];
        // ...
        default: data_o = '0;
    endcase
end
```

## Generate 命名規則

```systemverilog
// 強制：generate 塊必須命名
genvar i;
generate
    for (i = 0; i < N; i++) begin : gen_units    // <- 必須命名
        processing_unit u_unit ( ... );
    end
endgenerate

// 條件 generate 所有分支也要命名
generate
    if (COND) begin : gen_path_a
        // ...
    end else begin : gen_path_b
        // ...
    end
endgenerate
```

## 嵌套 Generate

```systemverilog
// 2D mesh
genvar row, col;
generate
    for (row = 0; row < ROWS; row++) begin : gen_rows
        for (col = 0; col < COLS; col++) begin : gen_cols
            router #(
                .X_COORD (col),
                .Y_COORD (row)
            ) u_router ( ... );
        end
    end
endgenerate
// 嵌套不超過 3 層
```
