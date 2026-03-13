# Encoding Primitives

## Overview

Encoding primitives convert between binary, one-hot, Gray, and thermometer
code representations.

## Module Reference

### `gray_encoder` — Binary to Gray Code

```
Parameters: WIDTH (int)
Ports: bin_in [WIDTH-1:0], gray_out [WIDTH-1:0]
Combinational. gray = bin ^ (bin >> 1)
```

---

### `gray_decoder` — Gray Code to Binary

```
Parameters: WIDTH (int)
Ports: gray_in [WIDTH-1:0], bin_out [WIDTH-1:0]
Combinational. Cascaded XOR reduction.
```

---

### `binary_encoder` — Binary Index to One-Hot

Asserts exactly one output bit corresponding to the input binary index.
No enable pin.

```
Parameters: IN_WIDTH (int), OUT_WIDTH (int)
Ports: bin_in [IN_WIDTH-1:0], onehot_out [OUT_WIDTH-1:0]
Combinational. onehot_out = 1 << bin_in
```

---

### `binary_decoder` — Binary Index to One-Hot with Enable

Same as `binary_encoder` but with an active-high `en` gate. When `en=0`,
output is all zeros.

```
Parameters: IN_WIDTH (int), OUT_WIDTH (int)
Ports: en, in [IN_WIDTH-1:0], out [OUT_WIDTH-1:0]
```

---

### `onehot_encoder` — One-Hot to Binary Index (with valid)

Converts a one-hot input to binary. Asserts `valid` when any input bit is set.

```
Parameters: WIDTH (int)
Ports: onehot_in [WIDTH-1:0], bin_out [$clog2(WIDTH)-1:0], valid
```

*Note: a second `onehot_encoder` in `bitops/` has different port names
(`in`, `out`) and no `valid` output. Both implement the same logical function.*

---

### `priority_encoder` — Priority Encoder (encoding/)

LSB-priority encoder. Returns the binary index of the lowest-indexed set bit.

```
Parameters: WIDTH (int)
Ports: req [WIDTH-1:0], enc [$clog2(WIDTH)-1:0], valid
```

*Note: a second `priority_encoder` in `bitops/` has port names `in` and `out`
instead of `req` and `enc`.*

---

### `bitmask_generator` — Bitmask Generator

Generates a field mask of `len` consecutive ones starting at `offset`.

```
Parameters: WIDTH (int)
Ports:
  offset [$clog2(WIDTH)-1:0]   — starting bit position
  len    [$clog2(WIDTH+1)-1:0] — number of ones
  mask   [WIDTH-1:0]
```

## Usage Examples

### Gray-Code FIFO Pointer

```systemverilog
// Encode write pointer before synchronization
gray_encoder #(.WIDTH(5)) u_wptr_enc (
  .bin_in  (wptr_bin),
  .gray_out(wptr_gray)
);

// Decode synchronized read pointer
gray_decoder #(.WIDTH(5)) u_rptr_dec (
  .gray_in(rptr_gray_sync),
  .bin_out(rptr_bin)
);
```

### Byte-Enable Mask Generation

```systemverilog
// Generate 4-bit byte-enable for a 32-bit write at byte offset 1, length 2
bitmask_generator #(.WIDTH(4)) u_be_gen (
  .offset(2'(1)),  // start at byte 1
  .len   (3'(2)),  // 2 bytes
  .mask  (byte_en) // = 4'b0110
);
```
