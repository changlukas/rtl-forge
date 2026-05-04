# 運算優化技巧

主文件對應章節：`rtl_style.md` §8

## 總覽

| 技巧 | 適用場景 | 效果 |
|------|---------|------|
| 常數乘法用移位 | 乘以 2^n 或 (2^n ± 1) | 節省乘法器 |
| CSA 加法器 | 多運算元加法（≥3） | 減少延遲 |
| 倒數乘法 | 除以常數 | 避免除法器 |
| Pipeline | 高吞吐量需求 | 提升頻率 |
| 資源共享 | 多個類似運算 | 減少面積 |
| LUT | 複雜函數 | 減少運算邏輯 |
| Gray code | 跨時鐘域計數器 | 降低亞穩態 |
| Clock gating | 條件性運算 | 降低功耗 |
| Operand isolation | 閒置運算器 | 降低功耗 |

## 常數乘法分解

```systemverilog
// 乘以 2 的冪次：用移位
assign result = data << 3;          // data * 8

// 乘以 (2^n ± 1)：用移位 + 加減
// data * 3  = (data << 1) + data
// data * 5  = (data << 2) + data
// data * 7  = (data << 3) - data
// data * 9  = (data << 3) + data
// data * 15 = (data << 4) - data
// data * 17 = (data << 4) + data
// data * 31 = (data << 5) - data

assign mul3 = (data << 1) + data;
assign mul7 = (data << 3) - data;
```

## CSA（Carry-Save Adder）

多運算元加法（如 `a + b + c + d`）用 3:2 compressor 樹減少延遲：

```systemverilog
// 第一層：a + b + c → sum + carry
logic [31:0] s1_sum, s1_carry;
assign s1_sum   = a_i ^ b_i ^ c_i;
assign s1_carry = ((a_i & b_i) | (b_i & c_i) | (c_i & a_i)) << 1;

// 第二層：sum + carry + d
logic [31:0] s2_sum, s2_carry;
assign s2_sum   = s1_sum ^ s1_carry ^ d_i;
assign s2_carry = ((s1_sum & s1_carry) | (s1_carry & d_i) | (d_i & s1_sum)) << 1;

// 最終：carry-propagate adder
assign sum_o = s2_sum + s2_carry;
```

## 飽和加法

```systemverilog
logic [WIDTH:0] temp_sum;       // 多 1 bit 偵測溢位
assign temp_sum = {1'b0, a_i} + {1'b0, b_i};
assign sum_o   = temp_sum[WIDTH] ? {WIDTH{1'b1}} : temp_sum[WIDTH-1:0];
```

## 除法優化

```systemverilog
// 除以 2 的冪次：用移位
assign result = data >>> 4;     // 有號數 / 16
assign result = data >>  4;     // 無號數 / 16

// 除以常數 = 乘以倒數（定點數）
// x / 3 ≈ (x * 0x55555556) >> 32
localparam logic [31:0] RECIPROCAL = 32'h55555556;
logic [63:0] product;
assign product    = dividend_i * RECIPROCAL;
assign quotient_o = product[63:32];
```

## Leading Zero Count（LZC）

```systemverilog
// 找最高位 1 的位置
always_comb begin
    lzc_o      = 6'd32;
    all_zero_o = 1'b1;
    for (int i = 31; i >= 0; i--) begin
        if (data_i[i]) begin
            lzc_o      = 31 - i;
            all_zero_o = 1'b0;
            break;
        end
    end
end
```

## Population Count（樹狀結構）

```systemverilog
// 32 bit popcount，用 tree 而非 ripple
logic [1:0] s1 [16];
logic [2:0] s2 [8];
logic [3:0] s3 [4];
logic [4:0] s4 [2];

genvar i;
generate
    for (i = 0; i < 16; i++) begin : gen_l1
        assign s1[i] = data_i[2*i] + data_i[2*i+1];
    end
    for (i = 0; i < 8; i++) begin : gen_l2
        assign s2[i] = s1[2*i] + s1[2*i+1];
    end
    for (i = 0; i < 4; i++) begin : gen_l3
        assign s3[i] = s2[2*i] + s2[2*i+1];
    end
    for (i = 0; i < 2; i++) begin : gen_l4
        assign s4[i] = s3[2*i] + s3[2*i+1];
    end
endgenerate
assign count_o = s4[0] + s4[1];
```

## Gray Code Counter（CDC 友好）

```systemverilog
logic [WIDTH-1:0] binary_q;

always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) binary_q <= '0;
    else if (enable_i) binary_q <= binary_q + 1'b1;
end

assign gray_o   = binary_q ^ (binary_q >> 1);   // Binary → Gray
assign binary_o = binary_q;
```

## Pipeline 平衡時序（Retiming）

```systemverilog
// ❌ 長組合路徑
always_ff @(posedge clk_i) begin
    result_q <= ((a_i * 2) + 100) << 3;     // 一拍做太多
end

// ✓ 切成多級
always_ff @(posedge clk_i) begin
    s1_q <= a_i * 2;
    s2_q <= s1_q + 100;
    s3_q <= s2_q << 3;
end
```

## Operand Isolation（功耗）

```systemverilog
// 閒置時固定輸入為 0，避免運算器內部翻轉
assign a_gated = enable_i ? a_i : '0;
assign b_gated = enable_i ? b_i : '0;
assign result  = a_gated * b_gated;
```

## 資源共享 ALU

```systemverilog
// 多個運算共享一個加法器
logic [31:0] op1, op2;
always_comb begin
    case (sel_i)
        2'b00: begin op1 = a_i; op2 = b_i;             end  // a + b
        2'b01: begin op1 = a_i; op2 = ~b_i + 1'b1;     end  // a - b（補數）
        default: begin op1 = '0; op2 = '0;             end
    endcase
end
assign alu_result = (sel_i == 2'b10) ? (op1 & op2) : (op1 + op2);
```

## 定點數乘法（Q 格式）

```systemverilog
// Q8.8 × Q8.8 → Q16.16，需取中間 16 bit 還原為 Q8.8
logic signed [31:0] temp_prod;
assign temp_prod = a_i * b_i;
assign prod_o    = temp_prod[23:8];     // 截取
// 或四捨五入：assign prod_o = temp_prod[23:8] + temp_prod[7];
```

## 工具相關注意

- ASIC 工具會自動推斷 Booth / Wallace tree
- FPGA 工具會自動把乘法 map 到 DSP block
- **不要手動實現 clock gating** — 用 library 的 ICG cell
- 讓綜合工具做 retiming，手動切 pipeline 是第二招
