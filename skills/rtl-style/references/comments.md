# Comments and Documentation

## Comment what, not why

Code shows *what*; comments must explain *why*.

```systemverilog
// ❌ Restates the code
counter <= counter + 1;  // Increment counter

// ✓ Explains intent
counter <= counter + 1;  // Watchdog needs 100 cycles before timeout

// ✓ Explains a non-obvious constraint
// AXI4 spec requires WVALID to remain high until WREADY is asserted.
// This flag tracks the in-flight handshake.
assign wvalid_hold = wvalid_q && !wready_i;
```

## Module documentation block

Every module starts with a banner. Mandatory fields: `Module`, `Description`, `Parameters` (if any), `Interfaces` (if non-trivial), `Author`, `Date`, `Version`.

```systemverilog
// ============================================================================
// Module: axi_dma_controller
//
// Description:
//   Multi-channel DMA controller with AXI4 master interface.
//   - Up to 16 independent channels
//   - Scatter-gather descriptor chains
//   - Priority-based arbitration
//   - Burst optimization for sequential transfers
//
// Parameters:
//   NUM_CHANNELS : Number of DMA channels (1-16)
//   DATA_WIDTH   : AXI data bus width (32/64/128/256)
//   ADDR_WIDTH   : Address bus width (32/64)
//   MAX_BURST    : Maximum burst length (1-256)
//
// Interfaces:
//   AXI4 Master  : Memory access
//   APB Slave    : Configuration registers
//
// Author : Lucas
// Date   : 2026-05-04
// Version: 1.2
// ============================================================================
```

See `templates/module.sv` for a ready-to-copy header.

## Annotating complex logic

Use a block comment to explain the **algorithm or invariant**, not each line.

```systemverilog
/* Credit-based flow control
 *
 * Each output port maintains a credit counter tracking downstream buffer
 * space. Credits are:
 *   - decremented on flit transmit
 *   - incremented on credit-return packet
 *
 * Transmission gated by:
 *   1. credit_q > 0 (buffer space available)
 *   2. valid_i high (data ready)
 *   3. !blocked   (no upstream backpressure)
 */
always_comb begin
    tx_allowed = (credit_q > '0) && valid_i && !blocked;
end
```

## Tagged comments

Use these tags consistently. Tag + author makes them grep-able.

| Tag | Meaning |
|-----|---------|
| `TODO(user)`  | Planned work, non-blocking |
| `FIXME(user)` | Known defect that must be addressed |
| `NOTE`        | Non-obvious assumption or contract |
| `HACK`        | Temporary workaround; cite the underlying cause |

```systemverilog
// TODO(lucas): add support for unaligned transfers
// FIXME(lucas): race condition when enable changes during active transfer
// NOTE: this implementation assumes little-endian byte ordering
// HACK: workaround for synthesis tool bug — issue #1234
```

`HACK` and `FIXME` should always reference the bug/ticket they trace back to.
