# 禁止使用的寫法

主文件對應章節：`rtl_style.md` §7

## 1. 混合阻塞與非阻塞賦值

```systemverilog
// ❌ 嚴重錯誤
always_ff @(posedge clk_i) begin
    a <= b;        // 非阻塞
    c = a + 1;     // 阻塞 — 行為不可預測
end

// ✓ 時序邏輯只用 <=
always_ff @(posedge clk_i) begin
    a <= b;
    c <= a + 1'b1;
end

// ✓ 組合邏輯只用 =
always_comb begin
    temp   = a + b;
    result = temp * c;
end
```

## 2. 多重驅動

```systemverilog
// ❌ 兩個 always 驅動同一信號
always_ff @(posedge clk_i) data_q <= data_i;
always_comb               data_q  = other_value;   // 衝突！

// ✓ 一處驅動
always_comb begin
    data_d = condition ? data_i : other_value;
end
always_ff @(posedge clk_i) data_q <= data_d;
```

## 3. 不完整的敏感度列表

```systemverilog
// ❌ always @ 容易漏列敏感信號
always @(a) result = a + b + c;     // 缺 b 和 c

// ✓ 永遠用 always_comb（自動推斷）
always_comb result = a + b + c;
```

## 4. Latch 產生（最常見錯誤）

```systemverilog
// ❌ case 不完整 → out 變 latch
always_comb begin
    case (sel)
        2'b00: out = a;
        2'b01: out = b;
        // 缺 2'b10, 2'b11
    endcase
end

// ✓ 加 default
always_comb begin
    case (sel)
        2'b00:   out = a;
        2'b01:   out = b;
        2'b10:   out = c;
        default: out = '0;
    endcase
end

// ✓ 或全域預設
always_comb begin
    out = '0;       // default
    case (sel)
        2'b00: out = a;
        2'b01: out = b;
    endcase
end

// ❌ if 沒有 else
always_comb begin
    if (en) out = data;     // !en 時 out 變 latch
end

// ✓
always_comb begin
    out = '0;
    if (en) out = data;
end
```

## 5. 位寬不匹配（隱式截斷）

```systemverilog
// ❌ 隱式截斷
logic [7:0]  byte_data;
logic [15:0] word_data;
assign byte_data = word_data;       // 高位被丟棄

// ✓ 明確截斷
assign byte_data = word_data[7:0];

// ✓ 明確擴展
assign word_data = {8'b0, byte_data};
```

## 6. 在可綜合代碼用 `x` 或 `z`

```systemverilog
// ❌
assign data = 4'bxxxx;          // 綜合行為未定義

// ✓
assign data = 4'b0000;

// 注意：x 只能用在 testbench
initial data = 4'bxxxx;         // testbench OK
```

## 7. For 循環濫用（產生意外硬體）

```systemverilog
// ❌ 在 always 中用 for
integer i;
always_ff @(posedge clk_i) begin
    for (i = 0; i < 16; i++) data_o[i] <= data_i[i];    // 共享 counter 風險
end

// ❌ 串聯邏輯
always_comb begin
    sum = '0;
    for (i = 0; i < 16; i++) sum = sum + data[i];       // 16 級串聯
end

// ✓ 用 generate
genvar i;
generate
    for (i = 0; i < 16; i++) begin : gen_regs
        always_ff @(posedge clk_i) data_o[i] <= data_i[i];
    end
endgenerate
```

詳見 `references/generate-vs-for.md`。

## 8. 手動 Clock Gating

```systemverilog
// ❌ 危險：手動 AND clock
assign gated_clk = clk_i & enable;
always_ff @(posedge gated_clk) data_q <= data_d;

// ❌ 用信號當 clock
always_ff @(posedge data_valid) counter <= counter + 1;

// ✓ 用 enable 信號
always_ff @(posedge clk_i) begin
    if (enable) counter_q <= counter_q + 1'b1;
end
```

需要 clock gating 時，用 library 提供的 ICG cell（不要手動實現）。

## 9. 異步重置忘記放敏感度

```systemverilog
// ❌ 異步重置但沒在敏感度列表
always_ff @(posedge clk_i) begin
    if (!rst_ni) data_q <= '0;       // 變成同步重置（語意錯）
    else         data_q <= data_d;
end

// ✓
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) data_q <= '0;
    else         data_q <= data_d;
end
```

## 10. CDC 直接連接

```systemverilog
// ❌ 跨時鐘域直接傳遞 → 亞穩態
always_ff @(posedge clk_a) sig_a <= ...;
always_ff @(posedge clk_b) sig_b <= sig_a;      // 危險

// ✓ 雙級同步器
logic sync_1, sync_2;
always_ff @(posedge clk_b) begin
    sync_1 <= sig_a;
    sync_2 <= sync_1;
end
// 使用 sync_2，不能用 sync_1
```

## 11. 算術運算不擴展位寬

```systemverilog
// ❌ 結果可能溢位
logic [7:0] a, b, sum;
assign sum = a + b;         // 溢位被截斷

// ✓ 擴展
logic [7:0] a, b;
logic [8:0] sum;
assign sum = {1'b0, a} + {1'b0, b};
```

## 12. `always` 而非 `always_ff` / `always_comb`

```systemverilog
// ❌ 不明確（時序？組合？）
always @(posedge clk_i) data_q <= data_d;
always @* result = a + b;

// ✓ 明確
always_ff  @(posedge clk_i) data_q <= data_d;
always_comb result = a + b;
```
