# 有限狀態機（FSM）

主文件對應章節：`rtl_style.md` §5.4

## 三段式 FSM（推薦結構）

**第一段（時序）**：更新 state register
**第二段（組合）**：計算 next state
**第三段（組合）**：產生輸出

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

// ====================================================================
// 第一段：時序邏輯，更新狀態
// ====================================================================
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        state_q <= IDLE;
    end else begin
        state_q <= state_d;
    end
end

// ====================================================================
// 第二段：組合邏輯，計算下一狀態
// ====================================================================
always_comb begin
    state_d = state_q;          // Default: stay in current state

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

        default: state_d = IDLE;        // 強制：必須有 default
    endcase
end

// ====================================================================
// 第三段：組合邏輯，產生輸出
// ====================================================================
always_comb begin
    // Default outputs（避免 latch）
    fetch_en  = 1'b0;
    exec_en   = 1'b0;
    wb_en     = 1'b0;
    error_o   = 1'b0;

    case (state_q)
        IDLE:       /* nothing */;
        FETCH:      fetch_en = 1'b1;
        EXECUTE:    exec_en  = 1'b1;
        WRITE_BACK: wb_en    = 1'b1;
        ERROR:      error_o  = 1'b1;
        default:    /* nothing */;
    endcase
end
```

## 編碼方式選擇

| 編碼 | 適用場景 | 範例 |
|------|---------|------|
| Binary | 狀態多、空間敏感 | `IDLE=2'd0, ACTIVE=2'd1` |
| One-hot | 狀態少（≤8）、要求高速 | `IDLE=4'b0001, ACTIVE=4'b0010` |
| Gray | 跨時鐘域 | `S0=2'b00, S1=2'b01, S2=2'b11, S3=2'b10` |

讓綜合工具用屬性挑選：
```systemverilog
(* fsm_encoding = "one_hot" *) state_e state_q;
```

## 強制規則

- 必須使用 `typedef enum` 定義狀態，不要用 raw `logic [N:0]`
- `case (state_q)` 必須有 `default` 分支
- 第二段的 `state_d` 必須有預設值（`state_d = state_q;`）
- 第三段所有輸出必須有預設值
- 重置時 `state_q <= IDLE`

## 反模式

```systemverilog
// ❌ 一段式 FSM（混合時序與組合）
always_ff @(posedge clk_i) begin
    case (state_q)
        IDLE: if (start_i) begin
            state_q <= ACTIVE;
            output_o <= 1'b1;       // 輸出邏輯也在時序裡，難維護
        end
    endcase
end

// ❌ 缺少 default
always_comb begin
    case (state_q)
        IDLE:   state_d = ACTIVE;
        ACTIVE: state_d = DONE;
        // 沒有 default，未列出狀態會產生 latch
    endcase
end

// ❌ 第三段輸出沒有預設值
always_comb begin
    case (state_q)
        FETCH: fetch_en = 1'b1;
        // 其他狀態 fetch_en 沒賦值 → latch
    endcase
end
```

## 直接複製模板

`templates/fsm.sv`
