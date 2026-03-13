// =============================================================================
// Module: async_fifo
// Description:
//   Asynchronous (dual-clock) FIFO using Gray-code pointers for safe CDC.
//   Write and read operations occur in fully independent clock domains.
//
//   Architecture:
//     - A dual-port synchronous SRAM (inferred from a 2-D register array).
//     - Binary write/read counters, each (ADDR_WIDTH+1) bits wide; the extra
//       MSB is used to distinguish the full condition from the empty condition
//       when the lower ADDR_WIDTH bits are equal.
//     - Each binary counter is converted to Gray code before being synchronized
//       into the opposite domain via gray_pointer_sync (2-FF synchronizer).
//     - Full  detected in the WRITE domain by comparing wr_ptr_gray with the
//       synchronized rd_ptr_gray (top two bits inverted for full check).
//     - Empty detected in the READ  domain by comparing rd_ptr_gray with the
//       synchronized wr_ptr_gray.
//
// Parameters:
//   DATA_WIDTH - Width of each FIFO word in bits (default: 8).
//   ADDR_WIDTH - Log2 of the FIFO depth (default: 4 → 16 entries).
//
// Ports:
//   wr_clk  - Write clock.
//   wr_rst_n- Active-low asynchronous reset (write domain).
//   wr_en   - Write enable; ignored when wr_full is high.
//   wr_data - Data word to write.
//   wr_full - Asserted when the FIFO cannot accept more data.
//
//   rd_clk  - Read clock.
//   rd_rst_n- Active-low asynchronous reset (read domain).
//   rd_en   - Read enable; ignored when rd_empty is high.
//   rd_data - Data word read from the FIFO.
//   rd_empty- Asserted when no data is available.
//
// Timing / Behavior Assumptions:
//   - wr_en must be deasserted (or ignored) when wr_full is high; writes
//     while full produce no visible effect (data is NOT written).
//   - rd_en must be deasserted (or ignored) when rd_empty is high; reads
//     while empty return rd_data from the last valid read address.
//   - wr_rst_n and rd_rst_n may be asserted independently, but both should
//     be released before normal operation to ensure pointers are coherent.
//   - FIFO depth = 2^ADDR_WIDTH entries.
//
// Usage Notes:
//   - For first-word-fall-through behavior, register rd_en externally.
//   - Do NOT read wr_full in the read domain or rd_empty in the write domain;
//     these flags are valid only in their respective domains.
//
// Example Instantiation:
//   async_fifo #(
//     .DATA_WIDTH(8),
//     .ADDR_WIDTH(4)
//   ) u_async_fifo (
//     .wr_clk  (wr_clk),
//     .wr_rst_n(wr_rst_n),
//     .wr_en   (fifo_wr_en),
//     .wr_data (fifo_wr_data),
//     .wr_full (fifo_full),
//     .rd_clk  (rd_clk),
//     .rd_rst_n(rd_rst_n),
//     .rd_en   (fifo_rd_en),
//     .rd_data (fifo_rd_data),
//     .rd_empty(fifo_empty)
//   );
// =============================================================================

module async_fifo #(
  parameter int DATA_WIDTH = 8,
  parameter int ADDR_WIDTH = 4
) (
  // Write port
  input  logic                  wr_clk,
  input  logic                  wr_rst_n,
  input  logic                  wr_en,
  input  logic [DATA_WIDTH-1:0] wr_data,
  output logic                  wr_full,
  // Read port
  input  logic                  rd_clk,
  input  logic                  rd_rst_n,
  input  logic                  rd_en,
  output logic [DATA_WIDTH-1:0] rd_data,
  output logic                  rd_empty
);

  localparam int DEPTH = 2 ** ADDR_WIDTH;

  // -------------------------------------------------------------------------
  // Dual-port memory array
  // -------------------------------------------------------------------------
  logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

  // -------------------------------------------------------------------------
  // Write domain: binary pointer and Gray-code conversion
  // -------------------------------------------------------------------------
  logic [ADDR_WIDTH:0] wr_ptr_bin;   // Binary write pointer (ADDR_WIDTH+1 bits)
  logic [ADDR_WIDTH:0] wr_ptr_gray;  // Gray-code write pointer

  // Binary-to-Gray conversion (XOR with right-shifted self)
  assign wr_ptr_gray = wr_ptr_bin ^ (wr_ptr_bin >> 1);

  always_ff @(posedge wr_clk or negedge wr_rst_n) begin
    if (!wr_rst_n) begin
      wr_ptr_bin <= '0;
    end else if (wr_en && !wr_full) begin
      mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= wr_data;
      wr_ptr_bin <= wr_ptr_bin + 1'b1;
    end
  end

  // -------------------------------------------------------------------------
  // Read domain: binary pointer and Gray-code conversion
  // -------------------------------------------------------------------------
  logic [ADDR_WIDTH:0] rd_ptr_bin;   // Binary read pointer (ADDR_WIDTH+1 bits)
  logic [ADDR_WIDTH:0] rd_ptr_gray;  // Gray-code read pointer

  assign rd_ptr_gray = rd_ptr_bin ^ (rd_ptr_bin >> 1);

  always_ff @(posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n) begin
      rd_ptr_bin <= '0;
    end else if (rd_en && !rd_empty) begin
      rd_ptr_bin <= rd_ptr_bin + 1'b1;
    end
  end

  assign rd_data = mem[rd_ptr_bin[ADDR_WIDTH-1:0]];

  // -------------------------------------------------------------------------
  // Cross-domain pointer synchronization using gray_pointer_sync
  // -------------------------------------------------------------------------

  // Write pointer (Gray) → Read domain
  logic [ADDR_WIDTH:0] wr_ptr_gray_sync;

  gray_pointer_sync #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) u_wptr_sync (
    .clk         (rd_clk),
    .rst_n       (rd_rst_n),
    .gray_ptr_in (wr_ptr_gray),
    .gray_ptr_out(wr_ptr_gray_sync)
  );

  // Read pointer (Gray) → Write domain
  logic [ADDR_WIDTH:0] rd_ptr_gray_sync;

  gray_pointer_sync #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) u_rptr_sync (
    .clk         (wr_clk),
    .rst_n       (wr_rst_n),
    .gray_ptr_in (rd_ptr_gray),
    .gray_ptr_out(rd_ptr_gray_sync)
  );

  // -------------------------------------------------------------------------
  // Full flag (write domain)
  // The FIFO is full when the write pointer has wrapped around and is one
  // entry behind the read pointer.  In Gray code this manifests as:
  //   - The two MSBs of wr_ptr_gray are the INVERSE of rd_ptr_gray_sync's MSBs
  //   - All lower bits are equal
  // -------------------------------------------------------------------------
  logic [ADDR_WIDTH:0] wr_full_val;
  assign wr_full_val = {~rd_ptr_gray_sync[ADDR_WIDTH:ADDR_WIDTH-1],
                         rd_ptr_gray_sync[ADDR_WIDTH-2:0]};

  always_ff @(posedge wr_clk or negedge wr_rst_n) begin
    if (!wr_rst_n) begin
      wr_full <= 1'b0;
    end else begin
      wr_full <= (wr_ptr_gray == wr_full_val);
    end
  end

  // -------------------------------------------------------------------------
  // Empty flag (read domain)
  // The FIFO is empty when the synchronized write pointer equals the read
  // pointer (same Gray code value).
  // -------------------------------------------------------------------------
  always_ff @(posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n) begin
      rd_empty <= 1'b1;
    end else begin
      rd_empty <= (wr_ptr_gray_sync == rd_ptr_gray);
    end
  end

endmodule
