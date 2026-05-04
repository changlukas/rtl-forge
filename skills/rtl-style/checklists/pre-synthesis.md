# 綜合前檢查清單

主文件對應章節：`rtl_style.md` §10

完成 RTL 代碼後，逐項對照下列五類檢查。

## 1. 代碼風格

- [ ] 使用 4 格空格縮排（無 Tab）
- [ ] 模組名稱小寫 + 底線
- [ ] 信號方向後綴：`_i` / `_o`
- [ ] 暫存器命名：`_q` / `_d`
- [ ] Active-low 信號加 `_n` 後綴
- [ ] 時鐘命名 `clk_*_i`，重置命名 `rst_*ni` 或 `arst_*ni`
- [ ] 常數 / 參數使用全大寫 + 底線
- [ ] enum 用 `_e`，struct 用 `_t`，union 用 `_u`
- [ ] Pipeline stage 用 `s<N>_` 前綴

## 2. 時序邏輯

- [ ] 使用 `always_ff`（不用 `always @(posedge clk)`）
- [ ] 使用非阻塞賦值 `<=`
- [ ] 所有暫存器在重置時有初始值
- [ ] 重置條件正確（同步：`@(posedge clk_i)`；異步：`@(posedge clk_i or negedge rst_ni)`）
- [ ] 異步重置 reset 信號出現在敏感度列表

## 3. 組合邏輯

- [ ] 使用 `always_comb`（不用 `always @*` 或 `always @(...)`）
- [ ] 使用阻塞賦值 `=`
- [ ] 所有輸出有預設值（避免 latch）
- [ ] 所有 `case` 有 `default`
- [ ] 所有 `if` 有對應 `else`，或開頭設預設值

## 4. 綜合性與正確性

- [ ] **無多重驅動**（同一信號只在一處被驅動）
- [ ] **無非預期 latch**（用 lint 工具確認）
- [ ] **無組合邏輯迴路**（特別注意 valid 不依賴 ready）
- [ ] **位寬匹配**，無隱式截斷或擴展
- [ ] **無使用 `x` 或 `z`** 在可綜合代碼
- [ ] **無手動 clock gating**（除非用 library ICG cell）
- [ ] **無使用信號當 clock**
- [ ] 異步重置雙級同步釋放（synchronous deassertion）
- [ ] 跨時鐘域信號使用雙級同步器
- [ ] 算術運算位寬足夠（無溢位被截斷）
- [ ] 參數化正確，邊界情況（如 N=0, N=1）已處理

## 5. Generate / For 循環

- [ ] **重複硬體結構使用 `generate` 而非 `for` 循環**
- [ ] **`for` 循環僅用於 testbench、initial、function 內**
- [ ] **所有 `generate` 塊有明確命名**（`gen_xxx`）
- [ ] 條件 `generate` 的所有分支都有命名
- [ ] Generate 變數使用 `genvar` 宣告
- [ ] 嵌套 generate 不超過 3 層

## 6. Pipeline（如適用）

- [ ] 每級都有 `_q` 暫存器
- [ ] valid 信號跟著資料一起傳播
- [ ] **valid 不依賴 ready**（避免組合迴路）
- [ ] 有背壓時 ready 邏輯正確（`!valid_q || downstream_ready`）
- [ ] stall 時資料保持原值
- [ ] flush 時清 valid（資料可保留）
- [ ] 沒有跨 stage 的組合路徑
- [ ] 資料相依性正確處理（forwarding / bubble）

## 7. 文件

- [ ] 模組頂部有完整描述（File / Description / Author / Created）
- [ ] 複雜邏輯有註解說明「為什麼」而非「是什麼」
- [ ] 參數有用途說明
- [ ] Port 有必要的註解
- [ ] FSM 狀態轉換有圖示或註解（複雜時）

## 8. Lint / 工具檢查

- [ ] Verilator 或 Spyglass lint 通過
- [ ] 綜合工具的 unintended latch 警告為 0
- [ ] 綜合工具的 multi-driver 警告為 0
- [ ] 模擬器的 `WIDTH` mismatch 警告為 0

## 9. 自我覆核問題

完成代碼後問自己：

- 這個模組做什麼？輸入 / 處理 / 輸出 / 副作用？
- 資料從哪來？被誰消費？狀態何時改變？
- 哪個信號是 guarantee（必然成立），哪個是 policy（設計選擇）？
- 異常情況（reset、stall、flush、error）有正確處理嗎？
- 邊界值（N=0、N=MAX、empty、full）會出問題嗎？
