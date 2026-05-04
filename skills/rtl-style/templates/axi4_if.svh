// ============================================================================
// File        : axi4_if.svh
// Description : AXI4 interface signal width and field definitions
// ============================================================================

`ifndef AXI4_IF_SVH
`define AXI4_IF_SVH

// ============================================================================
// AXI4 Parameter Definitions
// ============================================================================
`define AXI4_ADDR_WIDTH     32
`define AXI4_DATA_WIDTH     64
`define AXI4_ID_WIDTH       4
`define AXI4_USER_WIDTH     8

// Derived widths
`define AXI4_STRB_WIDTH     (`AXI4_DATA_WIDTH/8)
`define AXI4_BURST_WIDTH    2
`define AXI4_SIZE_WIDTH     3
`define AXI4_LEN_WIDTH      8
`define AXI4_RESP_WIDTH     2

// ============================================================================
// AXI4 Write Address Channel
// ============================================================================
`define AXI4_AW_ADDR_WIDTH  `AXI4_ADDR_WIDTH
`define AXI4_AW_ID_WIDTH    `AXI4_ID_WIDTH
`define AXI4_AW_LEN_WIDTH   `AXI4_LEN_WIDTH
`define AXI4_AW_SIZE_WIDTH  `AXI4_SIZE_WIDTH
`define AXI4_AW_BURST_WIDTH `AXI4_BURST_WIDTH
`define AXI4_AW_USER_WIDTH  `AXI4_USER_WIDTH

// ============================================================================
// AXI4 Write Data Channel
// ============================================================================
`define AXI4_W_DATA_WIDTH   `AXI4_DATA_WIDTH
`define AXI4_W_STRB_WIDTH   `AXI4_STRB_WIDTH
`define AXI4_W_USER_WIDTH   `AXI4_USER_WIDTH

// ============================================================================
// AXI4 Write Response Channel
// ============================================================================
`define AXI4_B_ID_WIDTH     `AXI4_ID_WIDTH
`define AXI4_B_RESP_WIDTH   `AXI4_RESP_WIDTH
`define AXI4_B_USER_WIDTH   `AXI4_USER_WIDTH

// ============================================================================
// AXI4 Read Address Channel
// ============================================================================
`define AXI4_AR_ADDR_WIDTH  `AXI4_ADDR_WIDTH
`define AXI4_AR_ID_WIDTH    `AXI4_ID_WIDTH
`define AXI4_AR_LEN_WIDTH   `AXI4_LEN_WIDTH
`define AXI4_AR_SIZE_WIDTH  `AXI4_SIZE_WIDTH
`define AXI4_AR_BURST_WIDTH `AXI4_BURST_WIDTH
`define AXI4_AR_USER_WIDTH  `AXI4_USER_WIDTH

// ============================================================================
// AXI4 Read Data Channel
// ============================================================================
`define AXI4_R_DATA_WIDTH   `AXI4_DATA_WIDTH
`define AXI4_R_ID_WIDTH     `AXI4_ID_WIDTH
`define AXI4_R_RESP_WIDTH   `AXI4_RESP_WIDTH
`define AXI4_R_USER_WIDTH   `AXI4_USER_WIDTH

// ============================================================================
// AXI4 Burst Type Definitions
// ============================================================================
`define AXI4_BURST_FIXED    2'b00
`define AXI4_BURST_INCR     2'b01
`define AXI4_BURST_WRAP     2'b10

// ============================================================================
// AXI4 Response Type Definitions
// ============================================================================
`define AXI4_RESP_OKAY      2'b00
`define AXI4_RESP_EXOKAY    2'b01
`define AXI4_RESP_SLVERR    2'b10
`define AXI4_RESP_DECERR    2'b11

// ============================================================================
// AXI4 Size Encoding
// ============================================================================
`define AXI4_SIZE_1B        3'b000  // 1   byte
`define AXI4_SIZE_2B        3'b001  // 2   bytes
`define AXI4_SIZE_4B        3'b010  // 4   bytes
`define AXI4_SIZE_8B        3'b011  // 8   bytes
`define AXI4_SIZE_16B       3'b100  // 16  bytes
`define AXI4_SIZE_32B       3'b101  // 32  bytes
`define AXI4_SIZE_64B       3'b110  // 64  bytes
`define AXI4_SIZE_128B      3'b111  // 128 bytes

`endif // AXI4_IF_SVH
