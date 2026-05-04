# Pipeline Style

## Core principles

1. Separate datapath from control path.
2. Name every stage with `s<N>_<signal>_q`.
3. **valid must not depend on ready** (would create a combinational loop).
4. On stall, hold the stage; on flush, clear `valid` (data may stay).
5. Between stages: registers only — no cross-stage combinational logic.

## Naming

```systemverilog
// Stage 1 → Stage 2
logic [31:0] s1_data_q;     // stage 1 registered
logic [31:0] s1_data_d;     // stage 1 next value (combinational)
logic        s1_valid_q;
logic [31:0] s2_data_q;
logic        s2_valid_q;

// Or functional naming
logic [31:0] fetch_data_q;
logic [31:0] decode_data_q;
logic [31:0] execute_data_q;
```

## Simple pipeline (no backpressure)

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

## Pipeline with backpressure (valid-ready handshake)

```systemverilog
// Stage 1
logic s1_ready;
assign s1_ready = !s1_valid_q || s2_ready;     // empty OR downstream ready
assign ready_o  = s1_ready;

always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        s1_data_q  <= '0;
        s1_valid_q <= 1'b0;
    end else if (s1_ready) begin
        s1_data_q  <= data_i;
        s1_valid_q <= valid_i;
    end
    // else: stall, hold current value
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

## Valid-ready protocol rules

1. Once `valid` is asserted, it must stay asserted until `ready` is sampled high (handshake completes).
2. `ready` may toggle freely.
3. Data transfers on the cycle where `valid && ready`.
4. **`valid` must not be combinationally derived from `ready`** (loop).

```systemverilog
// ✓ valid is independent of ready
always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
        valid_q <= 1'b0;
    end else if (condition) begin
        valid_q <= 1'b1;
        data_q  <= new_data;
    end else if (valid_q && ready_i) begin
        valid_q <= 1'b0;        // clear only on handshake
    end
end

// ❌ Combinational loop
assign valid_o = ready_i && some_condition;
```

## Stall and flush

```systemverilog
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        stage_data_q  <= '0;
        stage_valid_q <= 1'b0;
    end else if (flush_i) begin
        // Flush: clear valid → bubble. Data may stay or be cleared.
        stage_valid_q <= 1'b0;
    end else if (!stall_i) begin
        // Normal: advance the pipeline
        stage_data_q  <= prev_data_q;
        stage_valid_q <= prev_valid_q;
    end
    // else: stall, hold both data and valid
end
```

## Bubble insertion

```systemverilog
always_ff @(posedge clk_i) begin
    s1_data_q  <= data_i;
    s1_valid_q <= valid_i && !insert_bubble_i;     // force valid=0 → bubble
end
// Bubbles propagate naturally without further intervention.
```

## Skid buffer (breaks the ready combinational path)

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
        // Main path
        if (ready_i || !valid_q) begin
            data_q  <= data_i;
            valid_q <= valid_i;
        end
        // Skid: capture incoming data while output is stalled
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

## Template

`templates/pipeline.sv`.

## Design checklist

- [ ] Every stage has a `_q` register.
- [ ] `valid` propagates with the data.
- [ ] `ready` logic is correct under backpressure.
- [ ] `valid` does not depend on `ready`.
- [ ] Stall preserves data.
- [ ] Flush clears `valid` (data may stay).
- [ ] No cross-stage combinational paths.
- [ ] Inter-stage timing closes.
- [ ] Data hazards (RAW/WAR/WAW) are handled.
- [ ] Parametric edge cases (NUM_STAGES = 0 / 1) handled.

## Common mistakes

```systemverilog
// ❌ valid combinationally depends on ready
assign valid_o = ready_i && internal_valid;

// ❌ Cross-stage arithmetic
assign s2_result = s1_data_q + s2_data_q;   // mixes two stages directly

// ❌ Stall clears data
if (!stall_i) data_q <= data_i;
else          data_q <= '0;                  // stall must hold!

// ❌ Flush clears data but leaves valid
if (flush_i) data_q <= '0;                   // valid not cleared → bubble fails

// ❌ Parametric NUM_STAGES = 0 not handled
assign output = stage_q[NUM_STAGES-1];       // 0-1 = -1, out of range
```
