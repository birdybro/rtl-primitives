# Arbiter Primitives

## Overview

Arbiters resolve simultaneous access requests from multiple initiators,
granting access to exactly one at a time. This library provides several
arbitration policies to match different fairness and latency requirements.

## Module Reference

### `fixed_priority_arbiter` — Fixed Priority

The simplest arbiter. The lowest-indexed requestor always wins when multiple
requests are active simultaneously.

```
Parameters: NUM_REQS (int) — number of requestors (default 4)
Ports:
  req [NUM_REQS-1:0] — request vector
  gnt [NUM_REQS-1:0] — one-hot grant vector
```

**Combinational.** No clock or reset needed.

**Use when:** Strict priority ordering is required (e.g., interrupt controllers).

**Starvation risk:** Lower-priority requestors may never get granted if
higher-priority requestors are always active.

---

### `round_robin_arbiter` — Round Robin

Fair arbitration that rotates the priority pointer after each grant, ensuring
every requestor gets service eventually.

```
Parameters: NUM_REQS (int)
Ports: clk, rst_n, req, gnt
```

**Registered.** Updates on posedge clk.

**Use when:** All requestors have equal priority and starvation must be
avoided.

---

### `fair_rotating_arbiter` — Fair Rotating Arbiter

Similar to round-robin but uses a rotating priority mask. Grants the
highest-priority active request from those not yet served in the current
rotation, then wraps.

```
Parameters: NUM_REQS (int)
Ports: clk, rst_n, req, gnt
```

---

### `masked_priority_arbiter` — Masked Priority Arbiter

Fixed-priority arbiter with a per-bit enable mask. Only requestors whose
corresponding mask bit is asserted are eligible for a grant.

```
Parameters: NUM_REQS (int)
Ports:
  req  [NUM_REQS-1:0] — request vector
  mask [NUM_REQS-1:0] — enable mask; only masked-in bits participate
  gnt  [NUM_REQS-1:0] — one-hot grant
```

**Combinational.**

**Use when:** Some requestors must be dynamically disabled (e.g., DMA channels
that are not configured).

---

### `parking_arbiter` — Parking Arbiter

Round-robin arbiter that *parks* (holds) the last granted requestor when no
new requests are active, eliminating re-arbitration overhead when only one
requestor is continuously active.

```
Parameters: NUM_REQS (int)
Ports: clk, rst_n, req, gnt
```

**Use when:** One requestor is usually the only active one (high locality).

---

### `tree_arbiter` — Tree Arbiter

Hierarchical binary-tree priority arbiter. Lower-indexed requestors have
higher priority, equivalent to fixed-priority, but implemented as a balanced
tree for O(log N) critical path depth.

```
Parameters: NUM_REQS (int, power of two recommended)
Ports: req, gnt (combinational)
```

**Use when:** NUM_REQS is large and gate-delay matters.

---

### `weighted_round_robin_arbiter` — Weighted Round Robin

Round-robin arbiter where each requestor is assigned a weight. A requestor
with weight W gets W grants for every 1 grant that a requestor with weight 1
gets, over sufficient observation time.

```
Parameters:
  NUM_REQS     (int) — number of requestors (default 4)
  WEIGHT_WIDTH (int) — bits per weight value (default 4)
Ports:
  clk, rst_n
  req    [NUM_REQS-1:0]
  weight [NUM_REQS-1:0][WEIGHT_WIDTH-1:0] — per-requestor weights
  gnt    [NUM_REQS-1:0]
```

**Use when:** Bandwidth sharing with differentiated service is required
(e.g., QoS in a network-on-chip).

## Choosing an Arbiter

| Requirement | Recommended Module |
|-------------|-------------------|
| Strict priority, simple | `fixed_priority_arbiter` |
| Equal fairness, low overhead | `round_robin_arbiter` |
| Equal fairness, one dominant requester | `parking_arbiter` |
| Dynamic masking | `masked_priority_arbiter` |
| Large N, gate-delay sensitive | `tree_arbiter` |
| Bandwidth proportioning | `weighted_round_robin_arbiter` |

## Example: Round-Robin Arbiter

```systemverilog
round_robin_arbiter #(
  .NUM_REQS(4)
) u_rr_arb (
  .clk  (clk),
  .rst_n(rst_n),
  .req  (req_bus),
  .gnt  (gnt_bus)
);
```

## Example: Weighted Round-Robin

```systemverilog
logic [3:0][3:0] weights;
assign weights[0] = 4'd1;
assign weights[1] = 4'd2;
assign weights[2] = 4'd4;
assign weights[3] = 4'd1;

weighted_round_robin_arbiter #(
  .NUM_REQS    (4),
  .WEIGHT_WIDTH(4)
) u_wrr (
  .clk   (clk),
  .rst_n (rst_n),
  .req   (req_bus),
  .weight(weights),
  .gnt   (gnt_bus)
);
```
