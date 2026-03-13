# Bit Operation Primitives

## Overview

Combinational bit-manipulation primitives for common operations in ALUs,
encoders, and compression logic.

## Module Reference

### `barrel_shifter` — Barrel Shifter

Logical left, logical right, and arithmetic right shift in a single module.

```
Parameters: WIDTH (int, default 8)
Ports:
  in        [WIDTH-1:0]
  shift_amt [$clog2(WIDTH)-1:0]
  dir       — 0=left, 1=right
  arith     — 0=logical, 1=arithmetic (sign-extend on right shift)
  out       [WIDTH-1:0]
```

---

### `rotate_unit` — Rotate Unit

Circular left or right rotation.

```
Parameters: WIDTH (int)
Ports:
  in      [WIDTH-1:0]
  rot_amt [$clog2(WIDTH)-1:0]
  dir     — 0=left, 1=right
  out     [WIDTH-1:0]
```

---

### `popcount` — Population Count

Counts the number of set bits (Hamming weight).

```
Parameters: WIDTH (int)
Ports: in [WIDTH-1:0], count [$clog2(WIDTH+1)-1:0]
```

---

### `leading_zero_counter` — Leading Zero Counter

Counts the number of consecutive zero bits from the MSB.

```
Parameters: WIDTH (int)
Ports: in [WIDTH-1:0], count [$clog2(WIDTH+1)-1:0], all_zero
```

`count == WIDTH` and `all_zero == 1` when input is zero.

---

### `trailing_zero_counter` — Trailing Zero Counter

Counts the number of consecutive zero bits from the LSB.

```
Parameters: WIDTH (int)
Ports: in [WIDTH-1:0], count [$clog2(WIDTH+1)-1:0], all_zero
```

---

### `priority_encoder` — Priority Encoder (bitops/)

Returns the binary index of the lowest-indexed set bit.

```
Parameters: WIDTH (int)
Ports: in [WIDTH-1:0], out [$clog2(WIDTH)-1:0], valid
```

---

### `onehot_encoder` — One-Hot to Binary (bitops/)

Converts a one-hot input to binary using OR reduction.

```
Parameters: WIDTH (int), OUT_WIDTH ($clog2(WIDTH))
Ports: in [WIDTH-1:0], out [OUT_WIDTH-1:0]
```

No `valid` output; use `encoding/onehot_encoder` if `valid` is needed.

---

### `onehot_decoder` — Binary to One-Hot

Converts a binary index to a one-hot vector.

```
Parameters: IN_WIDTH (int), OUT_WIDTH (int)
Ports: in [IN_WIDTH-1:0], out [OUT_WIDTH-1:0]
```

---

### `thermometer_encoder` — Thermometer Encoder

Converts a binary count N to N consecutive set bits from the LSB.

```
Parameters: OUT_WIDTH (int)
Ports: in [$clog2(OUT_WIDTH+1)-1:0], out [OUT_WIDTH-1:0]
```

## Usage Examples

### Count Set Bits

```systemverilog
popcount #(.WIDTH(32)) u_popcnt (
  .in   (data_word),
  .count(ones_count)
);
```

### Normalize a Value (Leading-Zero Count)

```systemverilog
leading_zero_counter #(.WIDTH(32)) u_lzc (
  .in      (mantissa),
  .count   (shift_amount),
  .all_zero(mantissa_zero)
);
assign normalized = mantissa << shift_amount;
```
