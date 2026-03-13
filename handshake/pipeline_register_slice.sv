// -----------------------------------------------------------------------------
// Module: pipeline_register_slice
// Description:
//   Fully registered (full/empty) register slice for pipeline timing path
//   isolation. Both up_ready (upstream back-pressure) and dn_valid
//   (downstream valid) are registered outputs, eliminating any combinational
//   logic between the upstream and downstream interfaces.
//
//   The implementation uses a two-state FSM (EMPTY / FULL) with an auxiliary
//   "bubble" slot so that back-to-back transfers are possible without stalling
//   the upstream for more than one cycle.
//
//   Internal operation uses two data registers:
//     - primary_reg: holds data presented to the downstream.
//     - aux_reg:     holds data accepted from upstream while primary is full
//                    but downstream has not yet consumed it.
//
// Parameters:
//   DATA_WIDTH - Width of the data bus in bits (default: 8)
//
// Ports:
//   clk      - Clock input (rising-edge triggered)
//   rst_n    - Active-low synchronous reset
//   up_valid - Upstream data valid
//   up_ready - Upstream ready (output, REGISTERED)
//   up_data  - Upstream data bus [DATA_WIDTH-1:0]
//   dn_valid - Downstream data valid (output, REGISTERED)
//   dn_ready - Downstream ready
//   dn_data  - Downstream data bus [DATA_WIDTH-1:0] (output)
//
// Behavior:
//   - up_ready and dn_valid are registered: no combinational path exists
//     between them.
//   - Maximum throughput: 1 word/cycle when both sides are always ready.
//   - Minimum latency: 1 cycle (data appears on dn_valid one cycle after
//     accepted from upstream).
//   - The slice absorbs up to 1 extra word beyond what downstream can accept
//     before asserting back-pressure.
//
// Timing assumptions:
//   - up_valid / up_data must be stable before the rising clock edge.
//   - dn_ready is sampled on the rising clock edge.
//
// Usage notes:
//   - Place at stage boundaries where timing closure requires fully registered
//     ready and valid signals.
//   - For a simpler (non-fully-registered) stage use ready_valid_stage.
//
// Example instantiation:
//   pipeline_register_slice #(
//     .DATA_WIDTH(32)
//   ) u_slice (
//     .clk     (clk),
//     .rst_n   (rst_n),
//     .up_valid(stage_a_valid),
//     .up_ready(stage_a_ready),
//     .up_data (stage_a_data),
//     .dn_valid(stage_b_valid),
//     .dn_ready(stage_b_ready),
//     .dn_data (stage_b_data)
//   );
// -----------------------------------------------------------------------------

module pipeline_register_slice #(
    parameter int DATA_WIDTH = 8
) (
    input  logic                  clk,
    input  logic                  rst_n,

    // Upstream interface
    input  logic                  up_valid,
    output logic                  up_ready,
    input  logic [DATA_WIDTH-1:0] up_data,

    // Downstream interface
    output logic                  dn_valid,
    input  logic                  dn_ready,
    output logic [DATA_WIDTH-1:0] dn_data
);

    // -------------------------------------------------------------------------
    // Slice state encoding
    // EMPTY: primary register holds no valid data.
    // FULL:  primary register holds valid data.
    // BOTH:  primary AND aux registers hold valid data (upstream must stall).
    // -------------------------------------------------------------------------
    typedef enum logic [1:0] {
        EMPTY = 2'b00,
        FULL  = 2'b01,
        BOTH  = 2'b10
    } slice_state_t;

    slice_state_t              state;
    logic [DATA_WIDTH-1:0]     primary_reg;
    logic [DATA_WIDTH-1:0]     aux_reg;

    // Registered output signals
    logic                      up_ready_r;
    logic                      dn_valid_r;

    assign up_ready = up_ready_r;
    assign dn_valid = dn_valid_r;
    assign dn_data  = primary_reg;

    // -------------------------------------------------------------------------
    // State machine — fully registered transitions
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state       <= EMPTY;
            up_ready_r  <= 1'b1;
            dn_valid_r  <= 1'b0;
            primary_reg <= '0;
            aux_reg     <= '0;
        end else begin
            unique case (state)

                // --------------------------------------------------------------
                EMPTY: begin
                    if (up_valid & up_ready_r) begin
                        // Accept word from upstream
                        primary_reg <= up_data;
                        dn_valid_r  <= 1'b1;
                        up_ready_r  <= 1'b1; // Still room for one more
                        state       <= FULL;
                    end
                end

                // --------------------------------------------------------------
                FULL: begin
                    if (dn_ready & dn_valid_r & !(up_valid & up_ready_r)) begin
                        // Downstream consumed; nothing new arriving
                        dn_valid_r <= 1'b0;
                        up_ready_r <= 1'b1;
                        state      <= EMPTY;
                    end else if (dn_ready & dn_valid_r & up_valid & up_ready_r) begin
                        // Downstream consumed AND upstream sending: stay FULL
                        primary_reg <= up_data;
                        dn_valid_r  <= 1'b1;
                        up_ready_r  <= 1'b1;
                        // state stays FULL
                    end else if (!(dn_ready) & up_valid & up_ready_r) begin
                        // Downstream stalling; park incoming word in aux
                        aux_reg    <= up_data;
                        up_ready_r <= 1'b0; // No more room — stall upstream
                        dn_valid_r <= 1'b1;
                        state      <= BOTH;
                    end
                    // else: downstream stalling, nothing new — hold state
                end

                // --------------------------------------------------------------
                BOTH: begin
                    if (dn_ready & dn_valid_r) begin
                        // Downstream consumed primary; promote aux to primary
                        primary_reg <= aux_reg;
                        dn_valid_r  <= 1'b1;
                        up_ready_r  <= 1'b1; // Aux slot now free
                        state       <= FULL;
                    end
                    // else: upstream already stalled (up_ready_r = 0); hold
                end

                default: begin
                    state      <= EMPTY;
                    up_ready_r <= 1'b1;
                    dn_valid_r <= 1'b0;
                end

            endcase
        end
    end

endmodule
