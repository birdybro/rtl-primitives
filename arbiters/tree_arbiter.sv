// =============================================================================
// Module: tree_arbiter
// Description:
//   Combinational binary-tree fixed-priority arbiter. Decomposes arbitration
//   into a hierarchy of 2-input cells, giving O(log2 N) gate depth instead of
//   the O(N) depth of a ripple-carry style arbiter. Lowest index wins at every
//   node.
//
//   Tree structure (NUM_REQS = 8 example):
//     Level 0 (leaves): pairs (0,1), (2,3), (4,5), (6,7)
//     Level 1:          pairs of level-0 winners
//     Level 2 (root):   final winner
//   The tree winner propagates its index back down so that exactly one leaf
//   asserts its gnt bit.
//
//   NUM_REQS must be a power of two. For non-power-of-two counts, pad req
//   with zeros to the next power of two and ignore the extra gnt bits.
//
// Parameters:
//   NUM_REQS - Number of requestors; must be a power of 2 (default 8)
//
// Ports:
//   req [NUM_REQS-1:0] - Request vector (input)
//   gnt [NUM_REQS-1:0] - One-hot grant vector (output)
//
// Behavior:
//   - Purely combinational; no clock or reset.
//   - Lowest-index requestor among all asserted req bits is granted.
//   - If req == 0, gnt == 0.
//
// Timing / Assumptions:
//   - Propagation depth is O(log2(NUM_REQS)) gate stages.
//   - Downstream registers should sample gnt on the appropriate clock edge.
//
// Usage Notes:
//   - Preferred over the linear fixed_priority_arbiter when NUM_REQS is large
//     and timing closure on the grant path is critical.
//
// Example Instantiation:
//   tree_arbiter #(
//     .NUM_REQS(8)
//   ) u_ta (
//     .req (req_bus),
//     .gnt (gnt_bus)
//   );
// =============================================================================

module tree_arbiter #(
    parameter int NUM_REQS = 8
) (
    input  logic [NUM_REQS-1:0] req,
    output logic [NUM_REQS-1:0] gnt
);

    // -------------------------------------------------------------------------
    // Internal flat array representing all tree nodes.
    // We store NUM_REQS-1 internal nodes + NUM_REQS leaves = 2*NUM_REQS-1 nodes.
    // Node 0 = root. Node k's children are 2k+1 (left/lower) and 2k+2 (right/upper).
    // Leaf node for req[i] = node (NUM_REQS - 1 + i).
    //
    // Each node carries one bit: 1 = "any request in my subtree".
    // The winner index is reconstructed top-down from the root.
    //
    // Continuous assign statements are used (instead of always_comb with a
    // for loop) so that the dataflow order is unambiguous to lint tools.
    // -------------------------------------------------------------------------
    localparam int NODES = 2 * NUM_REQS - 1;

    logic [NODES-1:0] has_req;   // 1 if subtree has any request
    logic [NODES-1:0] sel;       // 1 if this subtree is selected (top-down)

    // -------------------------------------------------------------------------
    // Leaves: wire directly to req inputs
    // -------------------------------------------------------------------------
    genvar i;
    generate
        for (i = 0; i < NUM_REQS; i++) begin : gen_leaves
            assign has_req[NUM_REQS - 1 + i] = req[i];
            assign gnt[i]                     = sel[NUM_REQS - 1 + i];
        end
    endgenerate

    // -------------------------------------------------------------------------
    // Internal nodes: bottom-up request presence, top-down selection.
    // k counts from leaves toward root (NUM_REQS-2 down to 0).
    // Using a generate loop with assign keeps ordering explicit for linters.
    // -------------------------------------------------------------------------
    genvar k;
    generate
        for (k = 0; k < NUM_REQS - 1; k++) begin : gen_nodes
            // Bottom-up: OR of children
            assign has_req[k] = has_req[2*k+1] | has_req[2*k+2];
        end
    endgenerate

    // Root is selected iff any request exists
    assign sel[0] = has_req[0];

    generate
        for (k = 0; k < NUM_REQS - 1; k++) begin : gen_sel
            // Left child (lower indices) wins if it has any request
            assign sel[2*k+1] = sel[k] &  has_req[2*k+1];
            // Right child wins only when left subtree is empty
            assign sel[2*k+2] = sel[k] & ~has_req[2*k+1];
        end
    endgenerate

endmodule
