// -----------------------------------------------------------------------------
// Module: skid_buffer
// Description:
//   Two-entry elastic (skid) buffer that fully decouples the ready/valid
//   handshake between upstream and downstream. The key property is that
//   in_ready is a registered output — it carries no combinational dependence
//   on out_ready, eliminating ready-path timing loops.
//
//   The buffer operates using two slots: a primary register and a skid
//   register. When the downstream stalls (out_ready de-asserted) while
//   in_ready is still asserted (registered high), the arriving word is
//   stored in the skid slot, preventing data loss.
//
// Parameters:
//   DATA_WIDTH - Width of the data bus in bits (default: 8)
//
// Ports:
//   clk       - Clock input (rising-edge triggered)
//   rst_n     - Active-low synchronous reset
//   in_valid  - Upstream data valid
//   in_ready  - Upstream ready (output, REGISTERED — no comb path to out_ready)
//   in_data   - Upstream data bus [DATA_WIDTH-1:0]
//   out_valid - Downstream data valid (output)
//   out_ready - Downstream ready
//   out_data  - Downstream data bus [DATA_WIDTH-1:0] (output)
//
// Behavior:
//   - in_ready is registered: upstream sees a clean, glitch-free ready signal.
//   - Sustains full throughput (one word per cycle) when downstream is ready.
//   - When downstream stalls, up to one additional word is absorbed (skid slot).
//   - in_ready de-asserts one cycle after the buffer becomes full.
//
// Timing assumptions:
//   - in_valid / in_data must be stable before the rising clock edge.
//   - out_ready is sampled on the rising clock edge.
//
// Usage notes:
//   - Use at clock-domain boundaries or when combinational ready loops must
//     be broken for timing closure.
//   - Latency: 1 cycle minimum (data passes through primary register).
//
// Example instantiation:
//   skid_buffer #(
//     .DATA_WIDTH(32)
//   ) u_skid (
//     .clk      (clk),
//     .rst_n    (rst_n),
//     .in_valid (up_valid),
//     .in_ready (up_ready),
//     .in_data  (up_data),
//     .out_valid(dn_valid),
//     .out_ready(dn_ready),
//     .out_data (dn_data)
//   );
// -----------------------------------------------------------------------------

module skid_buffer #(
    parameter int DATA_WIDTH = 8
) (
    input  logic                  clk,
    input  logic                  rst_n,

    // Upstream (input) interface
    input  logic                  in_valid,
    output logic                  in_ready,
    input  logic [DATA_WIDTH-1:0] in_data,

    // Downstream (output) interface
    output logic                  out_valid,
    input  logic                  out_ready,
    output logic [DATA_WIDTH-1:0] out_data
);

    // -------------------------------------------------------------------------
    // Internal registers
    // -------------------------------------------------------------------------
    // Primary register — holds the word currently presented to downstream
    logic                  primary_valid;
    logic [DATA_WIDTH-1:0] primary_data;

    // Skid register — holds the word absorbed when downstream stalls while
    // in_ready was still asserted last cycle
    logic                  skid_valid;
    logic [DATA_WIDTH-1:0] skid_data;

    // Registered in_ready
    logic                  in_ready_r;

    // -------------------------------------------------------------------------
    // Output assignments
    // -------------------------------------------------------------------------
    assign out_valid = primary_valid;
    assign out_data  = primary_data;
    assign in_ready  = in_ready_r;

    // -------------------------------------------------------------------------
    // Sequential logic
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            primary_valid <= 1'b0;
            primary_data  <= '0;
            skid_valid    <= 1'b0;
            skid_data     <= '0;
            in_ready_r    <= 1'b1; // Reset to ready
        end else begin
            // ------------------------------------------------------------------
            // Skid register: captures arriving word when primary is occupied
            // and downstream is stalling (in_ready_r was high last cycle, so
            // upstream may have sent a word this cycle).
            // The `primary_valid` guard ensures we only park here when primary
            // is already occupied; if primary is empty the arriving word goes
            // directly to primary in the block below.
            // ------------------------------------------------------------------
            if (in_valid & in_ready_r & primary_valid & !out_ready) begin
                // Primary occupied and not draining — park in skid slot
                skid_valid <= 1'b1;
                skid_data  <= in_data;
            end else if (out_ready) begin
                // Downstream drained; skid slot no longer needed
                skid_valid <= 1'b0;
            end

            // ------------------------------------------------------------------
            // Primary register
            // ------------------------------------------------------------------
            if (out_ready | !primary_valid) begin
                if (skid_valid) begin
                    // Drain from skid slot first
                    primary_valid <= 1'b1;
                    primary_data  <= skid_data;
                end else if (in_valid & in_ready_r) begin
                    // Accept directly from upstream
                    primary_valid <= 1'b1;
                    primary_data  <= in_data;
                end else begin
                    primary_valid <= 1'b0;
                end
            end

            // ------------------------------------------------------------------
            // in_ready: de-assert when both slots will be occupied next cycle.
            // Asserted when at least one slot is or will be free.
            // ------------------------------------------------------------------
            if (out_ready) begin
                // Downstream drained one entry; buffer has room
                in_ready_r <= 1'b1;
            end else if (in_valid & in_ready_r & primary_valid) begin
                // About to fill skid slot; de-assert ready
                in_ready_r <= 1'b0;
            end
        end
    end

endmodule
