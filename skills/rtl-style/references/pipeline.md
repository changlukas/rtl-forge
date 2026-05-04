# Pipeline 撰寫風格

主文件對應章節：`rtl_style.md` §5.6

## 核心原則

1. **資料路徑與控制路徑分離**
2. **每級用 `s<N>_<signal>_q` 命名**
3. **valid 不能依賴 ready**（避免組合迴路）
4. **stall 時保持原值，flush 時清 valid**
5. **每級之間只有暫存器，不能有跨級組合邏輯**

## 命名慣例

```systemverilog
// Stage 1 → Stage 2
logic [31:0] s1_data_q;     // Stage 1 registered (current value)
logic [31:0] s1_data_d;     // Stage 1 next value (combinational)
logic        s1_valid_q;
logic [31:0] s2_data_q;
logic        s2_valid_q;

// 或功能性命名
logic [31:0] fetch_data_q;
logic [31:0] decode_data_q;
logic [31:0] execute_data_q;
```

## 簡單 Pipeline（無背壓）

```systemverilog
// Stage 1
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        s1_data_q  <= '0;
        s1_valid_q <= 1'b0;
    end else begin
        s1_data_q  <= data_i;
        s1_valid_q <= valid_i;
    end
end

// Stage 2 combinational + register
logic [31:0] s2_data_d;
always_comb begin
    s2_data_d = s1_data_q * 2 + 1;
end

always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        s2_data_q  <= '0;
        s2_valid_q <= 1'b0;
    end else begin
        s2_data_q  <= s2_data_d;
        s2_valid_q <= s1_valid_q;
    end
end

assign result_o = s2_data_q;
assign valid_o  = s2_valid_q;
```

## 帶背壓的 Pipeline（valid-ready 握手）

```systemverilog
// Stage 1
logic s1_ready;
assign s1_ready = !s1_valid_q || s2_ready;     // 空 OR 下級可收
assign ready_o  = s1_ready;

always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        s1_data_q  <= '0;
        s1_valid_q <= 1'b0;
    end else if (s1_ready) begin
        s1_data_q  <= data_i;
        s1_valid_q <= valid_i;
    end
    // else: stall, keep current value
end

// Stage 2
logic s2_ready;
assign s2_ready = !s2_valid_q || ready_i;

always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        s2_data_q  <= '0;
        s2_valid_q <= 1'b0;
    end else if (s2_ready) begin
        s2_data_q  <= s2_data_d;
        s2_valid_q <= s1_valid_q;
    end
end

assign data_o  = s2_data_q;
assign valid_o = s2_valid_q;
```

## Valid-Ready 協定規則

1. valid 一旦拉高，必須保持到 ready 為高（握手完成）
2. ready 可以隨時變化
3. 資料在 `valid && ready` 那一拍傳輸
4. **valid 不能依賴 ready**（避免組合迴路）

```systemverilog
// ✓ valid 獨立於 ready
always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
        valid_q <= 1'b0;
    end else if (condition) begin
        valid_q <= 1'b1;
        data_q  <= new_data;
    end else if (valid_q && ready_i) begin
        valid_q <= 1'b0;        // 握手完成才清
    end
end

// ❌ 組合迴路
assign valid_o = ready_i && some_condition;
```

## Stall 與 Flush

```systemverilog
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        stage_data_q  <= '0;
        stage_valid_q <= 1'b0;
    end else if (flush_i) begin
        // Flush：清 valid 變成 bubble，資料可保留也可清
        stage_valid_q <= 1'b0;
    end else if (!stall_i) begin
        // Normal：推進 pipeline
        stage_data_q  <= prev_data_q;
        stage_valid_q <= prev_valid_q;
    end
    // else: stall, keep current value (data + valid)
end
```

## Bubble 插入

```systemverilog
always_ff @(posedge clk_i) begin
    s1_data_q  <= data_i;
    s1_valid_q <= valid_i && !insert_bubble_i;     // 強制 valid=0 = bubble
end
// Bubble 會自動向後傳播，不影響後續邏輯
```

## Skid Buffer（打破 ready 組合路徑）

```systemverilog
logic [W-1:0] data_q, skid_data_q;
logic         valid_q, skid_valid_q;

always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        data_q       <= '0;
        valid_q      <= 1'b0;
        skid_data_q  <= '0;
        skid_valid_q <= 1'b0;
    end else begin
        // 主路徑
        if (ready_i || !valid_q) begin
            data_q  <= data_i;
            valid_q <= valid_i;
        end
        // Skid：output stall 時暫存
        if (valid_i && valid_q && !ready_i) begin
            skid_data_q  <= data_i;
            skid_valid_q <= 1'b1;
        end else if (ready_i) begin
            skid_valid_q <= 1'b0;
        end
    end
end

assign data_o  = skid_valid_q ? skid_data_q  : data_q;
assign valid_o = skid_valid_q ? skid_valid_q : valid_q;
assign ready_o = !skid_valid_q;
```

## 完整模板

直接複製 `templates/pipeline.sv`。

## 設計檢查清單

- [ ] 每級都有 `_q` 暫存器
- [ ] valid 跟著資料一起傳播
- [ ] 有背壓時 ready 邏輯正確
- [ ] valid 不依賴 ready
- [ ] stall 時資料不丟失
- [ ] flush 時清 valid（保留資料）
- [ ] 沒有跨 stage 的組合路徑
- [ ] 各 stage 之間時序滿足
- [ ] 資料相依性（data hazard）正確處理
- [ ] 參數化時考慮邊界（NUM_STAGES = 0 / 1）

## 常見錯誤

```systemverilog
// ❌ valid 依賴 ready（組合迴路）
assign valid_o = ready_i && internal_valid;

// ❌ 跨 stage 組合運算
assign s2_result = s1_data_q + s2_data_q;   // 直接混用兩級

// ❌ stall 時清資料
if (!stall_i) data_q <= data_i;
else          data_q <= '0;                  // stall 應保持原值！

// ❌ flush 只清資料不清 valid
if (flush_i) data_q <= '0;                   // valid 沒清，bubble 失效

// ❌ 參數化未處理 NUM_STAGES = 0
assign output = stage_q[NUM_STAGES-1];       // 0-1 = -1，越界
```
