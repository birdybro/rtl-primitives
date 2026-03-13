// =============================================================================
// Module: register_file
// Description:
//   Multi-read-port, single-write-port register file.  Reads are fully
//   combinational with write-to-read forwarding: if the write address matches
//   any read address on the same cycle that a write is in progress, the new
//   write data is forwarded directly to that read port instead of the stored
//   value.  Writes are registered (clocked).
//
// Parameters:
//   DATA_WIDTH    - Width of each register in bits (default: 32)
//   NUM_REGS      - Number of registers in the file (default: 32)
//   NUM_READ_PORTS- Number of simultaneous read ports (default: 2)
//
// Ports:
//   clk    - System clock (rising-edge triggered)
//   rst_n  - Asynchronous active-low reset (clears all registers to 0)
//   we     - Write enable (active high)
//   waddr  - Write address
//   wdata  - Write data
//   raddr  - Array of read addresses, one per read port
//   rdata  - Array of read data outputs, one per read port (combinational)
//
// Timing / Behaviour:
//   - Writes are committed on the rising edge of clk when we is asserted.
//   - Reads are purely combinational; rdata reflects the current register
//     contents (or forwarded wdata) immediately.
//   - Write-to-read forwarding ensures that a read issued in the same cycle
//     as a write to the same address returns the new (written) value.
//   - On reset, all registers are cleared to zero.
//
// Usage Notes:
//   - For CPU register files, tie raddr[0] and raddr[1] to rs1 and rs2.
//   - If NUM_REGS is a power of two, register 0 can be hardwired to zero by
//     the caller by simply never writing to address 0.
//
// Example Instantiation:
//   register_file #(
//     .DATA_WIDTH    (32),
//     .NUM_REGS      (32),
//     .NUM_READ_PORTS(2)
//   ) u_regfile (
//     .clk  (clk),
//     .rst_n(rst_n),
//     .we   (we),
//     .waddr(waddr),
//     .wdata(wdata),
//     .raddr(raddr),
//     .rdata(rdata)
//   );
// =============================================================================

module register_file #(
    parameter int DATA_WIDTH     = 32,
    parameter int NUM_REGS       = 32,
    parameter int NUM_READ_PORTS = 2
) (
    input  logic                                              clk,
    input  logic                                              rst_n,

    // Write port
    input  logic                                              we,
    input  logic [$clog2(NUM_REGS)-1:0]                      waddr,
    input  logic [DATA_WIDTH-1:0]                             wdata,

    // Read ports (combinational with forwarding)
    input  logic [NUM_READ_PORTS-1:0][$clog2(NUM_REGS)-1:0]  raddr,
    output logic [NUM_READ_PORTS-1:0][DATA_WIDTH-1:0]         rdata
);

    // Register array
    logic [DATA_WIDTH-1:0] regs [0:NUM_REGS-1];

    // Synchronous write with asynchronous reset
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < NUM_REGS; i++)
                regs[i] <= '0;
        end else if (we) begin
            regs[waddr] <= wdata;
        end
    end

    // Combinational read with write-to-read forwarding
    always_comb begin
        for (int p = 0; p < NUM_READ_PORTS; p++) begin
            if (we && (waddr == raddr[p]))
                rdata[p] = wdata;           // forward in-flight write data
            else
                rdata[p] = regs[raddr[p]];
        end
    end

endmodule
