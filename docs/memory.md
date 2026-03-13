# Memory Primitives

## Overview

Memory primitives provide general-purpose storage elements from single-entry
mailboxes to multi-kilobit RAMs and content-addressable memories.

## Module Reference

### `simple_fifo` — Synchronous FIFO

Classic synchronous FIFO with count output.

```
Parameters: DATA_WIDTH (int), DEPTH (int), ADDR_WIDTH ($clog2(DEPTH))
Ports:
  clk, rst_n
  wr_en, wr_data         — write interface
  rd_en, rd_data         — read interface
  full, empty            — status flags
  count [$clog2(DEPTH+1)-1:0]
```

Simultaneous read and write are supported; count remains unchanged.
`rd_data` is registered (1-cycle read latency).

---

### `circular_buffer` — Circular Buffer

Functionally equivalent to `simple_fifo` but with explicit ring-pointer
semantics (tail = write, head = read).

```
Parameters: DATA_WIDTH (int), DEPTH (int, power of two recommended)
```

---

### `dual_port_ram` — True Dual-Port RAM

Synchronous RAM with two independent read/write ports (Port A and Port B).
Each port has its own clock, enable, write-enable, address, and data signals.

```
Parameters: DATA_WIDTH (int), DEPTH (int), ADDR_WIDTH ($clog2(DEPTH))
Port A: clk_a, en_a, we_a, addr_a, din_a, dout_a
Port B: clk_b, en_b, we_b, addr_b, din_b, dout_b
```

Write-first semantics: dout reflects the written data on the same cycle.

---

### `register_file` — Register File

Multi-read-port register file with write-to-read forwarding. Reads are
combinational; writes are registered.

```
Parameters:
  DATA_WIDTH    (int, default 32)
  NUM_REGS      (int, default 32)
  NUM_READ_PORTS(int, default 2)
Ports:
  clk, rst_n
  we, waddr, wdata
  raddr [NUM_READ_PORTS-1:0][$clog2(NUM_REGS)-1:0]
  rdata [NUM_READ_PORTS-1:0][DATA_WIDTH-1:0]
```

**Forwarding:** If a read address matches the write address on the same cycle
that `we` is asserted, `rdata` returns the new write data immediately.

---

### `content_addressable_memory` — CAM

Fully-associative memory with combinational content search.

```
Parameters: DATA_WIDTH (int), DEPTH (int)
Ports:
  clk, rst_n
  wr_en, wr_addr, wr_data, wr_valid_bit — write interface
  search_key, hit, hit_addr              — search interface (combinational)
```

`hit_addr` returns the lowest-index matching entry when multiple entries match.
Reset clears all valid bits; data array is not cleared.

---

### `line_buffer` — Image Line Buffer

Streaming shift-register buffer for image/video processing. Retains the last
NUM_LINES complete pixel rows and presents them as a column for convolution kernels.

```
Parameters: DATA_WIDTH (int), LINE_WIDTH (int), NUM_LINES (int)
Ports:
  clk, rst_n
  wr_en, wr_data
  pixel_col  [$clog2(LINE_WIDTH)-1:0]     — column index of latest pixel
  line_out   [NUM_LINES-1:0][DATA_WIDTH-1:0] — column of NUM_LINES pixels
  line_valid — asserted once NUM_LINES complete lines have been written
```

## Usage Examples

### Simple FIFO

```systemverilog
simple_fifo #(
  .DATA_WIDTH(8),
  .DEPTH     (16)
) u_fifo (
  .clk    (clk),
  .rst_n  (rst_n),
  .wr_en  (push),
  .wr_data(push_data),
  .rd_en  (pop),
  .rd_data(pop_data),
  .full   (fifo_full),
  .empty  (fifo_empty),
  .count  (fifo_count)
);
```

### 3×1 Convolution Line Buffer

```systemverilog
logic [2:0][7:0] column; // 3 pixels, one per line
logic valid;

line_buffer #(
  .DATA_WIDTH(8),
  .LINE_WIDTH(640),
  .NUM_LINES (3)
) u_lbuf (
  .clk       (clk),
  .rst_n     (rst_n),
  .wr_en     (pixel_valid),
  .wr_data   (pixel_in),
  .pixel_col (col_idx),
  .line_out  (column),
  .line_valid(valid)
);

// When valid: column[0]=current, column[1]=prev, column[2]=prev-prev
assign top    = column[2];
assign middle = column[1];
assign bottom = column[0];
```

### Register File (CPU style)

```systemverilog
logic [1:0][4:0]  rs_addr;
logic [1:0][31:0] rs_data;

assign rs_addr[0] = rs1;
assign rs_addr[1] = rs2;

register_file #(
  .DATA_WIDTH    (32),
  .NUM_REGS      (32),
  .NUM_READ_PORTS(2)
) u_rf (
  .clk  (clk),
  .rst_n(rst_n),
  .we   (wb_we),
  .waddr(wb_rd),
  .wdata(wb_result),
  .raddr(rs_addr),
  .rdata(rs_data)
);
```
