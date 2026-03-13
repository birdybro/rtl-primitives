// =============================================================================
// Module: popcount
// Description:
//   Population count — counts the number of '1' bits in the input vector and
//   returns the result as a binary value. Implements an adder tree for
//   O(log2 WIDTH) depth rather than a linear chain of additions.
//
// Parameters:
//   WIDTH - Bit width of the input vector (default: 8). Must be >= 1.
//
// Ports:
//   in    [WIDTH-1:0]              - Input vector
//   count [$clog2(WIDTH+1)-1:0]   - Number of set bits (0..WIDTH)
//
// Behavior:
//   Combinational. Each input bit is first zero-extended to
//   $clog2(WIDTH+1) bits; successive pairs are summed in an adder tree
//   until a single sum remains.
//
// Timing Assumptions:
//   Pure combinational. Critical path depth is O(log2 WIDTH) adder stages.
//
// Usage Notes:
//   - WIDTH may be any positive integer; the adder tree handles non-power-of-2
//     widths by treating absent bits as 0.
//   - Output width $clog2(WIDTH+1) is the minimum number of bits to represent
//     the maximum count of WIDTH.
//
// Example Instantiation:
//   popcount #(
//     .WIDTH(32)
//   ) u_pop (
//     .in   (data_word),
//     .count(set_bit_cnt)
//   );
// =============================================================================

module popcount #(
  parameter int WIDTH = 8
) (
  input  logic [WIDTH-1:0]            in,
  output logic [$clog2(WIDTH+1)-1:0]  count
);

  // -------------------------------------------------------------------------
  // Adder tree: store partial sums as a flat array sized for the tree levels.
  // Maximum nodes needed is 2*WIDTH (full binary tree upper bound).
  // Each partial sum requires at most $clog2(WIDTH+1) bits.
  // -------------------------------------------------------------------------
  localparam int CNT_W = $clog2(WIDTH + 1);

  // Use a packed array of partial sums; tree reduces WIDTH leaves to 1 root.
  logic [CNT_W-1:0] tree [0:2*WIDTH-1];

  always_comb begin
    // Initialise entire array to 0 for safety
    for (int i = 0; i < 2*WIDTH; i++) tree[i] = '0;

    // Load leaves: each input bit zero-extended to CNT_W bits
    for (int i = 0; i < WIDTH; i++) tree[WIDTH + i] = CNT_W'(in[i]);

    // Reduce tree bottom-up
    for (int i = WIDTH - 1; i >= 1; i--) begin
      tree[i] = tree[2*i] + tree[2*i + 1];
    end
  end

  assign count = tree[1];

endmodule
