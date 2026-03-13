// =============================================================================
// Module: dual_port_ram
// Description:
//   True dual-port RAM with two fully independent read/write ports (Port A and
//   Port B), each driven by its own clock.  The memory array is shared between
//   both ports; simultaneous writes to the same address from both ports produce
//   implementation-defined (undefined) behaviour — the caller must arbitrate
//   externally.  The registered-read style is used so that synthesis tools can
//   reliably infer block RAM primitives.
//
// Parameters:
//   DATA_WIDTH - Width of each data word in bits (default: 8)
//   DEPTH      - Number of addressable words (default: 256)
//   ADDR_WIDTH - Address width, derived as $clog2(DEPTH); do not override
//
// Ports:
//   clk_a  - Clock for Port A
//   en_a   - Chip-enable for Port A (active high)
//   we_a   - Write-enable for Port A (active high)
//   addr_a - Address for Port A
//   din_a  - Write data for Port A
//   dout_a - Registered read data from Port A
//
//   clk_b  - Clock for Port B
//   en_b   - Chip-enable for Port B (active high)
//   we_b   - Write-enable for Port B (active high)
//   addr_b - Address for Port B
//   din_b  - Write data for Port B
//   dout_b - Registered read data from Port B
//
// Timing / Behaviour:
//   - Write-first mode: on a write cycle the new data is stored; on a read
//     cycle (we=0, en=1) the currently stored data at addr is captured into
//     the output register.  Both happen on the rising edge of their respective
//     clocks.
//   - Read latency: 1 clock cycle (registered output).
//   - No reset on the RAM array or output registers (matches block RAM
//     semantics; initial content is undefined).
//
// Usage Notes:
//   - Both ports operate independently; they may run at different frequencies.
//   - To avoid read-during-write hazards within a single port, ensure the
//     write completes before issuing a read to the same address, or treat the
//     read data as undefined during the same cycle as a write to that address.
//   - DEPTH must be a power of two for proper ADDR_WIDTH derivation.
//
// Example Instantiation:
//   dual_port_ram #(
//     .DATA_WIDTH(16),
//     .DEPTH     (512)
//   ) u_dp_ram (
//     .clk_a (clk_a), .en_a(en_a), .we_a(we_a),
//     .addr_a(addr_a), .din_a(din_a), .dout_a(dout_a),
//     .clk_b (clk_b), .en_b(en_b), .we_b(we_b),
//     .addr_b(addr_b), .din_b(din_b), .dout_b(dout_b)
//   );
// =============================================================================

module dual_port_ram #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 256,
    parameter int ADDR_WIDTH = $clog2(DEPTH)
) (
    // Port A
    input  logic                  clk_a,
    input  logic                  en_a,
    input  logic                  we_a,
    input  logic [ADDR_WIDTH-1:0] addr_a,
    input  logic [DATA_WIDTH-1:0] din_a,
    output logic [DATA_WIDTH-1:0] dout_a,

    // Port B
    input  logic                  clk_b,
    input  logic                  en_b,
    input  logic                  we_b,
    input  logic [ADDR_WIDTH-1:0] addr_b,
    input  logic [DATA_WIDTH-1:0] din_b,
    output logic [DATA_WIDTH-1:0] dout_b
);

    // Shared memory array — inferred as block RAM by most synthesis tools
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Port A: write then registered read
    always_ff @(posedge clk_a) begin
        if (en_a) begin
            if (we_a)
                mem[addr_a] <= din_a;
            else
                dout_a <= mem[addr_a];
        end
    end

    // Port B: write then registered read
    always_ff @(posedge clk_b) begin
        if (en_b) begin
            if (we_b)
                mem[addr_b] <= din_b;
            else
                dout_b <= mem[addr_b];
        end
    end

endmodule
