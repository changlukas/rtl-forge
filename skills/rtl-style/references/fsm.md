# Finite State Machine (FSM)

## Three-process FSM (recommended)

- **Process 1 (sequential)**: update the state register
- **Process 2 (combinational)**: compute next state
- **Process 3 (combinational)**: drive outputs

```systemverilog
typedef enum logic [2:0] {
    IDLE       = 3'b001,
    FETCH      = 3'b010,
    EXECUTE    = 3'b011,
    WRITE_BACK = 3'b100,
    ERROR      = 3'b101
} state_e;

state_e state_q, state_d;

// ====================================================================
// Process 1: state register
// ====================================================================
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) state_q <= IDLE;
    else         state_q <= state_d;
end

// ====================================================================
// Process 2: next-state logic
// ====================================================================
always_comb begin
    state_d = state_q;          // default: stay in current state

    case (state_q)
        IDLE:       if (start_i)       state_d = FETCH;
        FETCH:      if (fetch_error)   state_d = ERROR;
                    else if (fetch_done) state_d = EXECUTE;
        EXECUTE:    if (exec_done)     state_d = WRITE_BACK;
        WRITE_BACK: if (wb_done)       state_d = IDLE;
        ERROR:      if (error_clear)   state_d = IDLE;
        default:    state_d = IDLE;     // mandatory default
    endcase
end

// ====================================================================
// Process 3: output logic (Moore-style)
// ====================================================================
always_comb begin
    // Default outputs (avoid latch)
    fetch_en = 1'b0;
    exec_en  = 1'b0;
    wb_en    = 1'b0;
    error_o  = 1'b0;

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

## State encoding

| Encoding | When to use | Example |
|----------|-------------|---------|
| Binary | Many states, area-sensitive | `IDLE=2'd0, ACTIVE=2'd1` |
| One-hot | Few states (≤8), high speed | `IDLE=4'b0001, ACTIVE=4'b0010` |
| Gray | Cross clock-domain | `S0=2'b00, S1=2'b01, S2=2'b11, S3=2'b10` |

Let the synthesis tool select via attribute when unsure:
```systemverilog
(* fsm_encoding = "one_hot" *) state_e state_q;
```

## Mandatory rules

- Define states with `typedef enum`, never raw `logic [N:0]`.
- Both `case (state_q)` blocks must have a `default`.
- Process 2 must default `state_d = state_q;` first.
- Process 3 must assign defaults to every output before the case.
- Reset to a known state (`state_q <= IDLE`).

## Anti-patterns

```systemverilog
// ❌ One-process FSM (mixed sequential/combinational)
always_ff @(posedge clk_i) begin
    case (state_q)
        IDLE: if (start_i) begin
            state_q  <= ACTIVE;
            output_o <= 1'b1;       // output logic embedded — hard to maintain
        end
    endcase
end

// ❌ Missing default
always_comb begin
    case (state_q)
        IDLE:   state_d = ACTIVE;
        ACTIVE: state_d = DONE;
        // No default → unlisted states latch
    endcase
end

// ❌ Output logic without defaults
always_comb begin
    case (state_q)
        FETCH: fetch_en = 1'b1;
        // Other states → fetch_en latches
    endcase
end
```

## Template

`templates/fsm.sv`
